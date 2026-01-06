import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// removed unused flutter import
import 'analytics_service.dart';

//для показа уведомлений внутри приложения
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//Background message handler обязательно top-level
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
    await AnalyticsService.instance.logEvent('fcm_background_message', parameters: {
      'message_id': message.messageId ?? '',
      'has_notification': message.notification != null,
    });
  } catch (_) {}
}

class MessagingService {
  MessagingService._internal();
  static final MessagingService instance = MessagingService._internal();

  //основной API для получения токена, слушания смс и запрашивания разрешения
  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel); //создаём канал

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher'); //иконка уведомлений
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

      //подготовка плагина к показу уведомлений
      await _flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      //запрос разрешения у пользователя, получаем FCM токен
      await requestPermissionAndGetToken();

      //срабатывает, если приложение было полностью закрыто
      final initialMessage = await _fm.getInitialMessage();
      if (initialMessage != null) {
        _showLocalNotification(initialMessage);
        AnalyticsService.instance.logEvent('fcm_initial_message', parameters: {
          'message_id': initialMessage.messageId ?? '',
        });
      }

      // Foreground handler. Приложение открыто
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
        AnalyticsService.instance.logEvent('fcm_foreground_message', parameters: {
          'message_id': message.messageId ?? '',
          'has_notification': message.notification != null,
        });
      });

      //нажатие на уведомление и переход в приложение
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AnalyticsService.instance.logEvent('fcm_opened_from_notification', parameters: {
          'message_id': message.messageId ?? '',
        });
      });
    } catch (e) {
      // ignore
    }
  }

  //запрашивает разрешение
  Future<String?> requestPermissionAndGetToken() async {
    try {
      NotificationSettings settings = await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _fm.getToken(); //уникальный токен устройства
        if (token != null) {
          await AnalyticsService.instance.logEvent('fcm_token_obtained');
        }
        return token;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  //показ локального уведомления
  void _showLocalNotification(RemoteMessage message) {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final android = notification.android;
      final title = notification.title ?? '';
      final body = notification.body ?? '';

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      //показывает уведомление пользователю
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        platformDetails,
        payload: message.messageId,
      );
    } catch (e) {
      // ignore
    }
  }
}
