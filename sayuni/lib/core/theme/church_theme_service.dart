import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_typography.dart';

enum HeavenlyThemePalette {
  sapphireBlue,
  celestialGold,
  emeraldGrace,
  roseSharon,
}

class ChurchThemeService extends ChangeNotifier {
  static final ChurchThemeService _instance = ChurchThemeService._internal();
  factory ChurchThemeService() => _instance;
  ChurchThemeService._internal();

  static const String _keyThemeMode = 'setting_theme_mode';
  static const String _keyPalette = 'setting_heavenly_palette';

  ThemeMode _themeMode = ThemeMode.light;
  HeavenlyThemePalette _palette = HeavenlyThemePalette.sapphireBlue;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  HeavenlyThemePalette get palette => _palette;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_keyThemeMode);
      if (modeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (modeStr == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }

      final paletteStr = prefs.getString(_keyPalette);
      if (paletteStr != null && paletteStr != 'royalPurple') {
        _palette = HeavenlyThemePalette.values.firstWhere(
          (p) => p.name == paletteStr,
          orElse: () => HeavenlyThemePalette.sapphireBlue,
        );
      } else {
        _palette = HeavenlyThemePalette.sapphireBlue;
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Theme service init error: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyThemeMode,
        mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.system ? 'system' : 'light'),
      );
    } catch (_) {}
  }

  Future<void> setPalette(HeavenlyThemePalette palette) async {
    _palette = palette;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPalette, palette.name);
    } catch (_) {}
  }

  // Palette Primary Colors
  Color get primaryColor {
    switch (_palette) {
      case HeavenlyThemePalette.sapphireBlue:
        return const Color(0xFF0D52CD); // Electric Blue (#0D52CD)
      case HeavenlyThemePalette.celestialGold:
        return const Color(0xFFC59B27); // Celestial Divine Gold
      case HeavenlyThemePalette.emeraldGrace:
        return const Color(0xFF0F5132); // Emerald Grace Green
      case HeavenlyThemePalette.roseSharon:
        return const Color(0xFF9D174D); // Rose of Sharon
    }
  }

  Color get primaryLightColor {
    switch (_palette) {
      case HeavenlyThemePalette.sapphireBlue:
        return const Color(0xFF38BDF8); // Sky Light Blue
      case HeavenlyThemePalette.celestialGold:
        return const Color(0xFFE4BC4A);
      case HeavenlyThemePalette.emeraldGrace:
        return const Color(0xFF198754);
      case HeavenlyThemePalette.roseSharon:
        return const Color(0xFFBE185D);
    }
  }

  Color get primaryDarkColor {
    switch (_palette) {
      case HeavenlyThemePalette.sapphireBlue:
        return const Color(0xFF0A2540); // Deep Sanctuary Navy
      case HeavenlyThemePalette.celestialGold:
        return const Color(0xFF5A4305);
      case HeavenlyThemePalette.emeraldGrace:
        return const Color(0xFF072718);
      case HeavenlyThemePalette.roseSharon:
        return const Color(0xFF4C0519);
    }
  }

  String get paletteName {
    switch (_palette) {
      case HeavenlyThemePalette.sapphireBlue:
        return 'Sayuni Buluu & Nyeupe (Royal Blue & White)';
      case HeavenlyThemePalette.celestialGold:
        return 'Utukufu wa Dhahabu (Celestial Gold)';
      case HeavenlyThemePalette.emeraldGrace:
        return 'Neema & Uzima (Emerald Green)';
      case HeavenlyThemePalette.roseSharon:
        return 'Waridi la Sharon (Rose / Ruby)';
    }
  }

  ThemeData get lightTheme {
    final primary = primaryColor;
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary.withOpacity(0.12),
      onPrimaryContainer: primary,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.goldContainer,
      onSecondaryContainer: AppColors.onGoldContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvasLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.titleMedium(color: AppColors.textPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLarge(color: Colors.white),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: primary,
        labelStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final primary = primaryLightColor;
    const darkCanvas = Color(0xFF0B0F19); // Pure midnight charcoal, completely free of forced violet tint!
    const darkSurface = Color(0xFF161F30); // Clean dark container surface
    const darkBorder = Color(0xFF26354A); // Clean hairline border

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary.withOpacity(0.25),
      onPrimaryContainer: Colors.white,
      secondary: AppColors.goldLight,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF2D2311),
      onSecondaryContainer: AppColors.goldLight,
      surface: darkSurface,
      onSurface: Colors.white,
      error: const Color(0xFFF87171),
      onError: Colors.black,
      outline: darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkCanvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCanvas,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
      dividerTheme: DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: primary,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
