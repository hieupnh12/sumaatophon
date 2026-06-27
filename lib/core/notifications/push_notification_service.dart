import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../firebase_options.dart';

/// Xử lý push khi app ở background/terminated — FCM tự hiện banner nếu có notification payload.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static void Function()? onForegroundRefresh;

  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (_) => onForegroundRefresh?.call(),
    );
    _initialized = true;

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'phoneshop_notifications',
        'PhoneShop',
        description: 'Thông báo đơn hàng, sản phẩm mới và hỗ trợ',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => onForegroundRefresh?.call());

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onForegroundRefresh?.call();
    }

    _messaging.onTokenRefresh.listen((token) async {
      // Token refresh handled on next login/register call
      debugPrint('[FCM] token refreshed');
    });
  }

  static Future<void> showLocal({
    required String title,
    String? body,
    int id = 0,
  }) async {
    if (kIsWeb || !_initialized) {
      debugPrint('[FCM] showLocal skipped (init=$_initialized)');
      return;
    }
    final notifId = id == 0 ? title.hashCode : id;
    await _local.show(
      notifId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'phoneshop_notifications',
          'PhoneShop',
          channelDescription: 'Thông báo đơn hàng, sản phẩm mới và hỗ trợ',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
    debugPrint('[FCM] showLocal: $title');
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null || title.isEmpty) return;

    final dataId = message.data['notificationId'];
    await showLocal(
      title: title,
      body: body,
      id: dataId != null ? dataId.hashCode : message.hashCode,
    );
    onForegroundRefresh?.call();
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return _messaging.getToken();
  }

  static Future<void> registerWithBackend(ApiClient client, int customerId) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;

    await client.post(
      ApiEndpoints.notificationsRegisterToken,
      body: {
        'customerId': customerId,
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      },
    );
  }

  static Future<void> unregisterWithBackend(ApiClient client, {int? customerId}) async {
    final token = await getToken();
    await client.post(
      ApiEndpoints.notificationsUnregisterToken,
      body: {
        if (customerId != null) 'customerId': customerId,
        if (token != null) 'token': token,
      },
    );
  }
}
