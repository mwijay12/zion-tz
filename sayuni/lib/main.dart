import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
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
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));

  // Core local fast initialization with strict timeout guards
  try {
    await Future.wait([
      AppLanguageService()
          .init()
          .timeout(const Duration(milliseconds: 1500), onTimeout: () {}),
      ChurchThemeService()
          .init()
          .timeout(const Duration(milliseconds: 1500), onTimeout: () {}),
      ChurchAuthService()
          .init()
          .timeout(const Duration(milliseconds: 1500), onTimeout: () {}),
      DatabaseService()
          .database
          .timeout(const Duration(milliseconds: 1500)),
    ]);
  } catch (e) {
    debugPrint('Fast init warning: $e');
  }

  // Launch the Flutter app immediately: splash screen clears in milliseconds
  runApp(const SayuniApp());

  // Initialize background services (Firebase, Audio, Notifications, Sync) asynchronously
  _initBackgroundServices();
}

void _initBackgroundServices() {
  Future.microtask(() async {
    // 1. Initialize Firebase Cloud Connection
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Firebase background init error: $e');
    }

    // 2. Initialize Lock Screen Notification Service & High Priority Channels
    try {
      await ChurchNotificationService().init();
    } catch (e) {
      debugPrint('Notification background init error: $e');
    }

    // 3. Media Audio Service & Lock Screen Controls
    try {
      await ChurchAudioService.init().timeout(const Duration(seconds: 4));
      await ChurchAudioService().bind();
    } catch (e) {
      debugPrint('Audio service background init error: $e');
    }

    // 4. Real-time Announcement Synchronization Bridge
    try {
      await ChurchSyncService().init();
    } catch (e) {
      debugPrint('Church sync background init error: $e');
    }
  });
}

class SayuniApp extends StatelessWidget {
  const SayuniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnboarded = ChurchAuthService().isOnboarded;
    final themeService = ChurchThemeService();
    // Only the theme affects MaterialApp. Language is handled by the
    // screens themselves, so merging it here just caused extra rebuilds.
    return ListenableBuilder(
      listenable: themeService,
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
