import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Single-theme controller for the whole app.
///
/// There is exactly ONE brand theme — Electric Blue #0D52CD with gold accents.
/// The only user choice left is Light mode or Dark mode, so nothing gets mixed up.
class ChurchThemeService extends ChangeNotifier {
  static final ChurchThemeService _instance = ChurchThemeService._internal();
  factory ChurchThemeService() => _instance;
  ChurchThemeService._internal();

  static const String _keyThemeMode = 'setting_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_keyThemeMode);
      // Legacy values ("system", old palette names) collapse into light.
      _themeMode = modeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Theme service init error: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> toggleDarkMode() =>
      setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  // ---- The one and only brand palette ----
  Color get primaryColor => AppColors.primary; // Electric Blue #0D52CD
  Color get primaryLightColor => AppColors.primaryLight; // Sky light blue (dark mode accent)
  Color get primaryDarkColor => AppColors.primaryDark; // Deep sanctuary navy
  String get themeName => 'Buluu ya Sayuni';

  // ---------------------------------------------------------------- LIGHT
  ThemeData get lightTheme {
    const primary = AppColors.primary;

    final colorScheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryFixed,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.goldContainer,
      onSecondaryContainer: AppColors.onGoldContainer,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      canvasColor: AppColors.canvasLight,
      scaffoldBackgroundColor: AppColors.canvasLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight, size: 22),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimaryLight),
        displayMedium: TextStyle(color: AppColors.textPrimaryLight),
        displaySmall: TextStyle(color: AppColors.textPrimaryLight),
        headlineLarge: TextStyle(color: AppColors.textPrimaryLight),
        headlineMedium: TextStyle(color: AppColors.textPrimaryLight),
        headlineSmall: TextStyle(color: AppColors.textPrimaryLight),
        titleLarge: TextStyle(color: AppColors.textPrimaryLight),
        titleMedium: TextStyle(color: AppColors.textPrimaryLight),
        titleSmall: TextStyle(color: AppColors.textPrimaryLight),
        bodyLarge: TextStyle(color: AppColors.textSecondaryLight, height: 1.55),
        bodyMedium: TextStyle(color: AppColors.textSecondaryLight, height: 1.5),
        bodySmall: TextStyle(color: AppColors.textMutedLight, height: 1.45),
        labelLarge: TextStyle(color: AppColors.textPrimaryLight),
        labelMedium: TextStyle(color: AppColors.textSecondaryLight),
        labelSmall: TextStyle(color: AppColors.textMutedLight),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimaryLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight, size: 22),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      dividerColor: AppColors.borderLight,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge(color: primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTypography.labelLarge(color: primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium(color: AppColors.textMutedLight),
        labelStyle: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        counterStyle: AppTypography.bodySmall(color: AppColors.textMutedLight),
        floatingLabelStyle: AppTypography.labelLarge(color: primary),
        prefixIconColor: AppColors.textMutedLight,
        suffixIconColor: AppColors.textMutedLight,
        iconColor: AppColors.textMutedLight,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: primary,
        labelStyle: AppTypography.labelLarge(color: AppColors.textPrimaryLight),
        secondaryLabelStyle: AppTypography.labelLarge(color: Colors.white),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMutedLight,
        indicatorColor: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: AppTypography.bodyMedium(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.primary),
        trackColor: WidgetStatePropertyAll(Color(0xFFBFD3F5)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: AppTypography.bodySmall(color: Colors.white),
      ),
    );
  }

  // ----------------------------------------------------------------- DARK
  ThemeData get darkTheme {
    const primary = AppColors.primaryLight; // Sky blue reads cleanly on midnight canvas
    const canvas = AppColors.canvasDark;
    const surface = AppColors.surfaceDark;
    const border = AppColors.borderDark;

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Color(0xFF04121F),
      primaryContainer: Color(0xFF16305A),
      onPrimaryContainer: Colors.white,
      secondary: AppColors.goldLight,
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF2D2311),
      onSecondaryContainer: AppColors.goldLight,
      surface: surface,
      onSurface: Colors.white,
      error: Color(0xFFF87171),
      onError: Colors.black,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      canvasColor: canvas,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white, size: 22),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: AppColors.textSecondaryDark, height: 1.55),
        bodyMedium: TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
        bodySmall: TextStyle(color: AppColors.textMutedDark, height: 1.45),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: AppColors.textSecondaryDark),
        labelSmall: TextStyle(color: AppColors.textMutedDark),
      ),
      cardTheme: CardTheme(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primaryLight,
        textColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 22),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      dividerColor: border,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF04121F),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF04121F)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
        counterStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
        floatingLabelStyle: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
        prefixIconColor: AppColors.textMutedDark,
        suffixIconColor: AppColors.textMutedDark,
        iconColor: AppColors.textMutedDark,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFF87171)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFF87171), width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(
            color: Color(0xFF04121F), fontSize: 12, fontWeight: FontWeight.bold),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMutedDark,
        indicatorColor: AppColors.primaryLight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryLight),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.primaryLight),
        trackColor: WidgetStatePropertyAll(Color(0xFF24344C)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerDark,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
