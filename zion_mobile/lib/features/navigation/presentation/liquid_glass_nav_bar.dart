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
    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // 1. Frosted Liquid Glass Main Pill (4 Navigation Destinations)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    // Sleek Dark Pill Surface matching #1E232A with subtle Electric Blue trim
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF181C23).withValues(alpha: 0.96),
                        const Color(0xFF1E232A).withValues(alpha: 0.92),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
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
                      return _buildNavItem(
                        index: idx,
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        tooltip: item['tooltip'] as String,
                        isSelected: isSelected,
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
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: InkWell(
                  onTap: () {
                    AppHaptics.mediumImpact();
                    onMoreTapped();
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF181C23).withValues(alpha: 0.96),
                          const Color(0xFF1E232A).withValues(alpha: 0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
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
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: AppColors.goldLight,
                          size: 20,
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

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required String tooltip,
    required bool isSelected,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          AppHaptics.selectionClick();
          onTabSelected(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: isSelected ? 46 : 40,
          height: isSelected ? 46 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Active: Primary Electric Blue (#0D52CD) Highlight
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1.5,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isSelected ? 21 : 19,
                color: isSelected
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF94A3B8),
              ),
              if (isSelected) ...[
                const SizedBox(height: 2),
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
    );
  }
}
