import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/brand/brand.dart';
import '../../../core/format.dart';
import '../../../core/geo.dart';
import '../../../core/labels.dart';
import '../../../core/models.dart';
import '../../../core/strings.dart';
import '../../../core/widgets/common.dart';
import '../application/worker_controller.dart';
import '../data/location_service.dart';

/// Motion tokens for the worker screen.
abstract final class _Motion {
  static const press = Duration(milliseconds: 90);
  static const swap = Duration(milliseconds: 220);
  static const stamp = Duration(milliseconds: 650);
  static const pulse = Duration(milliseconds: 1800);
}

class WorkerHomeScreen extends ConsumerWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workerControllerProvider);
    final c = ref.read(workerControllerProvider.notifier);
    ref.listen(workerControllerProvider.select((s) => s.outcome), (_, o) {
      if (o?.kind == OutcomeKind.accepted) HapticFeedback.mediumImpact();
      if (o?.kind == OutcomeKind.rejected || o?.kind == OutcomeKind.error) HapticFeedback.heavyImpact();
    });
    final name = s.today?.fullName ?? ref.watch(authProvider).value?.fullName ?? '';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: Space.lg,
        title: Row(children: [
          const PinPunchMark(size: 28),
          const SizedBox(width: Space.sm),
          Flexible(child: Text(S.hello(name.split(' ').first), overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          IconButton(tooltip: S.refresh, icon: const Icon(Icons.refresh), onPressed: s.loading ? null : c.refresh),
          IconButton(tooltip: S.signOut, icon: const Icon(Icons.logout), onPressed: () => _confirmLogout(context, ref, s.pending.length)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: c.refresh,
          child: ListView(
            padding: const EdgeInsets.all(Space.lg),
            children: [
              MaxWidth(
                width: 560,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (s.loading && s.today == null) const LinearProgressIndicator(),
                  if (s.stale || (s.loadError != null && s.today == null)) ...[
                    StatusBadge(
                      label: s.today == null ? s.loadError! : S.offlineShowingSaved,
                      icon: Icons.cloud_off_outlined,
                      tone: Tone.warning,
                    ),
                    const SizedBox(height: Space.md),
                  ],
                  _Swap(
                    child: s.pending.isEmpty
                        ? const SizedBox.shrink(key: ValueKey('no-pending'))
                        : Padding(
                            key: const ValueKey('pending'),
                            padding: const EdgeInsets.only(bottom: Space.md),
                            child: _PendingBanner(count: s.pending.length, onSend: c.sendPending),
                          ),
                  ),
                  _WorksiteCard(today: s.today),
                  const SizedBox(height: Space.md),
                  _ZoneCard(state: s, onFixLocation: s.locationIssue == null ? c.startLocation : c.openLocationSettings),
                  const SizedBox(height: Space.xl),
                  _PunchButton(
                    next: s.next,
                    busy: s.marking,
                    enabled: s.today?.worksite != null || s.today == null,
                    onPressed: c.mark,
                  ),
                  _Swap(
                    child: s.outcome == null
                        ? const SizedBox.shrink(key: ValueKey('no-outcome'))
                        : Padding(
                            key: ValueKey(s.outcome),
                            padding: const EdgeInsets.only(top: Space.lg),
                            child: _OutcomeCard(outcome: s.outcome!, onClose: c.dismissOutcome),
                          ),
                  ),
                  const SizedBox(height: Space.xl),
                  _TodayMarks(marks: s.today?.marks ?? const []),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, int pending) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.signOutQuestion),
        content: Text(pending == 0 ? S.signOutBody : S.signOutPending(pending)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.signOut)),
        ],
      ),
    );
    if (ok ?? false) await ref.read(authProvider.notifier).logout();
  }
}

/// Fade + size swap for content that appears and disappears (no layout jumps).
class _Swap extends StatelessWidget {
  const _Swap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: _Motion.swap,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: _Motion.swap,
          reverseDuration: const Duration(milliseconds: 140), // exits faster than entrances
          switchInCurve: Curves.easeOut,
          child: child,
        ),
      );
}

class _WorksiteCard extends StatelessWidget {
  const _WorksiteCard({required this.today});

  final TodayInfo? today;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final w = today?.worksite;
    final String schedule;
    if (today == null) {
      schedule = S.loading;
    } else if (today!.todayStart != null) {
      schedule = S.shiftToday(Fmt.time(today!.todayStart!), Fmt.time(today!.todayEnd!), today!.shift!.graceMinutes);
    } else if (today!.shift != null) {
      schedule = S.noShiftToday(Fmt.days(today!.shift!.days));
    } else {
      schedule = S.noSchedule;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: t.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.construction_outlined, color: t.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w?.name ?? (today == null ? S.jobSite : S.noJobSite), style: t.textTheme.titleMedium),
              if (w != null && w.address.isNotEmpty)
                Text(w.address, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              const SizedBox(height: Space.xs),
              Text(schedule, style: t.textTheme.bodyMedium),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.state, required this.onFixLocation});

  final WorkerState state;
  final VoidCallback onFixLocation;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final issue = state.locationIssue;
    final zone = state.zone;
    final w = state.today?.worksite;
    final radius = w == null ? '' : Fmt.distance(w.radiusMeters.toDouble());

    final (IconData icon, Tone tone, String title, String detail) = switch ((issue, zone)) {
      (LocationIssue.serviceDisabled, _) => (Icons.location_off_outlined, Tone.danger, S.gpsOff, S.gpsOffHelp),
      (LocationIssue.deniedForever, _) =>
        (Icons.location_disabled_outlined, Tone.danger, S.noLocationPermission, S.noLocationPermissionForever),
      (LocationIssue.denied, _) => (Icons.location_disabled_outlined, Tone.danger, S.noLocationPermission, S.noLocationPermissionHelp),
      (null, null) => (Icons.gps_not_fixed, Tone.neutral, S.searchingGps, w == null ? '' : S.siteRadius(radius)),
      (null, ZoneCheck(state: ZoneState.inside, :final distanceMeters)) =>
        (Icons.where_to_vote_outlined, Tone.success, S.onSite, S.fromCenter(Fmt.distance(distanceMeters), radius)),
      (null, ZoneCheck(state: ZoneState.outside, :final distanceMeters)) =>
        (Icons.wrong_location_outlined, Tone.danger, S.offSite, S.fromCenter(Fmt.distance(distanceMeters), radius)),
      (null, ZoneCheck(state: ZoneState.imprecise)) =>
        (Icons.gps_not_fixed, Tone.warning, S.weakGps, S.weakGpsHelp(Fmt.distance(state.fix!.accuracyMeters))),
    };
    final (bg, fg) = toneColors(context, tone);
    final inside = issue == null && zone?.state == ZoneState.inside;
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: _Motion.swap,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            SizedBox.square(
              dimension: 48,
              child: _PulseRing(active: inside, color: fg, child: Icon(icon, color: fg, size: 30)),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: _Motion.swap,
                child: Column(
                  key: ValueKey(title),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w800)),
                    if (detail.isNotEmpty) Text(detail, style: t.textTheme.bodyMedium?.copyWith(color: fg)),
                  ],
                ),
              ),
            ),
          ]),
          if (issue != null) ...[
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: onFixLocation,
              icon: const Icon(Icons.settings_outlined),
              label: Text(issue == LocationIssue.serviceDisabled ? S.turnOnGps : S.allowLocation),
              style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: fg)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Expanding ring behind the icon while the worker is on site: "you're here", like a live map dot.
class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.active, required this.color, required this.child});

  final bool active;
  final Color color;
  final Widget child;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _Motion.pulse);

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (run && !_c.isAnimating) _c.repeat();
    if (!run && _c.isAnimating) _c.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_PulseRing old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        if (widget.active)
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final v = Curves.easeOut.transform(_c.value);
              return Container(
                width: 30 + 30 * v,
                height: 30 + 30 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: (1 - v) * 0.6), width: 2.5),
                ),
              );
            },
          ),
        widget.child,
      ]);
}

/// The primary action. Orange "Punch in" / navy "Punch out"; presses down and springs back.
class _PunchButton extends StatefulWidget {
  const _PunchButton({required this.next, required this.busy, required this.enabled, required this.onPressed});

  final String next;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_PunchButton> createState() => _PunchButtonState();
}

class _PunchButtonState extends State<_PunchButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final punchIn = widget.next == 'IN';
    final interactive = !widget.busy && widget.enabled;
    final bg = punchIn ? BrandColors.orange : t.colorScheme.primary;
    final fg = punchIn ? BrandColors.navy : t.colorScheme.onPrimary;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: interactive,
      label: widget.busy ? S.punchingSemantics : (punchIn ? S.punchIn : S.punchOut),
      excludeSemantics: true,
      child: Listener(
        onPointerDown: interactive ? (_) => setState(() => _down = true) : null,
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down && !reduce ? 0.96 : 1,
          duration: _Motion.press,
          curve: Curves.easeOut,
          child: FilledButton(
            onPressed: interactive
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onPressed();
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(104),
              backgroundColor: bg,
              foregroundColor: fg,
              elevation: _down ? 0 : 3,
              shadowColor: bg.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: AnimatedSwitcher(
              duration: _Motion.swap,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: child),
              ),
              child: widget.busy
                  ? Row(key: const ValueKey('busy'), mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox.square(dimension: 26, child: CircularProgressIndicator(strokeWidth: 3, color: fg)),
                      const SizedBox(width: Space.lg),
                      const Text(S.gettingLocation, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                    ])
                  : Row(key: ValueKey(widget.next), mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(punchIn ? Icons.login_rounded : Icons.logout_rounded, size: 34),
                      const SizedBox(width: Space.md),
                      Text(punchIn ? S.punchIn : S.punchOut, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome, required this.onClose});

  final MarkOutcome outcome;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (IconData icon, Tone tone) = switch (outcome.kind) {
      OutcomeKind.accepted => (Icons.check_circle, Tone.success),
      OutcomeKind.queued => (Icons.cloud_upload_outlined, Tone.info),
      OutcomeKind.rejected => (Icons.cancel, Tone.danger),
      OutcomeKind.error => (Icons.error_outline, Tone.danger),
    };
    final (bg, fg) = toneColors(context, tone);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.xs, Space.md),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: outcome.kind == OutcomeKind.accepted ? _Stamp(color: fg) : Icon(icon, color: fg, size: 32),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(outcome.title, style: t.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w800)),
                if (outcome.message != null) Text(outcome.message!, style: t.textTheme.bodyMedium?.copyWith(color: fg)),
              ]),
            ),
          ),
          IconButton(tooltip: S.close, onPressed: onClose, icon: Icon(Icons.close, color: fg)),
        ]),
      ),
    );
  }
}

/// Accepted punch: the pin drops in and the check is drawn, like a stamp on a time card.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: _Motion.stamp,
      builder: (_, v, _) {
        final drop = Curves.easeOutBack.transform((v / 0.55).clamp(0, 1));
        final check = Curves.easeOut.transform(((v - 0.45) / 0.55).clamp(0, 1));
        return Transform.scale(
          scale: 0.6 + 0.4 * drop,
          child: Opacity(
            opacity: drop.clamp(0, 1),
            child: CustomPaint(size: const Size.square(36), painter: PinPunchPainter(pinColor: color, checkColor: Colors.white, check: check)),
          ),
        );
      },
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count, required this.onSend});

  final int count;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, Tone.info);
    return Container(
      padding: const EdgeInsets.only(left: Space.lg),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.cloud_upload_outlined, color: fg),
        const SizedBox(width: Space.md),
        Expanded(child: Text(S.pending(count), style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
        TextButton(onPressed: onSend, style: TextButton.styleFrom(foregroundColor: fg), child: const Text(S.sendNow)),
      ]),
    );
  }
}

class _TodayMarks extends StatelessWidget {
  const _TodayMarks({required this.marks});

  final List<Mark> marks;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(S.todaysPunches, style: t.textTheme.titleMedium),
      const SizedBox(height: Space.sm),
      if (marks.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.lg),
          child: Text(S.noPunchesYet, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      for (final m in marks.reversed) _MarkTile(mark: m),
    ]);
  }
}

class _MarkTile extends StatelessWidget {
  const _MarkTile({required this.mark});

  final Mark mark;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final status = markStatusLabel(mark.status);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: mark.isIn ? BrandColors.orange : t.colorScheme.primary,
        foregroundColor: mark.isIn ? BrandColors.navy : t.colorScheme.onPrimary,
        child: Icon(mark.isIn ? Icons.login_rounded : Icons.logout_rounded),
      ),
      title: Text('${markTypeLabel(mark.type)} · ${Fmt.time(mark.recordedAt)}',
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Space.xs),
        child: Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [
          StatusBadge(label: status.label, icon: status.icon, tone: status.tone, dense: true),
          if (mark.deferred) const StatusBadge(label: S.sentOffline, icon: Icons.cloud_off_outlined, tone: Tone.neutral, dense: true),
          if (!mark.accepted && mark.message != null) Text(mark.message!, style: t.textTheme.bodySmall),
        ]),
      ),
    );
  }
}
