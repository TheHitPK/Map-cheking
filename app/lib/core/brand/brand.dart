import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// PinPunch brand palette. Navy on orange and white on navy both pass WCAG AA (5.4:1 and 15.4:1).
abstract final class BrandColors {
  /// Survey Navy: primary brand colour, text on orange.
  static const navy = Color(0xFF0B2545);
  static const navy700 = Color(0xFF13315C);

  /// Hi-Vis Orange: the "punch", primary call to action. Never small text on white (2.9:1).
  static const orange = Color(0xFFFF6B1A);

  /// Route Blue: maps, routes, secondary accents.
  static const route = Color(0xFF8DA9C4);

  /// Concrete: warm light background.
  static const concrete = Color(0xFFF5F3EE);
}

/// The PinPunch mark: a map pin whose head carries a check — "you're here, and it counts".
/// Drawn in a 100×100 box; [check] animates the check stroke (0 → 1).
class PinPunchPainter extends CustomPainter {
  const PinPunchPainter({
    this.pinColor = BrandColors.navy,
    this.checkColor = BrandColors.orange,
    this.check = 1,
    this.knockout = false,
  });

  final Color pinColor;
  final Color checkColor;
  final double check;

  /// Cut the check out of the pin instead of painting it (single-colour / themed icons).
  final bool knockout;

  static Path pinPath() => Path()
    ..moveTo(50, 95)
    ..cubicTo(50, 95, 19, 63, 19, 40)
    ..arcToPoint(const Offset(81, 40), radius: const Radius.circular(31), clockwise: true)
    ..cubicTo(81, 63, 50, 95, 50, 95)
    ..close();

  static Path checkPath() => Path()
    ..moveTo(36, 41)
    ..lineTo(46.5, 51.5)
    ..lineTo(65, 30);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas
      ..save()
      ..translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2)
      ..scale(s);
    if (knockout) canvas.saveLayer(const Rect.fromLTWH(0, 0, 100, 100), Paint());
    canvas.drawPath(pinPath(), Paint()..color = pinColor);
    if (check > 0) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = checkColor;
      if (knockout) stroke.blendMode = BlendMode.clear;
      canvas.drawPath(_partial(checkPath(), check.clamp(0, 1)), stroke);
    }
    if (knockout) canvas.restore();
    canvas.restore();
  }

  static Path _partial(Path path, double t) {
    if (t >= 1) return path;
    final out = Path();
    var remaining = path.computeMetrics().fold<double>(0, (a, m) => a + m.length) * t;
    for (final m in path.computeMetrics()) {
      final take = math.min(remaining, m.length);
      out.addPath(m.extractPath(0, take), Offset.zero);
      remaining -= take;
      if (remaining <= 0) break;
    }
    return out;
  }

  @override
  bool shouldRepaint(PinPunchPainter old) =>
      old.check != check || old.pinColor != pinColor || old.checkColor != checkColor || old.knockout != knockout;
}

class PinPunchMark extends StatelessWidget {
  const PinPunchMark({super.key, this.size = 48, this.pinColor, this.checkColor = BrandColors.orange, this.check = 1});

  final double size;
  final Color? pinColor;
  final Color checkColor;
  final double check;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'PinPunch',
        image: true,
        child: CustomPaint(
          size: Size.square(size),
          painter: PinPunchPainter(
            pinColor: pinColor ?? Theme.of(context).colorScheme.primary,
            checkColor: checkColor,
            check: check,
          ),
        ),
      );
}

/// "PinPunch" wordmark: "Pin" in the pin colour, "Punch" in orange.
class PinPunchWordmark extends StatelessWidget {
  const PinPunchWordmark({super.key, this.fontSize = 28, this.subtitle});

  final double fontSize;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final pin = Theme.of(context).colorScheme.primary;
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Pin', style: style.copyWith(color: pin)),
          TextSpan(text: 'Punch', style: style.copyWith(color: BrandColors.orange)),
        ]),
        semanticsLabel: 'PinPunch',
      ),
      if (subtitle != null) ...[
        SizedBox(height: fontSize * 0.25),
        Text(subtitle!.toUpperCase(),
            style: TextStyle(
                fontSize: fontSize * 0.36, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    ]);
  }
}

/// Brand moment for login and splash: a dashed route draws in, the pin drops on its end, the check punches.
/// Shows the final frame when the user asked the OS to reduce motion.
class RouteToPinHero extends StatefulWidget {
  const RouteToPinHero({super.key, this.size = 160});

  final double size;

  @override
  State<RouteToPinHero> createState() => _RouteToPinHeroState();
}

class _RouteToPinHeroState extends State<RouteToPinHero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pin = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final route = Curves.easeInOut.transform((_c.value / 0.55).clamp(0, 1));
          final drop = Curves.easeOutBack.transform(((_c.value - 0.45) / 0.3).clamp(0, 1));
          final check = Curves.easeOut.transform(((_c.value - 0.72) / 0.28).clamp(0, 1));
          return CustomPaint(
            size: Size(widget.size * 1.6, widget.size),
            painter: _RoutePainter(progress: route, color: BrandColors.route),
            child: SizedBox(
              width: widget.size * 1.6,
              height: widget.size,
              child: Align(
                alignment: const Alignment(0.55, -0.35),
                child: Opacity(
                  opacity: drop.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, (1 - drop) * -widget.size * 0.25),
                    child: CustomPaint(
                      size: Size.square(widget.size * 0.62),
                      painter: PinPunchPainter(pinColor: pin, check: check),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Ends under the pin's tip (pin centred at x = 0.775 w).
    final route = Path()
      ..moveTo(w * 0.04, h * 0.86)
      ..cubicTo(w * 0.30, h * 0.98, w * 0.30, h * 0.52, w * 0.52, h * 0.62)
      ..cubicTo(w * 0.66, h * 0.69, w * 0.70, h * 0.86, w * 0.775, h * 0.80);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.035
      ..strokeCap = StrokeCap.round
      ..color = color;
    final metric = route.computeMetrics().first;
    final end = metric.length * progress;
    final dash = h * 0.07, gap = h * 0.055;
    for (var d = 0.0; d < end; d += dash + gap) {
      canvas.drawPath(metric.extractPath(d, math.min(d + dash, end)), paint);
    }
    if (progress > 0) {
      canvas.drawCircle(Offset(w * 0.04, h * 0.86), h * 0.04, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.progress != progress || old.color != color;
}

/// Renders the mark to PNG bytes (used by the icon generator in tool/).
Future<List<int>> renderIconPng({
  required int size,
  required Color background,
  required Color pin,
  required Color check,
  double markScale = 0.62,
  double cornerRadius = 0,
  bool transparent = false,
  bool knockout = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (!transparent) {
    final bg = Paint()..color = background;
    cornerRadius > 0
        ? canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(cornerRadius * s)), bg)
        : canvas.drawRect(Rect.fromLTWH(0, 0, s, s), bg);
  }
  final m = s * markScale;
  canvas.translate((s - m) / 2, (s - m) / 2 + m * 0.02);
  PinPunchPainter(pinColor: pin, checkColor: check, knockout: knockout).paint(canvas, Size.square(m));
  final image = recorder.endRecording().toImageSync(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
