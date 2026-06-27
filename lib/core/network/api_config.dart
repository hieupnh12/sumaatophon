import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Chọn base URL API theo môi trường chạy app.
///
/// | Môi trường | URL |
/// |------------|-----|
/// | Release (mọi nền tảng) | https://maclenin.io.vn/mobile (VPS) |
/// | Web debug | localhost:3000 |
/// | Emulator | 10.0.2.2:3000 / 127.0.0.1:3000 |
/// | Máy thật + USB (`adb reverse`) | 127.0.0.1:3000 (chỉ khi debugger gắn) |
/// | Máy thật không USB | production (nếu `/health` trả `{ok:true}`) |
class ApiConfig {
  static const _channel = MethodChannel('com.example.sumaatophon/debug');

  static const String productionBaseUrl = 'https://maclenin.io.vn/mobile';

  static String _baseUrl = productionBaseUrl;

  static String get baseUrl => _baseUrl;

  static ApiSocketConfig get socketConfig {
    final uri = Uri.parse(_baseUrl);
    final origin = _socketOrigin(uri);

    var prefix = uri.path;
    if (prefix.endsWith('/')) {
      prefix = prefix.substring(0, prefix.length - 1);
    }
    final path =
        prefix.isEmpty || prefix == '/' ? '/socket.io' : '$prefix/socket.io';

    return ApiSocketConfig(origin: origin, path: path);
  }

  static String _socketOrigin(Uri uri) {
    final port = _explicitPort(uri);
    if (port == null) {
      return Uri(scheme: uri.scheme, host: uri.host).toString();
    }
    return Uri(scheme: uri.scheme, host: uri.host, port: port).toString();
  }

  static int? _explicitPort(Uri uri) {
    if (!uri.hasPort) return null;
    final port = uri.port;
    if (port <= 0) return null;
    final defaultPort =
        uri.scheme == 'https' || uri.scheme == 'wss' ? 443 : 80;
    if (port == defaultPort) return null;
    return port;
  }

  /// Probe lại URL (resume app, rút USB, mở tab Chat…).
  static Future<bool> recheckBaseUrl() async {
    if (kReleaseMode || kIsWeb) return false;

    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return false;

    final before = _baseUrl;
    await _resolveAndApplyBaseUrl();
    return before != _baseUrl;
  }

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

    await _resolveAndApplyBaseUrl();
  }

  static Future<void> _resolveAndApplyBaseUrl() async {
    const forceLocal = bool.fromEnvironment('USE_LOCAL_API');
    if (forceLocal) {
      _baseUrl = await _resolveLocalBaseUrl();
      _log('USE_LOCAL_API → $_baseUrl');
      return;
    }

    if (kIsWeb) {
      _baseUrl = 'http://localhost:3000';
      _log('web debug → localhost');
      return;
    }

    if (await _isEmulatorOrSimulator()) {
      _baseUrl = await _resolveLocalBaseUrl();
      _log('emulator/simulator → $_baseUrl');
      return;
    }

    await _applyPhysicalDeviceBaseUrl();
  }

  /// Máy thật: 127.0.0.1 chỉ khi debugger gắn (USB/adb reverse).
  /// Không USB → production nếu API thật; tránh giữ localhost sau rút cáp.
  static Future<void> _applyPhysicalDeviceBaseUrl() async {
    const lanHost = String.fromEnvironment('LOCAL_API_HOST');
    final localUrl = await _resolveLocalBaseUrl();
    final isLoopback = _isLoopbackUrl(localUrl);

    if (lanHost.isNotEmpty && await _isBackendReachable(localUrl)) {
      _baseUrl = localUrl;
      _log('LOCAL_API_HOST reachable → $localUrl');
      return;
    }

    if (isLoopback) {
      final debuggerConnected = await _invokeBool('isDebuggerConnected');
      if (debuggerConnected && await _isBackendReachable(localUrl)) {
        _baseUrl = localUrl;
        _log('USB debug (adb reverse) → $localUrl');
        return;
      }
    } else if (await _isBackendReachable(localUrl)) {
      _baseUrl = localUrl;
      _log('local reachable → $localUrl');
      return;
    }

    if (await _isBackendReachable(productionBaseUrl)) {
      _baseUrl = productionBaseUrl;
      _log('production API ok → $productionBaseUrl');
      return;
    }

    _baseUrl = productionBaseUrl;
    _log(
      'production chưa trả {ok:true} (nginx /mobile/ hoặc Node API?) — '
      'USB dev: adb reverse + npm start | WiFi: --dart-define=LOCAL_API_HOST=<IP_PC>',
    );
  }

  static bool _isLoopbackUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == '127.0.0.1' || host == 'localhost';
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
      return 'http://127.0.0.1:3000';
    }

    if (Platform.isIOS) {
      final isSimulator = await _invokeBool('isSimulator');
      if (isSimulator) {
        return 'http://127.0.0.1:3000';
      }
      return productionBaseUrl;
    }

    return 'http://127.0.0.1:3000';
  }

  /// Chỉ chấp nhận JSON `{ok:true}` — tránh nginx SPA trả HTML 200.
  static Future<bool> _isBackendReachable(String baseUrl) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(milliseconds: 800);
      final request = await client
          .getUrl(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(milliseconds: 800));
      final response =
          await request.close().timeout(const Duration(milliseconds: 800));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(milliseconds: 800));
      final lower = body.toLowerCase();
      if (lower.contains('<html') || lower.contains('<!doctype')) {
        return false;
      }
      return body.contains('"ok":true') || body.contains('"ok": true');
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
      final socket = socketConfig;
      debugPrint(
        'API baseUrl = $_baseUrl ($reason) | Socket.IO ${socket.origin}${socket.path}',
      );
    }
  }
}

class ApiSocketConfig {
  final String origin;
  final String path;

  const ApiSocketConfig({
    required this.origin,
    required this.path,
  });
}
