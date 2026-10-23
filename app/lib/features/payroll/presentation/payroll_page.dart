import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../../../core/widgets/common.dart';
import '../../supervisor/presentation/supervisor_shell.dart';
import '../data/payroll_api.dart';
import '../data/payroll_models.dart';
import 'pay_widgets.dart';

/// Supervisor: one week of crew pay, week by week, and marking a finished week as paid.
class PayrollPage extends ConsumerStatefulWidget {
  const PayrollPage({super.key});

  @override
  ConsumerState<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends ConsumerState<PayrollPage> {
  /// Opens on last week: the one to pay this Friday.
  late DateTime _monday = mondayOf(DateTime.now()).subtract(const Duration(days: 7));

  DateTime get _thisMonday => mondayOf(DateTime.now());

  void _shift(int weeks) => setState(() => _monday = DateTime(_monday.year, _monday.month, _monday.day + 7 * weeks));

  Future<void> _markPaid(Payroll p) async {
    final range = Fmt.dayRange(p.periodStart, p.periodEnd);
    final today = DateTime.now();
    var paidOn = DateTime(today.year, today.month, today.day);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          icon: const Icon(Icons.payments_outlined),
          title: Text(S.markPaidQuestion(range)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(S.markPaidBody(Fmt.money(p.totalGrossCents))),
            if (p.missingPunchOuts > 0) ...[
              const SizedBox(height: Space.md),
              StatusBadge(label: S.missingPunchOuts(p.missingPunchOuts), icon: Icons.warning_amber_rounded, tone: Tone.warning),
            ],
            const SizedBox(height: Space.lg),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text('${S.paidOnLabel}: ${Fmt.day(paidOn)}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: paidOn,
                  firstDate: p.periodEnd.add(const Duration(days: 1)),
                  lastDate: paidOn.isAfter(today) ? paidOn : today,
                );
                if (picked != null) setDialog(() => paidOn = picked);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.markAsPaid)),
          ],
        ),
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    try {
      await ref.read(payrollApiProvider).markPaid(p.periodStart, paidOn);
      ref.invalidate(payrollProvider(_monday));
      if (mounted) showMessage(context, S.markedPaid(range));
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(payrollProvider(_monday));
    Future<void> reload() => ref.refresh(payrollProvider(_monday).future);
    return Scaffold(
      appBar: SupervisorAppBar(title: S.payrollTitle, actions: [
        IconButton(tooltip: S.refresh, icon: const Icon(Icons.refresh), onPressed: week.isLoading ? null : reload),
      ]),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
          MaxWidth(
            width: 860,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _WeekPicker(
                monday: _monday,
                onPrevious: () => _shift(-1),
                onNext: _monday.isBefore(_thisMonday) ? () => _shift(1) : null,
              ),
              const SizedBox(height: Space.md),
              switch (week) {
                AsyncData(:final value) => _Week(payroll: value, onMarkPaid: () => _markPaid(value)),
                AsyncError(:final error) when !week.isLoading => ErrorState(message: '$error', onRetry: reload),
                _ => const Padding(padding: EdgeInsets.all(Space.xxl), child: Center(child: CircularProgressIndicator())),
              },
            ]),
          ),
        ]),
      ),
    );
  }
}

class _WeekPicker extends StatelessWidget {
  const _WeekPicker({required this.monday, required this.onPrevious, required this.onNext});

  final DateTime monday;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    return Row(children: [
      IconButton.outlined(tooltip: S.previousWeek, icon: const Icon(Icons.chevron_left), onPressed: onPrevious),
      Expanded(
        child: Text('${Fmt.dayRange(monday, sunday)}, ${sunday.year}',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      ),
      IconButton.outlined(tooltip: S.nextWeek, icon: const Icon(Icons.chevron_right), onPressed: onNext),
    ]);
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.payroll, required this.onMarkPaid});

  final Payroll payroll;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final p = payroll;
    final ended = p.endedBy(DateTime.now());
    final canPay = ended && !p.paid && p.withoutRate == 0 && !p.anyPunchedIn;
    final status = p.paid
        ? StatusBadge(label: S.paidOn(Fmt.day(p.payDate)), icon: Icons.check_circle, tone: Tone.success)
        : ended
            ? StatusBadge(label: S.payday(Fmt.day(p.payDate)), icon: Icons.event, tone: Tone.info)
            : const StatusBadge(label: S.inProgressWeek, icon: Icons.timelapse, tone: Tone.neutral);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            status,
            const SizedBox(height: Space.md),
            Text(p.paid ? S.grossLabel : S.estGross,
                style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            MoneyText(p.totalGrossCents, style: t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: Space.xs),
            Text('${S.hoursTotal(Fmt.hours(p.totalMinutes))} · ${S.crewCount(p.lines.length)}',
                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            if (p.withoutRate > 0 || p.missingPunchOuts > 0) ...[
              const SizedBox(height: Space.md),
              Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                if (p.withoutRate > 0)
                  StatusBadge(label: S.withoutRate(p.withoutRate), icon: Icons.money_off, tone: Tone.danger, dense: true),
                if (p.missingPunchOuts > 0)
                  StatusBadge(
                      label: S.missingPunchOuts(p.missingPunchOuts), icon: Icons.warning_amber_rounded, tone: Tone.warning, dense: true),
              ]),
            ],
            if (!p.paid) ...[
              const SizedBox(height: Space.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: t.colorScheme.tertiary, foregroundColor: t.colorScheme.onTertiary),
                  onPressed: canPay ? onMarkPaid : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text(S.markAsPaid),
                ),
              ),
              if (!canPay) ...[
                const SizedBox(height: Space.sm),
                Text(!ended ? S.weekNotOver : p.withoutRate > 0 ? S.setRatesFirst : S.stillPunchedIn,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ],
            ],
          ]),
        ),
      ),
      const SizedBox(height: Space.lg),
      if (p.lines.isEmpty)
        const EmptyState(icon: Icons.schedule, title: S.noCrewInWeek, message: S.noCrewInWeekHelp)
      else
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final (i, l) in p.lines.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _LineTile(line: l),
            ],
          ]),
        ),
      const SizedBox(height: Space.lg),
      Text(S.grossDisclaimer,
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
    ]);
  }
}

/// A crew member's week; expands to the per-day hours and the pay maths.
class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});

  final PayrollLine line;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pay = line.pay;
    final rate = pay.hourlyRateCents;
    final summary = [
      Fmt.hours(pay.totalMinutes),
      if (pay.overtimeMinutes > 0) S.overtime(Fmt.hours(pay.overtimeMinutes)),
      rate == null ? S.noRate : Fmt.rate(rate),
    ].join(' · ');
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(line.fullName, style: t.textTheme.titleMedium),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(summary, style: t.textTheme.bodyMedium?.copyWith(fontFeatures: tabular)),
        if (line.missingPunchOuts > 0 || line.punchedIn) ...[
          const SizedBox(height: Space.xs),
          PayIssues(missingPunchOuts: line.missingPunchOuts, punchedIn: line.punchedIn),
        ],
      ]),
      trailing: Text(pay.grossCents == null ? '—' : Fmt.money(pay.grossCents!),
          style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabular)),
      childrenPadding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
      children: [PayBreakdown(days: line.days, pay: pay)],
    );
  }
}
