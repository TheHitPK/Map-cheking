import 'package:flutter/material.dart';

/// Spacing scale (4 dp rhythm).
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Semantic status colours. Always paired with an icon and a label: colour never carries meaning alone.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.neutralContainer,
    required this.onNeutralContainer,
  });

  final Color success, onSuccess, successContainer, onSuccessContainer;
  final Color warning, onWarning, warningContainer, onWarningContainer;
  final Color neutralContainer, onNeutralContainer;

  // Light: all text/background pairs ≥ 4.5:1.
  static const light = StatusColors(
    success: Color(0xFF15803D),
    onSuccess: Colors.white,
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF14532D),
    warning: Color(0xFFB45309),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFEF3C7),
    onWarningContainer: Color(0xFF78350F),
    neutralContainer: Color(0xFFE2E8F0),
    onNeutralContainer: Color(0xFF1E293B),
  );

  // Dark: desaturated tones, not inverted.
  static const dark = StatusColors(
    success: Color(0xFF4ADE80),
    onSuccess: Color(0xFF052E16),
    successContainer: Color(0xFF14532D),
    onSuccessContainer: Color(0xFFDCFCE7),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF451A03),
    warningContainer: Color(0xFF78350F),
    onWarningContainer: Color(0xFFFEF3C7),
    neutralContainer: Color(0xFF334155),
    onNeutralContainer: Color(0xFFE2E8F0),
  );

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) =>
      other is StatusColors && t >= 0.5 ? other : this;
}

extension StatusColorsX on BuildContext {
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}

/// Utilitarian, high-contrast Material 3 theme: readable outdoors in sunlight, large touch targets.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E40AF),
    brightness: brightness,
    error: brightness == Brightness.light ? const Color(0xFFB91C1C) : const Color(0xFFF87171),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  const buttonSize = Size(64, 52);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return base.copyWith(
    extensions: [brightness == Brightness.light ? StatusColors.light : StatusColors.dark],
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: buttonSize, shape: shape, textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: buttonSize, shape: shape, textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: scheme.surfaceContainerLow,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: Space.md),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
