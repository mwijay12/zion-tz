import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/services/app_language_service.dart';
import 'core/services/church_audio_service.dart';
import 'core/services/church_auth_service.dart';
import 'core/services/church_notification_service.dart';
import 'core/services/church_sync_service.dart';
import 'core/services/database_service.dart';
import 'core/theme/church_theme_service.dart';
import 'features/auth/presentation/onboarding_auth_screen.dart';
import 'features/navigation/presentation/main_scaffold.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    databaseFactory = databaseFactoryFfi;
  }

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

  // Initialize Local SQLite Database
  try {
    await DatabaseService().database;
  } catch (e) {
    debugPrint('Database init error: $e');
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

  // Media audio: one AudioService-backed handler owns the only audio player.
  // Android 13+ needs the notification permission before the media
  // notification (and therefore the lock-screen controls) can be shown.
  try {
    await ChurchAudioService.requestNotificationPermission();
    await ChurchAudioService.init();
    await ChurchAudioService().bind();
  } catch (e) {
    debugPrint('Audio service init error: $e');
  }

  // NOTE: playback is intentionally never stopped from app lifecycle events
  // (paused/inactive) - background audio must survive home button, screen
  // lock and app switching. See ZionAudioHandler / ChurchAudioService.

  // Initialize Real-time Web Portal Announcement Synchronization Bridge
  try {
    await ChurchSyncService().init();
  } catch (e) {
    debugPrint('Church sync service init error: $e');
  }

  runApp(const SayuniApp());
}

class SayuniApp extends StatelessWidget {
  const SayuniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnboarded = ChurchAuthService().isOnboarded;
    final themeService = ChurchThemeService();
    final languageService = AppLanguageService();

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, languageService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Sayuni Jerusalem Church',
          debugShowCheckedModeBanner: false,
          theme: themeService.lightTheme.copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: themeService.darkTheme.copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: themeService.themeMode,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          home:
              isOnboarded ? const MainScaffold() : const OnboardingAuthScreen(),
        );
      },
    );
  }
}
