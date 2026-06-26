import 'api_config.dart';

/// URL REST API backend — không chứa thông tin MySQL.
class ApiEndpoints {
  static String get baseUrl => ApiConfig.baseUrl;
  static const String products = '/products';
  static const String googleLogin = '/auth/google';
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
  static String productFeedbacks(String id) => '/products/$id/feedbacks';
}
