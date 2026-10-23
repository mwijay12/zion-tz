import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'church_theme_service.dart';

abstract class AppTypography {
  static Color _resolveColor(Color? color,
      {required Color defaultLight, required Color defaultDark}) {
    final isDark = ChurchThemeService().isDarkMode;
    if (color == null) {
      return isDark ? defaultDark : defaultLight;
    }
    if (isDark) {
      if (color == AppColors.textPrimaryLight ||
          color == const Color(0xFF0A1E3F)) {
        return AppColors.textPrimaryDark;
      }
      if (color == AppColors.textSecondaryLight ||
          color == const Color(0xFF334155)) {
        return AppColors.textSecondaryDark;
      }
      if (color == AppColors.textMutedLight ||
          color == const Color(0xFF64748B)) {
        return AppColors.textMutedDark;
      }
    }
    return color;
  }

  // Sacred & Authoritative Optical Serif (Newsreader)
  static TextStyle displayLarge({Color? color}) {
    return GoogleFonts.newsreader(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: _resolveColor(color,
          defaultLight: AppColors.textPrimaryLight,
          defaultDark: AppColors.textPrimaryDark),
      letterSpacing: -0.5,
      height: 1.2,
    );
  }

  static TextStyle headlineMedium({Color? color}) {
    return GoogleFonts.newsreader(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: _resolveColor(color,
          defaultLight: AppColors.textPrimaryLight,
          defaultDark: AppColors.textPrimaryDark),
      height: 1.25,
    );
  }

  static TextStyle scriptureVerse({
    Color? color,
    double fontSize = 16,
    FontStyle fontStyle = FontStyle.italic,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      fontStyle: fontStyle,
      color: _resolveColor(color,
          defaultLight: AppColors.textPrimaryLight,
          defaultDark: AppColors.textPrimaryDark),
      height: 1.5,
    );
  }

  // Modern Humanist Sans-Serif for UI & Body (Plus Jakarta Sans)
  static TextStyle titleMedium({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: _resolveColor(color,
          defaultLight: AppColors.textPrimaryLight,
          defaultDark: AppColors.textPrimaryDark),
      height: 1.3,
    );
  }

  static TextStyle titleSmall({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: _resolveColor(color,
          defaultLight: AppColors.textPrimaryLight,
          defaultDark: AppColors.textPrimaryDark),
      height: 1.3,
    );
  }

  static TextStyle bodyLarge({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: _resolveColor(color,
          defaultLight: AppColors.textSecondaryLight,
          defaultDark: AppColors.textSecondaryDark),
      height: 1.5,
    );
  }

  static TextStyle bodyMedium({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: _resolveColor(color,
          defaultLight: AppColors.textSecondaryLight,
          defaultDark: AppColors.textSecondaryDark),
      height: 1.45,
    );
  }

  static TextStyle bodySmall({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: _resolveColor(color,
          defaultLight: AppColors.textSecondaryLight,
          defaultDark: AppColors.textSecondaryDark),
      height: 1.4,
    );
  }

  static TextStyle labelLarge({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _resolveColor(color,
          defaultLight: AppColors.textPrimaryLight,
          defaultDark: AppColors.textPrimaryDark),
      letterSpacing: 0.2,
    );
  }

  static TextStyle caption({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: _resolveColor(color,
          defaultLight: AppColors.textMutedLight,
          defaultDark: AppColors.textMutedDark),
    );
  }
}
