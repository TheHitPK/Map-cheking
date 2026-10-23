import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../../../core/widgets/common.dart';
import '../data/payroll_models.dart';

const tabular = [FontFeature.tabularFigures()];

/// Dollar amount that counts up when it first shows or changes (instant when the OS asks to reduce motion).
class MoneyText extends StatelessWidget {
  const MoneyText(this.cents, {super.key, this.style});

  /// Null shows a dash (no rate set).
  final int? cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = (style ?? DefaultTextStyle.of(context).style).copyWith(fontFeatures: tabular);
    final value = cents;
    if (value == null) return Text('—', style: s);
    if (MediaQuery.disableAnimationsOf(context)) return Text(Fmt.money(value), style: s);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(Fmt.money(v.round()), style: s, semanticsLabel: Fmt.money(value)),
    );
  }
}

/// One label/value row of a pay breakdown.
class PayRow extends StatelessWidget {
  const PayRow(this.label, this.value, {super.key, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = (strong ? t.titleMedium?.copyWith(fontWeight: FontWeight.w700) : t.bodyLarge)
        ?.copyWith(fontFeatures: tabular);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(children: [
        Expanded(child: Text(label, style: strong ? style : style?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Text(value, style: style),
      ]),
    );
  }
}

/// Hours per day, then regular / overtime / rate / gross.
class PayBreakdown extends StatelessWidget {
  const PayBreakdown({super.key, required this.days, required this.pay, this.grossLabel = S.grossLabel});

  final List<DayMinutes> days;
  final Pay pay;
  final String grossLabel;

  @override
  Widget build(BuildContext context) {
    final rate = pay.hourlyRateCents;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final d in days) PayRow(Fmt.day(d.date), Fmt.hours(d.minutes)),
      if (days.isNotEmpty) const Divider(height: Space.lg),
      PayRow(S.regular, Fmt.hours(pay.regularMinutes)),
      if (pay.overtimeMinutes > 0) PayRow(S.overtimeLabel, Fmt.hours(pay.overtimeMinutes)),
      PayRow(S.rateLabel, rate == null ? S.noRate : Fmt.rate(rate)),
      PayRow(grossLabel, pay.grossCents == null ? '—' : Fmt.money(pay.grossCents!), strong: true),
    ]);
  }
}

/// Badges for what needs attention in a week: missing punch-outs, open shift, no rate.
class PayIssues extends StatelessWidget {
  const PayIssues({super.key, required this.missingPunchOuts, required this.punchedIn});

  final int missingPunchOuts;
  final bool punchedIn;

  @override
  Widget build(BuildContext context) {
    final badges = [
      if (missingPunchOuts > 0)
        StatusBadge(label: S.missingPunchOuts(missingPunchOuts), icon: Icons.warning_amber_rounded, tone: Tone.warning, dense: true),
      if (punchedIn) const StatusBadge(label: S.stillPunchedIn, icon: Icons.timelapse, tone: Tone.info, dense: true),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: Space.sm, runSpacing: Space.sm, children: badges);
  }
}
