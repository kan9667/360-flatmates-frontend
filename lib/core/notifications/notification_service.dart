import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../providers.dart';

class NotificationService {
  const NotificationService(this._ref);

  final Ref _ref;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Deep link navigation handled by the router
    // The payload contains the route to navigate to
  }

  Future<void> initialize() async {
    // Request permissions
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'flatmates_messages',
          'Messages & Matches',
          description:
              'Notifications for new messages, matches, and visits',
          importance: Importance.high,
        ),
      );
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check initial message (app opened from notification)
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Token management
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToServer);
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _sendTokenToServer(token);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flatmates_messages',
          'Messages & Matches',
          channelDescription:
              'Notifications for new messages, matches, and visits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      // Navigate using the app's router
      // The router is accessible via the global navigator key
      debugPrint('Notification tap route: $route');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _ref.read(apiClientProvider).put(
            '/users/me',
            data: {'fcm_token': token},
          );
    } catch (_) {
      // Token sync is best-effort; do not block UX.
    }
  }

  Future<void> clearToken() async {
    try {
      await _ref.read(apiClientProvider).put(
            '/users/me',
            data: {'fcm_token': null},
          );
    } catch (_) {
      // Best-effort
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref),
);
