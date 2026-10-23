import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/haptics.dart';

/// Grounded surface card adhering to Google Stitch and anti-AI-vibe standards.
/// Prevents nested card soup by maintaining single-level card containers.
class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Detect if caller passed legacy light background
    final bool isLegacyLightBg = backgroundColor == null ||
        backgroundColor == AppColors.surfaceLight ||
        backgroundColor == AppColors.surfaceContainerLight ||
        backgroundColor == AppColors.surfaceLowLight ||
        backgroundColor == Colors.white;

    final bg = isDark
        ? (isLegacyLightBg ? AppColors.surfaceDark : backgroundColor!)
        : (backgroundColor ?? AppColors.surfaceLight);

    final bool isLegacyLightBorder = borderColor == null ||
        borderColor == AppColors.borderLight;

    final border = isDark
        ? (isLegacyLightBorder ? AppColors.borderDark : borderColor!)
        : (borderColor ?? AppColors.borderLight);

    final cardContent = Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.45) : AppColors.primaryDark.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          if (!isDark)
            BoxShadow(
              color: AppColors.gold.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.lightImpact();
            onTap!();
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
