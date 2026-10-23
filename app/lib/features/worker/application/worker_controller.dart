import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/geo.dart';
import '../../../core/models.dart';
import '../../../core/strings.dart';
import '../data/location_service.dart';
import '../data/offline_queue.dart';
import '../data/worker_repository.dart';

enum OutcomeKind { accepted, rejected, queued, error }

/// Result card shown after tapping "Marcar".
class MarkOutcome {
  const MarkOutcome(this.kind, this.title, [this.message]);

  final OutcomeKind kind;
  final String title;
  final String? message;
}

class WorkerState {
  const WorkerState({
    this.today,
    this.stale = false,
    this.loading = true,
    this.loadError,
    this.fix,
    this.locationIssue,
    this.pending = const [],
    this.marking = false,
    this.outcome,
  });

  final TodayInfo? today;

  /// [today] comes from the cache (no connection).
  final bool stale;
  final bool loading;
  final String? loadError;
  final Fix? fix;
  final LocationIssue? locationIssue;
  final List<PendingMark> pending;
  final bool marking;
  final MarkOutcome? outcome;

  /// The mark to make now: queued marks count, so the button flips even without signal.
  String get next {
    if (pending.isNotEmpty) return pending.last.type == 'IN' ? 'OUT' : 'IN';
    return today?.next ?? 'IN';
  }

  ZoneCheck? get zone {
    final w = today?.worksite;
    final f = fix;
    if (w == null || f == null) return null;
    return checkZone(
        centerLat: w.lat, centerLon: w.lon, radiusMeters: w.radiusMeters, lat: f.lat, lon: f.lon, accuracyMeters: f.accuracyMeters);
  }

  WorkerState copyWith({
    TodayInfo? today,
    bool? stale,
    bool? loading,
    String? Function()? loadError,
    Fix? fix,
    LocationIssue? Function()? locationIssue,
    List<PendingMark>? pending,
    bool? marking,
    MarkOutcome? Function()? outcome,
  }) =>
      WorkerState(
        today: today ?? this.today,
        stale: stale ?? this.stale,
        loading: loading ?? this.loading,
        loadError: loadError != null ? loadError() : this.loadError,
        fix: fix ?? this.fix,
        locationIssue: locationIssue != null ? locationIssue() : this.locationIssue,
        pending: pending ?? this.pending,
        marking: marking ?? this.marking,
        outcome: outcome != null ? outcome() : this.outcome,
      );
}

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  final session = ref.watch(authProvider).value!;
  return WorkerRepository(ref.watch(apiClientProvider), PrefsStore(), session.employeeId);
});

final workerControllerProvider = NotifierProvider<WorkerController, WorkerState>(WorkerController.new);

/// ViewModel of the worker screen.
class WorkerController extends Notifier<WorkerState> {
  StreamSubscription<Fix>? _gps;
  Timer? _retry;
  bool _flushing = false;

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);
  LocationService get _location => ref.read(locationServiceProvider);

  @override
  WorkerState build() {
    ref.onDispose(() {
      _gps?.cancel();
      _retry?.cancel();
    });
    // Queued marks are retried every minute while the screen is open.
    _retry = Timer.periodic(const Duration(minutes: 1), (_) {
      if (state.pending.isNotEmpty) _flush();
    });
    Future.microtask(() async {
      await _loadPending();
      await startLocation();
      await _flush();
      await refresh();
    });
    return const WorkerState();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, loadError: () => null);
    try {
      final today = await _repo.today();
      if (!ref.mounted) return;
      state = state.copyWith(today: today, stale: false, loading: false);
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      if (e.isUnauthorized) return _expire();
      final cached = state.today ?? await _repo.cachedToday();
      if (!ref.mounted) return;
      state = state.copyWith(today: cached, stale: cached != null, loading: false, loadError: () => e.message);
    }
  }

  Future<void> startLocation() async {
    final issue = await _location.ensureReady();
    if (!ref.mounted) return;
    state = state.copyWith(locationIssue: () => issue);
    if (issue != null) return;
    await _gps?.cancel();
    _gps = _location.watch().listen(
          (fix) => state = state.copyWith(fix: fix),
          onError: (_) {}, // keep the last fix; the mark asks for a fresh one anyway
        );
  }

  Future<void> openLocationSettings() async {
    final issue = state.locationIssue;
    if (issue != null) await _location.openSettings(issue);
  }

  Future<void> mark() async {
    if (state.marking) return;
    state = state.copyWith(marking: true, outcome: () => null);
    try {
      final issue = await _location.ensureReady();
      if (issue != null) {
        state = state.copyWith(locationIssue: () => issue);
        return _done(const MarkOutcome(OutcomeKind.error, S.locationUnavailable, S.locationUnavailableHelp));
      }
      final Fix fix;
      try {
        fix = await _location.current();
      } catch (_) {
        return _done(const MarkOutcome(OutcomeKind.error, S.noGpsFix, S.noGpsFixHelp));
      }
      final type = state.next;
      final pending = PendingMark(
        clientId: uuidV4(),
        type: type,
        lat: fix.lat,
        lon: fix.lon,
        accuracyMeters: fix.accuracyMeters,
        mocked: fix.mocked,
        capturedAt: DateTime.now().toUtc(),
      );
      try {
        await _repo.queue.add(pending); // persisted first: never lost, even if the app closes now
      } on ApiException catch (e) {
        return _done(MarkOutcome(OutcomeKind.error, S.couldNotSave, e.message));
      }
      state = state.copyWith(fix: fix);
      final result = await _flush();
      final mark = result?.sent.where((m) => m.clientId == pending.clientId).firstOrNull;
      if (mark != null) {
        _done(_outcomeOf(mark));
        await refresh();
      } else if (result?.failed.isNotEmpty ?? false) {
        _done(MarkOutcome(OutcomeKind.error, S.notAccepted, result!.failed.first.message));
      } else {
        _done(MarkOutcome(OutcomeKind.queued, S.savedOffline(type == 'IN'), S.savedOfflineHelp));
      }
    } finally {
      if (ref.mounted && state.marking) state = state.copyWith(marking: false);
    }
  }

  void dismissOutcome() => state = state.copyWith(outcome: () => null);

  Future<void> sendPending() async {
    final result = await _flush();
    if (result != null && result.sent.isNotEmpty) await refresh();
  }

  MarkOutcome _outcomeOf(Mark m) {
    if (!m.accepted) return MarkOutcome(OutcomeKind.rejected, S.notRecorded(m.isIn), m.message);
    return MarkOutcome(OutcomeKind.accepted, S.recorded(m.isIn), switch (m.status) {
      'LATE' => S.recordedLate,
      'EARLY_LEAVE' => S.recordedEarly,
      'UNSCHEDULED' => S.recordedUnscheduled,
      _ => S.recordedOnTime,
    });
  }

  void _done(MarkOutcome outcome) {
    if (ref.mounted) state = state.copyWith(marking: false, outcome: () => outcome);
  }

  Future<void> _loadPending() async {
    final pending = await _repo.queue.all();
    if (ref.mounted) state = state.copyWith(pending: pending);
  }

  /// Sends queued marks in order. One flush at a time (the queue is read-modify-write).
  Future<FlushResult?> _flush() async {
    if (_flushing) return null;
    _flushing = true;
    try {
      final result = await _repo.queue.flush(_repo.send);
      if (!ref.mounted) return result;
      await _loadPending();
      if (result.stoppedBy?.isUnauthorized ?? false) await _expire();
      return result;
    } finally {
      _flushing = false;
    }
  }

  Future<void> _expire() => ref.read(authProvider.notifier).expire();
}
