import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

class LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int index) onTabSelected;
  final VoidCallback onMoreTapped;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onMoreTapped,
  });

  static const List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Home',
      'icon': Icons.church_rounded,
      'tooltip': 'Mwanzo (Home)',
    },
    {
      'label': 'Community',
      'icon': Icons.diversity_3_rounded,
      'tooltip': 'Ushirika & Jumuiya',
    },
    {
      'label': 'Media',
      'icon': Icons.play_circle_fill_rounded,
      'tooltip': 'Mahubiri & Nyimbo',
    },
    {
      'label': 'Book',
      'icon': Icons.auto_stories_rounded,
      'tooltip': 'Biblia, Tenzi & Madokezo',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final pillColors = isDark
        ? (highContrast
            ? const [Color(0xFF0F172A), Color(0xFF161F30)]
            : const [Color(0xF5181C23), Color(0xEB1E232A)])
        : (highContrast
            ? const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)]
            : const [Color(0xF2FFFFFF), Color(0xE6EFF6FF)]);

    final blurSigma = highContrast ? 0.0 : 18.0;

    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // 1. Frosted Liquid Glass Main Pill (4 Navigation Destinations)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  height: 62,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: pillColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: highContrast ? 0.45 : 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.35 : 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_navItems.length, (idx) {
                      final item = _navItems[idx];
                      final isSelected = currentIndex == idx;
                      return _LiquidNavTabButton(
                        index: idx,
                        icon: item['icon'] as IconData,
                        tooltip: item['tooltip'] as String,
                        isSelected: isSelected,
                        isDark: isDark,
                        disableAnimations: disableAnimations,
                        onTap: () => onTabSelected(idx),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. Separate Floating Circular Quick More Options Hub (58x58 symmetric)
          Tooltip(
            message: 'Huduma Zaidi & Menyu ya Sayuni',
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AppHaptics.mediumImpact();
                      onMoreTapped();
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: pillColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.35 : 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            color: isDark
                                ? AppColors.goldLight
                                : AppColors.goldDark,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidNavTabButton extends StatefulWidget {
  final int index;
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final bool isDark;
  final bool disableAnimations;
  final VoidCallback onTap;

  const _LiquidNavTabButton({
    required this.index,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.isDark,
    required this.disableAnimations,
    required this.onTap,
  });

  @override
  State<_LiquidNavTabButton> createState() => _LiquidNavTabButtonState();
}

class _LiquidNavTabButtonState extends State<_LiquidNavTabButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;
    final duration = widget.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return Semantics(
      button: true,
      selected: isSelected,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            AppHaptics.selectionClick();
            widget.onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed && !widget.disableAnimations ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: isSelected ? 46 : 42,
              height: isSelected ? 46 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.primary.withValues(alpha: 0.07)),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.35)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.borderLight),
                  width: isSelected ? 1.4 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.38),
                          blurRadius: 16,
                          spreadRadius: 1.2,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: isSelected ? 22 : 20,
                    color: isSelected
                        ? const Color(0xFFFFFFFF)
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF5A6B85)),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
