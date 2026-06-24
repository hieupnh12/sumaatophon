import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// URL REST API backend — không chứa thông tin MySQL.
class ApiEndpoints {
  // Tự động nhận diện thiết bị để dùng đúng IP Localhost
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000'; // Máy ảo Android
    return 'http://127.0.0.1:3000'; // iOS Simulator hoặc Desktop
  }

  static const String products = '/products';
  static const String googleLogin = '/auth/google'; // Có thể bỏ
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String authSync = '/auth/sync';
  static const String linkPhone = '/auth/link-phone';
  static const String profile = '/profile';
  static const String health = '/health';

  static String productById(String id) => '/products/$id';
}
