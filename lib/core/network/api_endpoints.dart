import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// URL REST API backend — không chứa thông tin MySQL.
class ApiEndpoints {
  // Android Emulator: 10.0.2.2 = localhost của máy host (Windows/Mac chạy backend)
  // iOS Simulator / Windows desktop: localhost hoặc 127.0.0.1
  // Máy thật + cùng WiFi: http://<IP-LAN-PC>:3000
  // Máy thật + USB: adb reverse tcp:3000 tcp:3000 rồi dùng 127.0.0.1

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  static const String products = '/products';
  static const String health = '/health';
  static const String googleLogin = '/auth/google';

  static String productById(String id) => '/products/$id';
  static String productFeedbacks(String id) => '/products/$id/feedbacks';
}
