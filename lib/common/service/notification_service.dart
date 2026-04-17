import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important messages.',
    importance: Importance.max,
  );

  Future<void> initForForeground() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) =>
          log('Notification tapped: ${response.payload}'),
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance.requestPermission();

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Foreground message received: ${message.messageId}');

      if (Platform.isAndroid) {
        showForegroundNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => log('Opened from notification: ${message.data}'),
    );
  }

  Future<void> initForBackground() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _local.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      await _local.show(
        3107,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    }
  }

  Future<void> showBackgroundDataNotification(RemoteMessage message) async {
    final title = message.data['title']?.toString();
    final body = message.data['body']?.toString();

    if (title == null && body == null) return;

    int? badgeCount;
    final badge = message.data['badge'] ?? message.data['badge_count'];
    if (badge != null) {
      try {
        badgeCount = int.parse(badge.toString());
        if (badgeCount > 9) badgeCount = 9;
      } catch (e) {
        log('Could not parse badge count: $e');
      }
    }

    await _local.show(
      3107,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          number: badgeCount,
        ),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
