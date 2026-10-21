import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum Tone { success, warning, danger, neutral, info }

/// Status label: icon + text on a tinted container. Colour is never the only signal.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.icon, required this.tone, this.dense = false});

  final String label;
  final IconData icon;
  final Tone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? Space.sm : Space.md, vertical: dense ? 2 : Space.xs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: dense ? 14 : 18, color: fg),
        const SizedBox(width: Space.xs),
        Flexible(
          child: Text(label,
              style: (dense ? Theme.of(context).textTheme.labelMedium : Theme.of(context).textTheme.labelLarge)
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

(Color, Color) toneColors(BuildContext context, Tone tone) {
  final s = context.status;
  final c = Theme.of(context).colorScheme;
  return switch (tone) {
    Tone.success => (s.successContainer, s.onSuccessContainer),
    Tone.warning => (s.warningContainer, s.onWarningContainer),
    Tone.danger => (c.errorContainer, c.onErrorContainer),
    Tone.info => (c.primaryContainer, c.onPrimaryContainer),
    Tone.neutral => (s.neutralContainer, s.onNeutralContainer),
  };
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: t.colorScheme.onSurfaceVariant),
          const SizedBox(height: Space.lg),
          Text(title, style: t.textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: Space.sm),
            Text(message!, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: Space.xl), action!],
        ]),
      ),
    );
  }
}

/// Error with a recovery path.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudo cargar',
        message: message,
        action: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      );
}

/// Centres content and caps its width on large screens (readable measure on web/tablets).
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.width = 720});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: width), child: child));
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  final c = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? c.error : null,
      duration: const Duration(seconds: 4),
    ));
}
