import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/common.dart';
import '../../../core/strings.dart';
import '../data/supervisor_api.dart';
import '../data/supervisor_models.dart';
import 'supervisor_shell.dart';
import 'worksite_filter.dart';

/// Every mark (rejected ones too) in a date range, with CSV copy for spreadsheets.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTimeRange _range = () {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
  }();
  int? _worksiteId;
  bool _onlyIssues = false;

  MarksQuery get _query => (from: _range.start, to: _range.end, worksiteId: _worksiteId);

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: S.reportPeriod,
    );
    if (r != null) setState(() => _range = r);
  }

  /// Tab-separated cell: pastes straight into spreadsheet columns. Neutralizes formula prefixes.
  static String _csvCell(String v) {
    final s = v.replaceAll(RegExp(r'[\t\r\n]'), ' ');
    return s.isNotEmpty && '=+-@'.contains(s[0]) ? "'$s" : s;
  }

  Future<void> _copyCsv(List<MarkRow> rows) async {
    final b = StringBuffer('Date\tTime\tEmployee ID\tEmployee\tJob site\tType\tStatus\tReason\tDistance (ft)\tAccuracy (ft)\tOffline\n');
    for (final r in rows) {
      final m = r.mark;
      final local = m.recordedAt.toLocal();
      b.writeln([
        Fmt.isoDate(local),
        Fmt.time(local),
        _csvCell(r.employeeDocument),
        _csvCell(r.employeeName),
        _csvCell(r.worksiteName),
        markTypeLabel(m.type),
        markStatusLabel(m.status).label,
        _csvCell(m.message ?? ''),
        m.distanceMeters == null ? '' : Fmt.metersToFeet(m.distanceMeters!).toString(),
        Fmt.metersToFeet(m.accuracyMeters).toString(),
        m.deferred ? 'yes' : 'no',
      ].join('\t'));
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (mounted) showMessage(context, S.csvCopied(rows.length));
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(marksProvider(_query));
    final data = rows.value;
    final filtered = data == null
        ? null
        : _onlyIssues
            ? data.where((r) => r.mark.status != 'ON_TIME').toList()
            : data;
    return Scaffold(
      appBar: SupervisorAppBar(title: S.reportsTitle, actions: [
        IconButton(
          tooltip: S.copyCsv,
          icon: const Icon(Icons.content_copy_outlined),
          onPressed: filtered == null || filtered.isEmpty ? null : () => _copyCsv(filtered),
        ),
      ]),
      body: Column(children: [
        MaxWidth(
          width: 1100,
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Wrap(spacing: Space.md, runSpacing: Space.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text('${Fmt.day(_range.start)} – ${Fmt.day(_range.end)}'),
              ),
              WorksiteFilter(value: _worksiteId, onChanged: (id) => setState(() => _worksiteId = id)),
              FilterChip(
                label: const Text(S.onlyIssues),
                avatar: const Icon(Icons.report_gmailerrorred_outlined, size: 18),
                selected: _onlyIssues,
                onSelected: (v) => setState(() => _onlyIssues = v),
              ),
            ]),
          ),
        ),
        Expanded(
          child: switch (rows) {
            AsyncError(:final error) => ErrorState(message: '$error', onRetry: () => ref.invalidate(marksProvider(_query))),
            AsyncData() when filtered!.isEmpty =>
              const EmptyState(icon: Icons.inbox_outlined, title: S.noPunchesInPeriod),
            AsyncData() => ListView.builder(
                padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xxl),
                itemCount: filtered!.length,
                itemBuilder: (_, i) => MaxWidth(width: 1100, child: _MarkRowTile(row: filtered[i])),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ]),
    );
  }
}

class _MarkRowTile extends StatelessWidget {
  const _MarkRowTile({required this.row});

  final MarkRow row;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final m = row.mark;
    final s = markStatusLabel(m.status);
    final local = m.recordedAt.toLocal();
    return Column(children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(m.isIn ? Icons.login : Icons.logout),
        title: Text('${row.employeeName} · ${markTypeLabel(m.type)}'),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${Fmt.day(local)} ${Fmt.time(local)} · ${row.worksiteName.isEmpty ? S.noSite : row.worksiteName}'
              '${m.distanceMeters == null ? '' : ' · ${Fmt.distance(m.distanceMeters!)}'}'),
          if (m.message != null) Text(m.message!, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.error)),
        ]),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusBadge(label: s.label, icon: s.icon, tone: s.tone, dense: true),
          if (m.deferred) ...[
            const SizedBox(height: Space.xs),
            const StatusBadge(label: S.offline, icon: Icons.cloud_off_outlined, tone: Tone.neutral, dense: true),
          ],
        ]),
      ),
      const Divider(height: 1),
    ]);
  }
}
