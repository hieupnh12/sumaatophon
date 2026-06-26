import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// URL REST API backend — không chứa thông tin MySQL.
class ApiEndpoints {

  static String get baseUrl {
    return 'https://maclenin.io.vn/mobile';
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
