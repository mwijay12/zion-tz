import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/app_language_service.dart';
import 'core/services/church_auth_service.dart';
import 'core/services/church_notification_service.dart';
import 'core/services/church_sync_service.dart';
import 'core/theme/church_theme_service.dart';
import 'features/auth/presentation/onboarding_auth_screen.dart';
import 'features/navigation/presentation/main_scaffold.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for phones
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase Cloud Connection
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialize error: $e');
  }

  // Initialize Language Service (Default English, Swahili switchable)
  try {
    await AppLanguageService().init();
  } catch (e) {
    debugPrint('Language service init error: $e');
  }

  // Initialize Theme Service & Heavenly Palettes
  try {
    await ChurchThemeService().init();
  } catch (e) {
    debugPrint('Theme service init error: $e');
  }

  // Initialize Church Auth & Member Verification
  try {
    await ChurchAuthService().init();
  } catch (e) {
    debugPrint('Auth service init error: $e');
  }

  // Initialize Lock Screen Notification Service & Reminders
  try {
    await ChurchNotificationService().init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  // Initialize Real-time Web Portal Announcement Synchronization Bridge
  try {
    await ChurchSyncService().init();
  } catch (e) {
    debugPrint('Church sync service init error: $e');
  }

  runApp(const ZionChurchApp());
}

class ZionChurchApp extends StatelessWidget {
  const ZionChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnboarded = ChurchAuthService().isOnboarded;
    final themeService = ChurchThemeService();
    final languageService = AppLanguageService();

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, languageService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Zion Jerusalem Church',
          debugShowCheckedModeBanner: false,
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.themeMode,
          home: isOnboarded ? const MainScaffold() : const OnboardingAuthScreen(),
        );
      },
    );
  }
}
