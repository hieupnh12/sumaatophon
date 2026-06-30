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
  static const String cart = '/api/cart';
  static const String cartItems = '/api/cart/items';
  static const String orders = '/api/orders';
  static const String payOsCreate = '/api/payments/payos/create';
  static const String payOsCancel = '/api/payments/payos/cancel';
  static const String payOsConfirm = '/api/payments/payos/confirm';

  static String payOsStatus(String orderId) => '/api/payments/payos/status/$orderId';

  static const String chatThreads = '/chat/threads';
  static const String chatThreadsMine = '/chat/threads/mine';
  static const String chatbotAsk = '/chatbot/ask';
  static const String chatbotSuggestions = '/chatbot/suggestions';

  static String chatThreadMessages(String threadId) =>
      '/chat/threads/$threadId/messages';

  static const String chatUploadImage = '/chat/upload-image';

  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsRegisterToken = '/notifications/register-token';
  static const String notificationsUnregisterToken = '/notifications/unregister-token';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationDelete(String id) => '/notifications/$id';

  static String productById(String id) => '/products/$id';
  static String productFeedbacks(String id) => '/products/$id/feedbacks';

  // Orders
  static String orderById(String id) => '/api/orders/$id';
  static String cartItemByVersionId(String productVersionId) => '/api/cart/items/$productVersionId';

  // Warranty
  static const String warrantiesEligible = '/api/warranties/eligible-items';
  static const String warranties = '/api/warranties';
}
