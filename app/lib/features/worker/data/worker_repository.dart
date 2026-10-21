import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models.dart';
import 'offline_queue.dart';

class PrefsStore implements KeyValueStore {
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> get(String key) => _prefs.getString(key);

  @override
  Future<void> set(String key, String? value) => value == null ? _prefs.remove(key) : _prefs.setString(key, value);
}

/// Worker endpoints plus a cached copy of the last "today" so the screen still works without signal.
class WorkerRepository {
  WorkerRepository(this._api, this._store, this.employeeId);

  final ApiClient _api;
  final KeyValueStore _store;
  final int employeeId;

  String get _cacheKey => 'today_$employeeId';

  late final queue = OfflineQueue(_store, employeeId);

  Future<TodayInfo> today() async {
    final json = await _api.get('/me/today') as Map<String, dynamic>;
    final today = TodayInfo.fromJson(json);
    await _store.set(_cacheKey, jsonEncode(today.toJson()));
    return today;
  }

  Future<TodayInfo?> cachedToday() async {
    final raw = await _store.get(_cacheKey);
    if (raw == null) return null;
    try {
      return TodayInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Mark> send(PendingMark m) async => Mark.fromJson(await _api.post('/me/marks', m.toJson()) as Map<String, dynamic>);
}
