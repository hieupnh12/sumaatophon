import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// URL REST API backend — không chứa thông tin MySQL.
class ApiEndpoints {
  /// Production VPS: https://maclenin.io.vn/mobile (Nginx → flutter-api :3001)
  /// Override khi dev: --dart-define=API_BASE_URL=http://192.168.x.x:3000
  static const String _prodBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://maclenin.io.vn/mobile',
  );

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty && !kReleaseMode) {
      return override;
    }
    if (kReleaseMode) {
      return _prodBaseUrl;
    }

    // Debug local: emulator / simulator / máy thật cùng WiFi với PC chạy backend
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://127.0.0.1:3000';
  }

  static const String products = '/products';
  static const String googleLogin = '/auth/google'; // Có thể bỏ
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String authSync = '/auth/sync';
  static const String linkPhone = '/auth/link-phone';
  static const String profile = '/profile';
  static const String health = '/health';

  static const String chatThreads = '/chat/threads';
  static const String chatThreadsMine = '/chat/threads/mine';
  static const String chatbotAsk = '/chatbot/ask';
  static const String chatbotSuggestions = '/chatbot/suggestions';

  static String chatThreadMessages(String threadId) =>
      '/chat/threads/$threadId/messages';

  static String productById(String id) => '/products/$id';
}
