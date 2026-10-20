import 'package:flutter/material.dart';
import 'church_theme_service.dart';

/// Design tokens extracted directly from Google Stitch and Zion Design System.
/// Enforces warm, dignified sanctuary colors and pure midnight slate dark mode
/// with guaranteed contrast ratios (>= 4.5:1), completely free of forced violet tint.
abstract class AppColors {
  // Primary Electric Blue & White System (Sanctuary Dignity, Heaven, Peace)
  static const Color primary = Color(0xFF0D52CD); // Electric Blue (#0D52CD)
  static const Color primaryLight = Color(0xFF38BDF8); // Sky Light Blue
  static const Color primaryDark = Color(0xFF0A2540); // Deep Sanctuary Navy Blue
  static const Color primaryFixed = Color(0xFFE0F2FE); // Soft Sky Tint
  static const Color onPrimaryFixed = Color(0xFF032B56); // Deep Navy Ink
  static const Color primaryContainer = Color(0xFFEFF6FF); // Crisp Ice Blue Container
  static Color primaryOf(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color dynamicPrimary(BuildContext context) => Theme.of(context).colorScheme.primary;

  // Sacred Ochre Gold (Divinity, Giving, Honor)
  static const Color gold = Color(0xFFC59B27);
  static const Color goldLight = Color(0xFFE4BC4A);
  static const Color goldDark = Color(0xFF8B6B12);
  static const Color goldContainer = Color(0xFFFFF7E6);
  static const Color onGoldContainer = Color(0xFF5A4305);

  // Backgrounds & Surfaces (Light Constants)
  static const Color canvasLight = Color(0xFFF8FAFC); // Crisp pure canvas
  static const Color surfaceLight = Color(0xFFFFFFFF); // Clean white cards
  static const Color surfaceLowLight = Color(0xFFF1F5F9); // Light slate linen
  static const Color surfaceContainerLight = Color(0xFFF0F7FF); // Soft celestial blue tint
  static const Color borderLight = Color(0xFFD8E6F8); // Subtle crisp hairline borders

  // Backgrounds & Surfaces (Dark Constants - Pure Midnight Slate, Zero Forced Violet Tint)
  static const Color canvasDark = Color(0xFF0B0F19); // Pure midnight charcoal slate
  static const Color surfaceDark = Color(0xFF161F30); // Clean dark card container
  static const Color surfaceLowDark = Color(0xFF111827); // Deep slate low surface
  static const Color surfaceContainerDark = Color(0xFF1C273C); // Slate elevated container
  static const Color borderDark = Color(0xFF26354A); // Clean dark slate border

  // High Contrast Inks & Typography (WCAG AAA compliant)
  static const Color textPrimaryLight = Color(0xFF0A1E3F); // Deepest royal navy ink
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Pure white

  static const Color textSecondaryLight = Color(0xFF334155); // Slate charcoal
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // Light slate

  static const Color textMutedLight = Color(0xFF64748B); // Cool grey label text
  static const Color textMutedDark = Color(0xFF94A3B8); // Muted slate

  static const Color textWhite = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706);

  // M-Pesa & Tigo Brand Colors for Tanzania Giving
  static const Color mpesaGreen = Color(0xFF009639);
  static const Color tigoBlue = Color(0xFF00377B);
  static const Color airtelRed = Color(0xFFE60000);
  static const Color crdbGreen = Color(0xFF006837);

  // Dynamic aliases resolving directly to theme state
  static Color get canvas => ChurchThemeService().isDarkMode ? canvasDark : canvasLight;
  static Color get surface => ChurchThemeService().isDarkMode ? surfaceDark : surfaceLight;
  static Color get surfaceLow => ChurchThemeService().isDarkMode ? surfaceLowDark : surfaceLowLight;
  static Color get surfaceContainer => ChurchThemeService().isDarkMode ? surfaceContainerDark : surfaceContainerLight;
  static Color get border => ChurchThemeService().isDarkMode ? borderDark : borderLight;

  static Color get textPrimary => ChurchThemeService().isDarkMode ? textPrimaryDark : textPrimaryLight;
  static Color get textSecondary => ChurchThemeService().isDarkMode ? textSecondaryDark : textSecondaryLight;
  static Color get textMuted => ChurchThemeService().isDarkMode ? textMutedDark : textMutedLight;

  // Dynamic Theme-Aware Helpers
  static bool get isDark => ChurchThemeService().isDarkMode;

  // Context-based helpers
  static bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color canvasOf(BuildContext context) => isDarkMode(context) ? canvasDark : canvasLight;
  static Color surfaceOf(BuildContext context) => isDarkMode(context) ? surfaceDark : surfaceLight;
  static Color surfaceLowOf(BuildContext context) => isDarkMode(context) ? surfaceLowDark : surfaceLowLight;
  static Color surfaceContainerOf(BuildContext context) => isDarkMode(context) ? surfaceContainerDark : surfaceContainerLight;
  static Color borderOf(BuildContext context) => isDarkMode(context) ? borderDark : borderLight;
  static Color textPrimaryOf(BuildContext context) => isDarkMode(context) ? textPrimaryDark : textPrimaryLight;
  static Color textSecondaryOf(BuildContext context) => isDarkMode(context) ? textSecondaryDark : textSecondaryLight;
  static Color textMutedOf(BuildContext context) => isDarkMode(context) ? textMutedDark : textMutedLight;
}
