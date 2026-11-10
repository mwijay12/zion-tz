import 'package:flutter/material.dart';

/// Counts up smoothly to [value] whenever it changes (TZS totals, KPI
/// figures, attendance counts). Uses [TweenAnimationBuilder] so no
/// `setState` is called per animation tick — 60fps safe.
///
/// Example:
/// ```dart
/// AnimatedTshCounter(value: GivingService.buildingRaised)
/// AnimatedCount(value: 128, suffix: ' waumini')
/// ```
class AnimatedTshCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedTshCounter({
    super.key,
    required this.value,
    this.prefix = 'TSh ',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final rounded = animatedValue.round();
        final formatted = rounded.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );
        return Text(
          '$prefix$formatted$suffix',
          style: style,
        );
      },
    );
  }
}

/// Generic integer counter for non-currency figures (attendance, streaks).
class AnimatedCount extends StatelessWidget {
  final double value;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          '${animatedValue.round()}$suffix',
          style: style,
        );
      },
    );
  }
}
