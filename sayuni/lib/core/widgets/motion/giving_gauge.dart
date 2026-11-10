import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// Self-drawing church giving gauge (building project progress).
///
/// Adapted from the fintech credit-gauge pattern (`CustomPainter` +
/// `PathMetrics` self-drawing checkmark) for the church context:
/// gold/navy sanctuary palette, Swahili labels, TZS counter in the centre.
///
/// Performance: the [AnimationController] is passed directly to the
/// painter via `repaint:` — no `setState` per tick. Wrapped in a
/// [RepaintBoundary] so it repaints in isolation at 60/120fps.
class ChurchGivingGauge extends StatefulWidget {
  /// 0.0 → 1.0 (e.g. 0.57 = 57% imelipwa)
  final double progress;
  final double raisedTzs;
  final double targetTzs;
  final double size;

  const ChurchGivingGauge({
    super.key,
    required this.progress,
    required this.raisedTzs,
    required this.targetTzs,
    this.size = 220,
  });

  @override
  State<ChurchGivingGauge> createState() => _ChurchGivingGaugeState();
}

class _ChurchGivingGaugeState extends State<ChurchGivingGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1, 0.3, 1), // Expressive expo-out
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ChurchGivingGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.raisedTzs != widget.raisedTzs) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0.0, 1.0);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _curved,
        builder: (context, _) {
          final t = _curved.value;
          final animatedRaised = widget.raisedTzs * t;
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GivingGaugePainter(
              progress: clamped * t,
              drawProgress: t,
            ),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ZILIZOPATIKANA',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.textMutedOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.formatTsh(animatedRaised.roundToDouble()),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(clamped * t * 100).toStringAsFixed(0)}% ya lengo',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GivingGaugePainter extends CustomPainter {
  final double progress;
  final double drawProgress;

  _GivingGaugePainter({
    required this.progress,
    required this.drawProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // 1. Background track arc (theme-aware via singleton, no context needed)
    final trackPaint = Paint()
      ..color = AppColors.surfaceContainer
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // 2. Animated gold gradient foreground arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.goldDark, AppColors.gold, AppColors.goldLight],
      ).createShader(rect)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, activePaint);

    // 3. Self-drawing checkmark at the bottom of the gauge (PathMetrics)
    final checkPath = Path()
      ..moveTo(center.dx - 12, center.dy + radius - 10)
      ..lineTo(center.dx - 3, center.dy + radius - 1)
      ..lineTo(center.dx + 14, center.dy + radius - 18);

    final checkPaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final PathMetric metric in checkPath.computeMetrics()) {
      final extracted =
          metric.extractPath(0, metric.length * drawProgress);
      canvas.drawPath(extracted, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GivingGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.drawProgress != drawProgress;
}
