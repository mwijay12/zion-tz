import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Declarative staggered entrance for cards, tiles and list items.
///
/// Wraps [child] with a fade + slide-up reveal delayed by [index] so
/// sections cascade in on first paint instead of popping in all at once.
///
/// ```dart
/// StaggeredReveal(index: 0, child: _buildCountdownBanner())
/// StaggeredReveal(index: 1, child: _buildQuickActionGrid())
/// ```
///
/// Uses `flutter_animate` — no manual AnimationControllers, no setState
/// per tick. Safe inside SliverList children (each child animates once
/// on first build).
class StaggeredReveal extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration step;

  const StaggeredReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 70),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          duration: 420.ms,
          delay: step * index,
          curve: Curves.easeOutExpo,
        )
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 420.ms,
          delay: step * index,
          curve: Curves.easeOutExpo,
        );
  }
}

/// Springy tap feedback for action tiles: a quick scale bounce (<180ms)
/// paired with haptic feedback at the call site.
///
/// Implemented with a short [AnimationController] (no `setState` per
/// tick beyond the controller's own repaint) so it stays at 60fps.
class TapBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TapBounce({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<TapBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
