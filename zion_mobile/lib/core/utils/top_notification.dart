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

class _TopAlertWidgetState extends State<_TopAlertWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnimation = Tween<double>(begin: -60.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
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
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.bgStart, widget.bgEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.borderColor, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
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
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.message != null && widget.message!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.message!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11.5,
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
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
