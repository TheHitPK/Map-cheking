import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/labels.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../data/supervisor_api.dart';
import '../data/supervisor_models.dart';
import 'supervisor_shell.dart';
import 'worksite_filter.dart';

/// Who arrived, who is late, who is missing — per day and worksite.
class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  int? _worksiteId;
  String? _stateFilter;
  Timer? _autoRefresh;

  DailyQuery get _query => (date: _date, worksiteId: _worksiteId);

  @override
  void initState() {
    super.initState();
    // Live view: refresh today's board every minute.
    _autoRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (DateUtils.isSameDay(_date, DateTime.now())) ref.invalidate(dailyProvider(_query));
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(dailyProvider(_query));
    final isToday = DateUtils.isSameDay(_date, DateTime.now());
    return Scaffold(
      appBar: SupervisorAppBar(title: isToday ? 'Asistencia de hoy' : 'Asistencia', actions: [
        IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(dailyProvider(_query))),
      ]),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dailyProvider(_query).future),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: MaxWidth(
              width: 1100,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 0),
                child: Wrap(spacing: Space.md, runSpacing: Space.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(isToday ? 'Hoy, ${Fmt.day(_date)}' : Fmt.day(_date)),
                  ),
                  WorksiteFilter(value: _worksiteId, onChanged: (id) => setState(() => _worksiteId = id)),
                ]),
              ),
            ),
          ),
          ...switch (rows) {
            AsyncData(:final value) => _content(value),
            AsyncError(:final error) => [
                SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(message: '$error', onRetry: () => ref.invalidate(dailyProvider(_query)))),
              ],
            _ => [const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))],
          },
        ]),
      ),
    );
  }

  List<Widget> _content(List<DailyRow> all) {
    if (all.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.event_note_outlined,
            title: 'No hay trabajadores con horario',
            message: 'Asigne un horario y una obra a cada trabajador en la sección Personal.',
          ),
        ),
      ];
    }
    final counts = <String, int>{};
    for (final r in all) {
      counts[r.state] = (counts[r.state] ?? 0) + 1;
    }
    final onSite = all.where((r) => r.onSite).length;
    final rows = _stateFilter == null
        ? all
        : _stateFilter == 'ON_SITE'
            ? all.where((r) => r.onSite).toList()
            : all.where((r) => r.state == _stateFilter).toList();
    return [
      SliverToBoxAdapter(
        child: MaxWidth(
          width: 1100,
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              _CountChip(label: 'En obra', icon: Icons.engineering_outlined, count: onSite, selected: _stateFilter == 'ON_SITE',
                  onTap: () => _toggle('ON_SITE')),
              for (final s in const ['ON_TIME', 'LATE', 'ABSENT', 'PENDING'])
                _CountChip(
                  label: dayStateLabel(s).label,
                  icon: dayStateLabel(s).icon,
                  count: counts[s] ?? 0,
                  selected: _stateFilter == s,
                  onTap: () => _toggle(s),
                ),
            ]),
          ),
        ),
      ),
      if (rows.isEmpty)
        const SliverToBoxAdapter(child: EmptyState(icon: Icons.filter_alt_off_outlined, title: 'Nadie en este filtro')),
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (_, i) => MaxWidth(
          width: 1100,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
            child: _DailyCard(row: rows[i]),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
    ];
  }

  void _toggle(String s) => setState(() => _stateFilter = _stateFilter == s ? null : s);
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.icon, required this.count, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
        avatar: Icon(icon, size: 18),
        label: Text('$label · $count', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.row});

  final DailyRow row;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final state = dayStateLabel(row.state);
    final initials = row.fullName.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(child: Text(initials)),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row.fullName, style: t.textTheme.titleMedium),
              Text('${row.worksiteName} · turno ${Fmt.hhmm(row.shiftStart)}–${Fmt.hhmm(row.shiftEnd)}',
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              const SizedBox(height: Space.sm),
              Wrap(spacing: Space.lg, runSpacing: Space.xs, children: [
                _TimeLabel(label: 'Llegada', mark: row.inMark),
                _TimeLabel(label: 'Salida', mark: row.outMark),
              ]),
              const SizedBox(height: Space.sm),
              Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [
                StatusBadge(label: state.label, icon: state.icon, tone: state.tone, dense: true),
                if (row.onSite) const StatusBadge(label: 'En obra', icon: Icons.engineering_outlined, tone: Tone.info, dense: true),
                if (row.earlyLeave)
                  const StatusBadge(label: 'Salida anticipada', icon: Icons.directions_walk, tone: Tone.warning, dense: true),
                if (row.inMark?.deferred ?? false)
                  const StatusBadge(label: 'Llegada sin conexión', icon: Icons.cloud_off_outlined, tone: Tone.neutral, dense: true),
                if (row.rejectedAttempts > 0)
                  StatusBadge(
                    label: row.rejectedAttempts == 1 ? '1 intento rechazado' : '${row.rejectedAttempts} intentos rechazados',
                    icon: Icons.report_gmailerrorred_outlined,
                    tone: Tone.danger,
                    dense: true,
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.label, required this.mark});

  final String label;
  final Mark? mark;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final m = mark;
    final distance = m?.distanceMeters == null ? '' : ' · ${Fmt.distance(m!.distanceMeters!)}';
    return Text.rich(TextSpan(children: [
      TextSpan(text: '$label ', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      TextSpan(
        text: m == null ? '—' : '${Fmt.time(m.recordedAt)}$distance',
        style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    ]));
  }
}
