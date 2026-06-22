/// URL REST API backend — không chứa thông tin MySQL.
class ApiEndpoints {
  // Android Emulator: http://10.0.2.2:3000
  // iOS Simulator: http://localhost:3000
  // Máy thật (cùng WiFi với PC chạy backend): http://<IP-LAN-PC>:3000
  // IP hiện tại PC dev — đổi lại nếu IP WiFi thay đổi hoặc dùng emulator.
  static const String baseUrl = 'http://127.0.0.1:3000';

  static const String products = '/products';
  static const String health = '/health';
  static const String googleLogin = '/auth/google';

  static String productById(String id) => '/products/$id';
}
