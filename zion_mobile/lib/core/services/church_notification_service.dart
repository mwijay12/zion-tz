import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  debugPrint('Background notification action clicked: ${details.actionId}');
  if (details.actionId == 'action_play_pause') {
    ChurchNotificationService.onPlayPauseAction?.call();
  } else if (details.actionId == 'action_stop') {
    ChurchNotificationService.onStopAction?.call();
  } else if (details.actionId == 'action_next') {
    ChurchNotificationService.onNextAction?.call();
  } else if (details.actionId == 'action_prev') {
    ChurchNotificationService.onPrevAction?.call();
  }
}

class ChurchNotificationService {
  static final ChurchNotificationService _instance = ChurchNotificationService._internal();
  factory ChurchNotificationService() => _instance;

  ChurchNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'zion_church_lock_screen_alerts';
  static const String channelName = 'Sayuni Arifa za Juu & Lock Screen';
  static const String channelDescription = 'Arifa za ibada, maombi, na matangazo ya Zion Jerusalem Church';

  static const String mediaChannelId = 'zion_church_media_playback';
  static const String mediaChannelName = 'Sayuni Media & Audio Controls';
  static const String mediaChannelDescription = 'Udhibiti wa sauti na redio ya Sayuni kwenye lock screen';
  static const int mediaNotificationId = 8888;

  static VoidCallback? onPlayPauseAction;
  static VoidCallback? onStopAction;
  static VoidCallback? onNextAction;
  static VoidCallback? onPrevAction;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}, actionId: ${details.actionId}');
          if (details.actionId == 'action_play_pause') {
            onPlayPauseAction?.call();
          } else if (details.actionId == 'action_stop') {
            onStopAction?.call();
          } else if (details.actionId == 'action_next') {
            onNextAction?.call();
          } else if (details.actionId == 'action_prev') {
            onPrevAction?.call();
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Create Channels for Android
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // 1. High priority worship reminder channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            showBadge: true,
            enableVibration: true,
            playSound: true,
          ),
        );

        // 2. High-visibility ongoing media playback channel for lock screen controls
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            mediaChannelId,
            mediaChannelName,
            description: mediaChannelDescription,
            importance: Importance.high,
            showBadge: false,
            enableVibration: false,
            playSound: false,
          ),
        );

        // Request POST_NOTIFICATIONS runtime permission on Android 13+
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('ChurchNotificationService initialized successfully.');

      // Check and trigger Saturday or Sunday service reminder asynchronously (do not block app startup)
      Future.delayed(const Duration(seconds: 3), () {
        checkAndTriggerSaturdayServiceReminder();
      });
    } catch (e) {
      debugPrint('Failed to initialize ChurchNotificationService: $e');
    }
  }

  Future<void> showLockScreenNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public, // VISIBLE ON LOCK SCREEN
        icon: '@drawable/ic_notification',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error displaying notification: $e');
    }
  }

  Future<void> checkAndTriggerSaturdayServiceReminder() async {
    final now = DateTime.now();
    // In Dart DateTime: Monday=1, ..., Saturday=6, Sunday=7
    if (now.weekday == DateTime.saturday) {
      // It is Saturday! Remind member about tomorrow's Sunday Main Service
      await showLockScreenNotification(
        id: 777,
        title: '🔔 Kesho ni Ibada Kuu ya Sayuni!',
        body: 'Usisahau kufika Hekaluni Mbagala Kwa Matope saa 02:30 Asubuhi. Askofu Messi Mgala na jopo la wachungaji wameandaa neno la uponyaji na ukombozi kwa ajili yako!',
        payload: 'saturday_service_reminder',
      );
    } else if (now.weekday == DateTime.sunday) {
      // It is Sunday!
      await showLockScreenNotification(
        id: 778,
        title: '☀️ Karibu Nyumbani mwa Bwana Leo!',
        body: 'Ibada Kuu ya Hekalu la Sayuni inaanza. Lete familia na marafiki kwa ajili ya sifa, maombi na neno lenye uzima.',
        payload: 'sunday_service_reminder',
      );
    }
  }

  /// Displays lock screen & notification bar media playback controls
  Future<void> showMediaNotification({
    required String title,
    required String subtitle,
    required bool isPlaying,
    bool hasPrevious = true,
    bool hasNext = true,
  }) async {
    try {
      final actions = <AndroidNotificationAction>[];

      if (hasPrevious) {
        actions.add(const AndroidNotificationAction(
          'action_prev',
          '⏮ Nyuma',
          showsUserInterface: false,
        ));
      }

      actions.add(AndroidNotificationAction(
        'action_play_pause',
        isPlaying ? '⏸ Sitisha' : '▶ Cheza',
        showsUserInterface: false,
      ));

      if (hasNext) {
        actions.add(const AndroidNotificationAction(
          'action_next',
          'Mbele ⏭',
          showsUserInterface: false,
        ));
      }

      actions.add(const AndroidNotificationAction(
        'action_stop',
        '⏹ Funga',
        showsUserInterface: false,
      ));

      final androidDetails = AndroidNotificationDetails(
        mediaChannelId,
        mediaChannelName,
        channelDescription: mediaChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public, // VISIBLE ON LOCK SCREEN
        ongoing: isPlaying,
        autoCancel: false,
        icon: '@drawable/ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF0D52CD),
        showWhen: false,
        styleInformation: const MediaStyleInformation(),
        actions: actions,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        mediaNotificationId,
        title,
        '${isPlaying ? "Inacheza sasa" : "Imesimamishwa"} • $subtitle',
        notificationDetails,
        payload: 'media_player',
      );
    } catch (e) {
      debugPrint('Error displaying media notification: $e');
    }
  }

  Future<void> hideMediaNotification() async {
    try {
      await _notificationsPlugin.cancel(mediaNotificationId);
    } catch (_) {}
  }
}
