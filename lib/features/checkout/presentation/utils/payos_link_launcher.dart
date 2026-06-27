import 'package:url_launcher/url_launcher.dart';

/// PayOS / ngân hàng dùng deep link (momo://, intent://, …) — WebView không mở được, cần app ngoài.
bool payOsShouldOpenExternally(String url) {
  if (url.startsWith('intent://')) return true;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  return scheme.isNotEmpty &&
      scheme != 'http' &&
      scheme != 'https' &&
      scheme != 'about' &&
      scheme != 'data' &&
      scheme != 'javascript';
}

Future<bool> launchPayOsExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Mở trang checkout PayOS bằng Chrome/Safari — từ đó chọn MoMo/VCB và nhảy sang app ví/ngân hàng.
Future<bool> openPayOsCheckoutInBrowser(String checkoutUrl) async {
  final trimmed = checkoutUrl.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return false;

  const modes = [
    LaunchMode.externalApplication,
    LaunchMode.platformDefault,
    LaunchMode.inAppBrowserView,
  ];

  for (final mode in modes) {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (launched) return true;
    } catch (_) {
      // Thử mode kế tiếp (một số máy MIUI chặn externalApplication).
    }
  }

  return false;
}
