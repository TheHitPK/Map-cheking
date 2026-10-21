import 'package:asistencia/core/api/api_client.dart';
import 'package:asistencia/core/models.dart';
import 'package:asistencia/features/worker/data/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStore implements KeyValueStore {
  final data = <String, String>{};

  @override
  Future<String?> get(String key) async => data[key];

  @override
  Future<void> set(String key, String? value) async => value == null ? data.remove(key) : data[key] = value;
}

PendingMark pending(String id, String type) => PendingMark(
      clientId: id,
      type: type,
      lat: 10.6427,
      lon: -71.6125,
      accuracyMeters: 12,
      mocked: false,
      capturedAt: DateTime.utc(2026, 10, 19, 11, 5),
    );

Mark served(PendingMark p) => Mark(
      id: 1,
      clientId: p.clientId,
      type: p.type,
      status: 'ON_TIME',
      rejection: null,
      message: null,
      recordedAt: p.capturedAt,
      distanceMeters: 10,
      accuracyMeters: p.accuracyMeters,
      deferred: false,
    );

void main() {
  late MemoryStore store;
  late OfflineQueue queue;

  setUp(() {
    store = MemoryStore();
    queue = OfflineQueue(store, 7);
  });

  test('persists marks in order and survives a new instance (app restart)', () async {
    await queue.add(pending('a', 'IN'));
    await queue.add(pending('b', 'OUT'));
    final reopened = OfflineQueue(store, 7);
    expect((await reopened.all()).map((m) => m.clientId), ['a', 'b']);
    expect((await OfflineQueue(store, 8).all()), isEmpty, reason: 'queues are per employee');
  });

  test('flush sends in order and empties the queue', () async {
    await queue.add(pending('a', 'IN'));
    await queue.add(pending('b', 'OUT'));
    final order = <String>[];
    final r = await queue.flush((p) async {
      order.add(p.clientId);
      return served(p);
    });
    expect(order, ['a', 'b']);
    expect(r.sent, hasLength(2));
    expect(r.stoppedBy, isNull);
    expect(await queue.all(), isEmpty);
    expect(store.data, isEmpty);
  });

  test('network error stops flushing and keeps the rest queued', () async {
    await queue.add(pending('a', 'IN'));
    await queue.add(pending('b', 'OUT'));
    var calls = 0;
    final r = await queue.flush((p) async {
      if (calls++ == 1) throw ApiException('Sin conexión con el servidor.');
      return served(p);
    });
    expect(r.sent.map((m) => m.clientId), ['a']);
    expect(r.stoppedBy?.isNetwork, isTrue);
    expect((await queue.all()).map((m) => m.clientId), ['b']);
  });

  test('401 and 5xx keep the mark for later; 400 drops it', () async {
    await queue.add(pending('a', 'IN'));
    var r = await queue.flush((_) async => throw ApiException('expirada', statusCode: 401));
    expect(r.stoppedBy?.isUnauthorized, isTrue);
    r = await queue.flush((_) async => throw ApiException('caído', statusCode: 503));
    expect(await queue.all(), hasLength(1));

    r = await queue.flush((_) async => throw ApiException('Marca incompleta.', statusCode: 400));
    expect(r.failed.single.message, 'Marca incompleta.');
    expect(await queue.all(), isEmpty);
  });

  test('refuses to grow without bound', () async {
    for (var i = 0; i < OfflineQueue.maxSize; i++) {
      await queue.add(pending('$i', i.isEven ? 'IN' : 'OUT'));
    }
    expect(() => queue.add(pending('x', 'IN')), throwsA(isA<ApiException>()));
  });

  test('request body matches the API contract', () {
    final json = pending('a', 'IN').toJson();
    expect(json.keys, containsAll(['clientId', 'type', 'lat', 'lon', 'accuracyMeters', 'mocked', 'capturedAt']));
    expect(json['capturedAt'], '2026-10-19T11:05:00.000Z');
  });
}
