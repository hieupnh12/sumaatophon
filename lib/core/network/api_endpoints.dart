/// URL REST API backend — không chứa thông tin MySQL.
class ApiEndpoints {
  // Android Emulator: 10.0.2.2 trỏ về localhost máy dev.
  // iOS Simulator: http://localhost:3000
  // Máy thật: http://<IP-LAN-máy-dev>:3000
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const String products = '/products';
  static const String health = '/health';

  static String productById(String id) => '/products/$id';
}
