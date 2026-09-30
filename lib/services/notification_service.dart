import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

typedef NotificationNavigationCallback = void Function(String type, int? referenceId);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Dio _dio = ApiClient().dio;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationNavigationCallback? _onNotificationNavigation;
  bool _isInitialized = false;
  bool _hasFirebase = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important apartment announcements & requests.',
    importance: Importance.high,
  );

  Future<void> initialize({NotificationNavigationCallback? onNotificationTap}) async {
    if (_isInitialized) return;
    _onNotificationNavigation = onNotificationTap;

    // 1. Initialize Local Notifications
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!);
              final type = data['type']?.toString() ?? 'ANNOUNCEMENT';
              final rawRef = data['referenceId'];
              final refId = rawRef is int ? rawRef : int.tryParse(rawRef?.toString() ?? '');
              _onNotificationNavigation?.call(type, refId);
            } catch (_) {}
          }
        },
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }
    } catch (e) {
      debugPrint('Local notifications init note: ');
    }

    // 2. Initialize Firebase Core & Messaging safely
    try {
      await Firebase.initializeApp();
      _hasFirebase = true;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final fcm = FirebaseMessaging.instance;

      // Request permission
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM AuthorizationStatus: ');

      // Handle terminated click
      final initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      // Handle background click (app resumed)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageTap(message);
      });

      // Handle foreground push
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // Get initial token and register
      final token = await fcm.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Token received: ...');
        await StorageService.saveFcmToken(token);
        if (StorageService.hasToken()) {
          await registerDeviceWithBackend(token);
        }
      }

      // Listen for token refresh
      fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed');
        await StorageService.saveFcmToken(newToken);
        if (StorageService.hasToken()) {
          await registerDeviceWithBackend(newToken);
        }
      });
    } catch (e) {
      debugPrint('Firebase Messaging setup note:  (App will function normally, push notifications active once google-services.json configured)');
      _hasFirebase = false;
    }

    _isInitialized = true;
  }

  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? 'ANNOUNCEMENT';
    final rawRef = message.data['referenceId'];
    final refId = rawRef is int ? rawRef : int.tryParse(rawRef?.toString() ?? '');
    _onNotificationNavigation?.call(type, refId);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Thông báo cư dân';
    final body = notification?.body ?? message.data['body'] ?? '';

    final type = message.data['type']?.toString() ?? 'ANNOUNCEMENT';
    final rawRef = message.data['referenceId'];
    final refId = rawRef is int ? rawRef : int.tryParse(rawRef?.toString() ?? '');

    final payload = jsonEncode({
      'type': type,
      'referenceId': refId,
    });

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // --- API Methods ---

  Future<void> syncDeviceToken() async {
    final token = StorageService.getFcmToken();
    if (token != null && token.isNotEmpty) {
      await registerDeviceWithBackend(token);
    } else if (_hasFirebase) {
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await StorageService.saveFcmToken(fcmToken);
          await registerDeviceWithBackend(fcmToken);
        }
      } catch (_) {}
    }
  }

  Future<bool> registerDeviceWithBackend(String token) async {
    try {
      final platform = kIsWeb ? 'WEB' : (Platform.isIOS ? 'IOS' : 'ANDROID');
      final deviceName = kIsWeb ? 'Web Browser' : (Platform.isAndroid ? 'Android Device' : 'iOS Device');

      final response = await _dio.post(
        '/devices/register',
        data: {
          'fcmToken': token,
          'platform': platform,
          'deviceName': deviceName,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Failed to register device token: ');
      return false;
    }
  }

  Future<bool> deactivateCurrentToken() async {
    final token = StorageService.getFcmToken();
    if (token == null || token.isEmpty) return false;
    try {
      final response = await _dio.post(
        '/devices/deactivate-token',
        data: {'fcmToken': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to deactivate device token: ');
      return false;
    }
  }

  Future<bool> deactivateDevice(int id) async {
    try {
      final response = await _dio.delete('/devices/');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<List<NotificationModel>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final res = await getMyNotifications(page: page, pageSize: pageSize);
      return res.items;
    } catch (_) {
      // Fallback
      return [];
    }
  }

  Future<NotificationPageResponse> getMyNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        '/notifications/my',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return NotificationPageResponse.fromJson(response.data);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final response = await _dio.put('/notifications//read');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}