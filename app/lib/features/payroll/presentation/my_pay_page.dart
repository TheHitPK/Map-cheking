import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/brand/brand.dart';
import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../../../core/widgets/common.dart';
import '../data/payroll_api.dart';
import '../data/payroll_models.dart';
import 'pay_widgets.dart';

/// Crew member: what the next paycheck should be and when, this week so far, and past paychecks.
class MyPayPage extends ConsumerWidget {
  const MyPayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pay = ref.watch(myPayProvider);
    Future<void> reload() => ref.refresh(myPayProvider.future);
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.myPayTitle),
        actions: [IconButton(tooltip: S.refresh, icon: const Icon(Icons.refresh), onPressed: pay.isLoading ? null : reload)],
      ),
      body: switch (pay) {
        AsyncData(:final value) => RefreshIndicator(onRefresh: reload, child: _Content(pay: value)),
        AsyncError(:final error) when !pay.isLoading => ErrorState(message: '$error', onRetry: reload),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.pay});

  final MyPay pay;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    // Last week's check is the news until it is paid; after that, this week's running total is.
    final upcoming = !pay.previous.paid && pay.previous.pay.totalMinutes > 0 ? pay.previous : null;
    final current = pay.current;
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      MaxWidth(
        width: 560,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Hero(stub: upcoming ?? current, isNextCheck: upcoming != null),
          if (pay.hourlyRateCents == null) ...[
            const SizedBox(height: Space.md),
            const StatusBadge(label: S.rateNotSet, icon: Icons.info_outline, tone: Tone.warning),
          ],
          if (upcoming != null && upcoming.missingPunchOuts > 0) ...[
            const SizedBox(height: Space.md),
            PayIssues(missingPunchOuts: upcoming.missingPunchOuts, punchedIn: false),
          ],
          const SizedBox(height: Space.xl),
          Row(children: [
            Expanded(child: Text(S.thisWeek, style: t.textTheme.titleMedium)),
            Text(Fmt.dayRange(current.periodStart, current.periodEnd),
                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: Space.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (current.missingPunchOuts > 0 || current.punchedIn) ...[
                  PayIssues(missingPunchOuts: current.missingPunchOuts, punchedIn: current.punchedIn),
                  const SizedBox(height: Space.md),
                ],
                if (current.pay.totalMinutes == 0 && current.missingPunchOuts == 0)
                  Text(S.noTimeYet, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))
                else
                  PayBreakdown(days: current.days, pay: current.pay, grossLabel: S.estGross),
              ]),
            ),
          ),
          if (current.missingPunchOuts > 0 || (upcoming?.missingPunchOuts ?? 0) > 0) ...[
            const SizedBox(height: Space.sm),
            Text(S.missingPunchOutHelp, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: Space.xl),
          Text(S.pastPaychecks, style: t.textTheme.titleMedium),
          const SizedBox(height: Space.sm),
          if (pay.history.isEmpty)
            Text(S.noPaychecksYet, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))
          else
            Card(
              child: Column(children: [
                for (final (i, w) in pay.history.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.check_circle, color: context.status.success),
                    title: Text(Fmt.dayRange(w.periodStart, w.periodEnd)),
                    subtitle: Text('${S.paidOn(Fmt.day(w.paidOn))} · ${Fmt.hours(w.pay.totalMinutes)}'),
                    trailing: Text(w.pay.grossCents == null ? '—' : Fmt.money(w.pay.grossCents!),
                        style: t.textTheme.titleMedium?.copyWith(fontFeatures: tabular)),
                  ),
                ],
              ]),
            ),
          const SizedBox(height: Space.xl),
          Text(S.grossDisclaimer,
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ]),
      ),
    ]);
  }
}

/// Navy card with the amount front and centre and the payday under it.
class _Hero extends StatelessWidget {
  const _Hero({required this.stub, required this.isNextCheck});

  final PayStub stub;
  final bool isNextCheck;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const muted = BrandColors.route;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Space.xl),
        decoration: BoxDecoration(color: BrandColors.navy, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isNextCheck ? Icons.payments_outlined : Icons.timelapse, color: BrandColors.orange, size: 20),
            const SizedBox(width: Space.sm),
            Text(isNextCheck ? S.nextPaycheck : S.thisWeekSoFar,
                style: t.labelLarge?.copyWith(color: muted, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          ]),
          const SizedBox(height: Space.sm),
          MoneyText(stub.pay.grossCents,
              style: t.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: Space.md),
          Row(children: [
            const Icon(Icons.event, color: Colors.white, size: 18),
            const SizedBox(width: Space.xs),
            Text(S.payday(Fmt.day(stub.payDate)),
                style: t.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: Space.xs),
          Text(S.forWeek(Fmt.dayRange(stub.periodStart, stub.periodEnd), Fmt.hours(stub.pay.totalMinutes)),
              style: t.bodyMedium?.copyWith(color: muted)),
        ]),
      ),
    );
  }
}
