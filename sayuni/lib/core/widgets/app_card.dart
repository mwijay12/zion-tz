import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/haptics.dart';

/// Grounded surface card adhering to Google Stitch and anti-AI-vibe standards.
/// Prevents nested card soup by maintaining single-level card containers.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    // Detect if caller passed legacy light background
    final bool isLegacyLightBg = widget.backgroundColor == null ||
        widget.backgroundColor == AppColors.surfaceLight ||
        widget.backgroundColor == AppColors.surfaceContainerLight ||
        widget.backgroundColor == AppColors.surfaceLowLight ||
        widget.backgroundColor == Colors.white;

    final bg = isDark
        ? (isLegacyLightBg ? AppColors.surfaceDark : widget.backgroundColor!)
        : (widget.backgroundColor ?? AppColors.surfaceLight);

    final bool isLegacyLightBorder =
        widget.borderColor == null || widget.borderColor == AppColors.borderLight;

    final border = isDark
        ? (isLegacyLightBorder ? AppColors.borderDark : widget.borderColor!)
        : (widget.borderColor ?? AppColors.borderLight);

    final cardContent = Container(
      clipBehavior: Clip.antiAlias,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          if (!isDark)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return AnimatedScale(
        scale: _isPressed && !disableAnimations ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (val) => setState(() => _isPressed = val),
            onTap: () {
              AppHaptics.lightImpact();
              widget.onTap!();
            },
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}
