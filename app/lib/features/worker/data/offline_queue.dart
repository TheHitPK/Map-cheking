import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/models.dart';

/// Minimal persistent key/value port (shared_preferences in the app, a map in tests).
abstract interface class KeyValueStore {
  Future<String?> get(String key);

  Future<void> set(String key, String? value);
}

/// A mark captured on the phone and not yet confirmed by the server.
class PendingMark {
  const PendingMark({
    required this.clientId,
    required this.type,
    required this.lat,
    required this.lon,
    required this.accuracyMeters,
    required this.mocked,
    required this.capturedAt,
  });

  final String clientId;
  final String type;
  final double lat;
  final double lon;
  final double accuracyMeters;
  final bool mocked;
  final DateTime capturedAt;

  factory PendingMark.fromJson(Map<String, dynamic> j) => PendingMark(
        clientId: j['clientId'] as String,
        type: j['type'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        accuracyMeters: (j['accuracyMeters'] as num).toDouble(),
        mocked: j['mocked'] as bool,
        capturedAt: DateTime.parse(j['capturedAt'] as String),
      );

  /// Also the request body of `POST /me/marks`.
  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'type': type,
        'lat': lat,
        'lon': lon,
        'accuracyMeters': accuracyMeters,
        'mocked': mocked,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      };
}

class FlushResult {
  const FlushResult(this.sent, this.failed, this.stoppedBy);

  /// Server answers, in order (accepted or rejected marks).
  final List<Mark> sent;

  /// Requests the server refused outright (e.g. 400); dropped from the queue.
  final List<ApiException> failed;

  /// Why flushing stopped early (network, 5xx, 401); those marks stay queued.
  final ApiException? stoppedBy;
}

/// FIFO of marks per employee, persisted before sending so a crash or no signal never loses a mark.
/// Retries are safe: the server deduplicates by clientId.
class OfflineQueue {
  OfflineQueue(this._store, int employeeId) : _key = 'pending_marks_$employeeId';

  static const maxSize = 20;

  final KeyValueStore _store;
  final String _key;

  Future<List<PendingMark>> all() async {
    final raw = await _store.get(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => PendingMark.fromJson(e as Map<String, dynamic>)).toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> add(PendingMark mark) async {
    final items = await all();
    if (items.length >= maxSize) {
      throw ApiException('Hay demasiadas marcas sin enviar. Conéctese a internet para enviarlas.');
    }
    await _save([...items, mark]);
  }

  Future<FlushResult> flush(Future<Mark> Function(PendingMark) send) async {
    final items = await all();
    final sent = <Mark>[];
    final failed = <ApiException>[];
    ApiException? stoppedBy;
    var i = 0;
    for (; i < items.length; i++) {
      try {
        sent.add(await send(items[i]));
      } on ApiException catch (e) {
        if (!e.isPermanent) {
          stoppedBy = e;
          break;
        }
        failed.add(e);
      }
    }
    await _save(items.sublist(i));
    return FlushResult(sent, failed, stoppedBy);
  }

  Future<void> _save(List<PendingMark> items) =>
      _store.set(_key, items.isEmpty ? null : jsonEncode(items.map((m) => m.toJson()).toList()));
}
