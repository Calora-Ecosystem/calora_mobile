import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'default_channel',
    'Default notifications',
    description: 'General notifications',
    importance: Importance.high,
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

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => log('Opened from notification: ${message.data}'),
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      sound: true,
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

  Future<void> showNotificationFromRemote(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) return;

    int? badgeCount;
    final badge = message.data['badge'] ?? message.data['badge_count'];
    if (badge != null) {
      try {
        badgeCount = int.parse(badge.toString());
        if (badgeCount > 9) {
          badgeCount = 9;
        }
      } catch (e) {
        log('Could not parse badge count: $e');
      }
    }

    await _local.show(
      message.hashCode,
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
        iOS: DarwinNotificationDetails(badgeNumber: badgeCount),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
