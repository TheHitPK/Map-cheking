import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/format.dart';
import '../../../core/geo.dart';
import '../../../core/labels.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../application/worker_controller.dart';
import '../data/location_service.dart';

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
        title: Text('Hola, ${name.split(' ').first}'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: s.loading ? null : c.refresh,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ref, s.pending.length),
          ),
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
                      label: s.today == null ? s.loadError! : 'Sin conexión: mostrando los últimos datos guardados.',
                      icon: Icons.cloud_off_outlined,
                      tone: Tone.warning,
                    ),
                    const SizedBox(height: Space.md),
                  ],
                  if (s.pending.isNotEmpty) ...[
                    _PendingBanner(count: s.pending.length, onSend: c.sendPending),
                    const SizedBox(height: Space.md),
                  ],
                  _WorksiteCard(today: s.today),
                  const SizedBox(height: Space.md),
                  _ZoneCard(state: s, onFixLocation: s.locationIssue == null ? c.startLocation : c.openLocationSettings),
                  const SizedBox(height: Space.xl),
                  _MarkButton(next: s.next, busy: s.marking, enabled: s.today?.worksite != null || s.today == null, onPressed: c.mark),
                  if (s.outcome != null) ...[
                    const SizedBox(height: Space.lg),
                    _OutcomeCard(outcome: s.outcome!, onClose: c.dismissOutcome),
                  ],
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
        title: const Text('¿Cerrar sesión?'),
        content: Text(pending == 0
            ? 'Tendrá que ingresar su clave de nuevo.'
            : 'Tiene $pending marca(s) sin enviar. Se enviarán cuando vuelva a iniciar sesión en este teléfono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(authProvider.notifier).logout();
  }
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
      schedule = 'Cargando…';
    } else if (today!.todayStart != null) {
      schedule = 'Hoy ${Fmt.time(today!.todayStart!)} – ${Fmt.time(today!.todayEnd!)}'
          ' · tolerancia ${today!.shift!.graceMinutes} min';
    } else if (today!.shift != null) {
      schedule = 'Hoy no tiene turno (${Fmt.days(today!.shift!.days)})';
    } else {
      schedule = 'Sin horario asignado';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(children: [
          Icon(Icons.location_city_outlined, size: 32, color: t.colorScheme.primary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w?.name ?? (today == null ? 'Obra' : 'Sin obra asignada'), style: t.textTheme.titleMedium),
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

    final (IconData icon, Tone tone, String title, String detail) = switch ((issue, zone)) {
      (LocationIssue.serviceDisabled, _) => (Icons.location_off_outlined, Tone.danger, 'GPS apagado', 'Active la ubicación del teléfono.'),
      (LocationIssue.deniedForever, _) =>
        (Icons.location_disabled_outlined, Tone.danger, 'Sin permiso de ubicación', 'Permita la ubicación en los ajustes de la app.'),
      (LocationIssue.denied, _) =>
        (Icons.location_disabled_outlined, Tone.danger, 'Sin permiso de ubicación', 'La app necesita su ubicación para marcar.'),
      (null, null) => (Icons.gps_not_fixed, Tone.neutral, 'Buscando señal GPS…', w == null ? '' : 'Radio de la obra: ${w.radiusMeters} m'),
      (null, ZoneCheck(state: ZoneState.inside, :final distanceMeters)) => (Icons.verified_outlined, Tone.success,
          'Dentro de la obra', 'A ${Fmt.distance(distanceMeters)} del centro · radio ${w!.radiusMeters} m'),
      (null, ZoneCheck(state: ZoneState.outside, :final distanceMeters)) => (Icons.wrong_location_outlined, Tone.danger,
          'Fuera de la obra', 'A ${Fmt.distance(distanceMeters)} del centro · radio ${w!.radiusMeters} m'),
      (null, ZoneCheck(state: ZoneState.imprecise)) => (Icons.gps_not_fixed, Tone.warning, 'Señal GPS imprecisa',
          'Precisión ± ${state.fix!.accuracyMeters.round()} m. Salga a cielo abierto.'),
    };
    final (bg, fg) = toneColors(context, tone);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: fg, size: 32),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                if (detail.isNotEmpty) Text(detail, style: t.textTheme.bodyMedium?.copyWith(color: fg)),
              ]),
            ),
          ]),
          if (issue != null) ...[
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: onFixLocation,
              icon: const Icon(Icons.settings_outlined),
              label: Text(issue == LocationIssue.serviceDisabled ? 'Activar GPS' : 'Dar permiso'),
              style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: fg)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({required this.next, required this.busy, required this.enabled, required this.onPressed});

  final String next;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final arrival = next == 'IN';
    return Semantics(
      button: true,
      label: busy ? 'Marcando, obteniendo ubicación' : (arrival ? 'Marcar llegada' : 'Marcar salida'),
      excludeSemantics: true,
      child: FilledButton(
        onPressed: busy || !enabled ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(96),
          backgroundColor: arrival ? t.colorScheme.primary : t.colorScheme.tertiary,
          foregroundColor: arrival ? t.colorScheme.onPrimary : t.colorScheme.onTertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: busy
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 3, color: t.colorScheme.onPrimary.withValues(alpha: 0.9))),
                const SizedBox(width: Space.lg),
                const Text('Obteniendo ubicación…', style: TextStyle(fontSize: 20)),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(arrival ? Icons.login : Icons.logout, size: 32),
                const SizedBox(width: Space.md),
                Text(arrival ? 'Marcar llegada' : 'Marcar salida',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ]),
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
          Padding(padding: const EdgeInsets.only(top: Space.xs), child: Icon(icon, color: fg, size: 28)),
          const SizedBox(width: Space.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(outcome.title, style: t.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                if (outcome.message != null) Text(outcome.message!, style: t.textTheme.bodyMedium?.copyWith(color: fg)),
              ]),
            ),
          ),
          IconButton(tooltip: 'Cerrar', onPressed: onClose, icon: Icon(Icons.close, color: fg)),
        ]),
      ),
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
        Expanded(
          child: Text(count == 1 ? '1 marca pendiente de envío' : '$count marcas pendientes de envío',
              style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ),
        TextButton(onPressed: onSend, style: TextButton.styleFrom(foregroundColor: fg), child: const Text('Enviar ahora')),
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
      Text('Marcas de hoy', style: t.textTheme.titleMedium),
      const SizedBox(height: Space.sm),
      if (marks.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.lg),
          child: Text('Aún no ha marcado hoy.', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
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
        backgroundColor: t.colorScheme.secondaryContainer,
        child: Icon(mark.isIn ? Icons.login : Icons.logout, color: t.colorScheme.onSecondaryContainer),
      ),
      title: Text('${markTypeLabel(mark.type)} · ${Fmt.time(mark.recordedAt)}'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Space.xs),
        child: Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [
          StatusBadge(label: status.label, icon: status.icon, tone: status.tone, dense: true),
          if (mark.deferred) const StatusBadge(label: 'Enviada sin conexión', icon: Icons.cloud_off_outlined, tone: Tone.neutral, dense: true),
          if (!mark.accepted && mark.message != null) Text(mark.message!, style: t.textTheme.bodySmall),
        ]),
      ),
    );
  }
}
