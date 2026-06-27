import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Chọn base URL API theo môi trường chạy app.
///
/// | Môi trường | URL |
/// |------------|-----|
/// | Release (mọi nền tảng) | https://maclenin.io.vn/mobile (VPS 35.221.155.202) |
/// | Web debug (`flutter run -d chrome`) | localhost:3000 |
/// | Web release | VPS production |
/// | Emulator + USB debug | 10.0.2.2:3000 (Android) / 127.0.0.1:3000 (iOS) |
/// | Máy thật + USB debug | 127.0.0.1:3000 (cần `adb reverse`) hoặc LOCAL_API_HOST |
/// | Máy thật mở app bình thường | VPS production |
class ApiConfig {
  static const _channel = MethodChannel('com.example.sumaatophon/debug');

  static const String productionBaseUrl = 'https://maclenin.io.vn/mobile';

  static String _baseUrl = productionBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> init() async {
    if (kReleaseMode) {
      _baseUrl = productionBaseUrl;
      _log('release → production');
      return;
    }

    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      _baseUrl = override;
      _log('API_BASE_URL override');
      return;
    }

    // FORCE LOCAL FOR TESTING
    const forceLocal = true; // bool.fromEnvironment('USE_LOCAL_API');
    if (forceLocal) {
      _baseUrl = await _resolveLocalBaseUrl();
      _log('USE_LOCAL_API');
      return;
    }

    // Web debug: flutter run -d chrome → backend local trên PC
    if (kIsWeb) {
      _baseUrl = 'http://localhost:3000';
      _log('web debug → localhost');
      return;
    }

    // Emulator/simulator: luôn dùng host local (10.0.2.2 / 127.0.0.1).
    if (await _isEmulatorOrSimulator()) {
      _baseUrl = await _resolveLocalBaseUrl();
      _log('emulator/simulator → local ($_baseUrl)');
      return;
    }

    // Máy thật: probe backend local — ổn định hơn Debug.isDebuggerConnected() (hay false trên MIUI…).
    // USB + `adb reverse tcp:3000 tcp:3000` + `npm start` → /health OK → dùng local.
    // Mở app từ launcher (không reverse) → probe fail → VPS production.
    final localUrl = await _resolveLocalBaseUrl();
    if (localUrl == productionBaseUrl) {
      _baseUrl = productionBaseUrl;
      _log('no local host → production');
      return;
    }

    if (await _isLocalBackendReachable(localUrl)) {
      _baseUrl = localUrl;
      _log('local backend reachable → $localUrl');
      return;
    }

    _baseUrl = productionBaseUrl;
    _log('local unreachable → production (USB dev: adb reverse tcp:3000 tcp:3000 + npm start)');
  }

  static Future<bool> _isEmulatorOrSimulator() async {
    if (Platform.isAndroid) {
      return _invokeBool('isEmulator');
    }
    if (Platform.isIOS) {
      return _invokeBool('isSimulator');
    }
    return false;
  }

  /// Android emulator: 10.0.2.2
  /// Android máy thật + USB: 127.0.0.1 (chạy `adb reverse tcp:3000 tcp:3000`)
  /// iOS simulator: 127.0.0.1
  /// iOS máy thật + USB: LOCAL_API_HOST = IP LAN của Mac
  static Future<String> _resolveLocalBaseUrl() async {
    const lanHost = String.fromEnvironment('LOCAL_API_HOST');
    if (lanHost.isNotEmpty) {
      return 'http://$lanHost:3000';
    }

    if (Platform.isAndroid) {
      final isEmulator = await _invokeBool('isEmulator');
      if (isEmulator) {
        return 'http://10.0.2.2:3000';
      }
      // Máy thật + USB: adb reverse tcp:3000 tcp:3000
      return 'http://127.0.0.1:3000';
    }

    if (Platform.isIOS) {
      final isSimulator = await _invokeBool('isSimulator');
      if (isSimulator) {
        return 'http://127.0.0.1:3000';
      }
      // iPhone thật không gọi được localhost của Mac — dùng VPS hoặc LOCAL_API_HOST
      return productionBaseUrl;
    }

    return 'http://127.0.0.1:3000';
  }

  /// Gọi GET /health với timeout ngắn — phát hiện adb reverse + backend local đang chạy.
  static Future<bool> _isLocalBackendReachable(String baseUrl) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client
          .getUrl(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      final response = await request.close().timeout(const Duration(seconds: 2));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> _invokeBool(String method) async {
    final value = await _channel.invokeMethod<bool>(method);
    return value ?? false;
  }

  static void _log(String reason) {
    if (kDebugMode) {
      debugPrint('API baseUrl = $_baseUrl ($reason)');
    }
  }
}
