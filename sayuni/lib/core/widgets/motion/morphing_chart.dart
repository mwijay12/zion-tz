import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/haptics.dart';

/// Morphing attendance chart for Jumuiya / church growth.
///
/// Tapping "Wiki Hii / Mwezi Huu" morphs the curve in place (550ms,
/// expo-out) instead of showing a loading spinner — the fintech
/// morphing-graph pattern adapted for church attendance.
///
/// Data is illustrative demo data (labelled as such in the UI) until
/// real attendance sync is wired. Values are 0.0 → 1.0 normalised.
class JumuiyaAttendanceChart extends StatefulWidget {
  const JumuiyaAttendanceChart({super.key});

  @override
  State<JumuiyaAttendanceChart> createState() => _JumuiyaAttendanceChartState();
}

class _JumuiyaAttendanceChartState extends State<JumuiyaAttendanceChart> {
  bool _isMonthly = false;

  // Illustrative attendance trajectory (normalised). Replace with real
  // Jumuiya report data when Firestore sync is live.
  final List<double> _weekly = [0.25, 0.55, 0.42, 0.78, 0.64, 0.92, 0.85];
  final List<double> _monthly = [0.40, 0.30, 0.72, 0.50, 0.88, 0.60, 0.96];

  @override
  Widget build(BuildContext context) {
    final targetData = _isMonthly ? _monthly : _weekly;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HUDHURIO YA JUMUIYA',
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mwenendo wa Ushiriki',
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() => _isMonthly = !_isMonthly);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isMonthly ? 'Mwezi Huu' : 'Wiki Hii',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: RepaintBoundary(
              child: TweenAnimationBuilder<List<double>>(
                tween: _ListDoubleTween(begin: _weekly, end: targetData),
                duration: const Duration(milliseconds: 550),
                curve: const Cubic(0.16, 1, 0.3, 1),
                builder: (context, animatedPoints, _) {
                  return CustomPaint(
                    painter: _SmoothSplineChartPainter(points: animatedPoints),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data ya sampuli ya onyesho — itaunganishwa na ripoti halisi za Jumuiya.',
            style: TextStyle(
              color: AppColors.textMutedOf(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListDoubleTween extends Tween<List<double>> {
  _ListDoubleTween({required super.begin, required super.end});

  @override
  List<double> lerp(double t) {
    return List<double>.generate(
      begin!.length,
      (i) => ui.lerpDouble(begin![i], end![i], t)!,
    );
  }
}

class _SmoothSplineChartPainter extends CustomPainter {
  final List<double> points;
  _SmoothSplineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final stepX = size.width / (points.length - 1);

    Offset getPoint(int i) =>
        Offset(i * stepX, size.height * (1 - points[i] * 0.85));

    path.moveTo(getPoint(0).dx, getPoint(0).dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = getPoint(i);
      final p1 = getPoint(i + 1);
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 1. Gradient fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.35),
          AppColors.primaryLight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // 2. Crisp bezier stroke
    final linePaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // 3. Highlight last point
    final lastPt = getPoint(points.length - 1);
    canvas.drawCircle(lastPt, 6, Paint()..color = AppColors.primaryLight);
    canvas.drawCircle(lastPt, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SmoothSplineChartPainter oldDelegate) => true;
}
