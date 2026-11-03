import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'haptics.dart';

enum TopAlertType { info, success, warning, error }

class AppTopAlert {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    TopAlertType type = TopAlertType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    AppHaptics.lightImpact();

    // Dismiss existing toast if active
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    Color bgStart;
    Color bgEnd;
    Color borderColor;
    IconData icon;

    switch (type) {
      case TopAlertType.success:
        bgStart = const Color(0xFF0F5132);
        bgEnd = const Color(0xFF198754);
        borderColor = const Color(0xFF22C55E);
        icon = Icons.check_circle_rounded;
        break;
      case TopAlertType.error:
        bgStart = const Color(0xFF842029);
        bgEnd = const Color(0xFFDC2626);
        borderColor = const Color(0xFFF87171);
        icon = Icons.error_rounded;
        break;
      case TopAlertType.warning:
        bgStart = const Color(0xFF78350F);
        bgEnd = const Color(0xFFD97706);
        borderColor = const Color(0xFFFBBF24);
        icon = Icons.warning_amber_rounded;
        break;
      case TopAlertType.info:
        bgStart = const Color(0xFF0A2540);
        bgEnd = const Color(0xFF0D52CD);
        borderColor = AppColors.gold;
        icon = Icons.notifications_active_rounded;
        break;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopAlertWidget(
        title: title,
        message: message,
        bgStart: bgStart,
        bgEnd: bgEnd,
        borderColor: borderColor,
        icon: icon,
        onTap: () {
          _dismiss();
          onTap?.call();
        },
        onDismiss: _dismiss,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      _currentEntry?.remove();
      _currentEntry = null;
    }
  }
}

class _TopAlertWidget extends StatefulWidget {
  final String title;
  final String? message;
  final Color bgStart;
  final Color bgEnd;
  final Color borderColor;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopAlertWidget({
    required this.title,
    this.message,
    required this.bgStart,
    required this.bgEnd,
    required this.borderColor,
    required this.icon,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TopAlertWidget> createState() => _TopAlertWidgetState();
}

class _TopAlertWidgetState extends State<_TopAlertWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    // Smooth deceleration curve mimicking iOS / Sonner physics
    _slideAnimation = Tween<double>(begin: -48.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.23, 1.0, 0.32, 1.0),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.23, 1.0, 0.32, 1.0),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 14,
      right: 14,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: Dismissible(
          key: const Key('top_toast_dismissible'),
          direction: DismissDirection.up,
          onDismissed: (_) {
            AppHaptics.lightImpact();
            widget.onDismiss();
          },
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                widget.onTap();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.bgStart.withOpacity(0.96),
                      widget.bgEnd.withOpacity(0.92)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.borderColor.withOpacity(0.85),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: widget.borderColor.withOpacity(0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.message != null &&
                              widget.message!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.message!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        AppHaptics.lightImpact();
                        widget.onDismiss();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
