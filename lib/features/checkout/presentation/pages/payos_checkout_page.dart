import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../utils/payos_link_launcher.dart';

class PayOsCheckoutPage extends StatefulWidget {
  const PayOsCheckoutPage({
    super.key,
    required this.checkoutUrl,
    required this.orderId,
  });

  final String checkoutUrl;
  final String orderId;

  @override
  State<PayOsCheckoutPage> createState() => _PayOsCheckoutPageState();
}

class _PayOsCheckoutPageState extends State<PayOsCheckoutPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  bool _isSuccessUrl(String url) {
    return url.contains('/payment/success') || url.contains('payment%2Fsuccess');
  }

  bool _isCancelUrl(String url) {
    return url.contains('/payment/cancel') || url.contains('payment%2Fcancel');
  }

  Future<void> _finish(bool success) async {
    if (!mounted) return;
    Navigator.of(context).pop(success);
  }

  Future<NavigationDecision> _handleNavigation(String url) async {
    if (_isSuccessUrl(url)) {
      await _finish(true);
      return NavigationDecision.prevent;
    }
    if (_isCancelUrl(url)) {
      await _finish(false);
      return NavigationDecision.prevent;
    }

    if (payOsShouldOpenExternally(url)) {
      await launchPayOsExternalUrl(url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) => _handleNavigation(request.url),
          onUrlChange: (change) async {
            final url = change.url;
            if (url == null) return;
            if (_isSuccessUrl(url)) {
              await _finish(true);
            } else if (_isCancelUrl(url)) {
              await _finish(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      appBar: AppBar(
        title: Text(context.tr('checkout_payos_webview_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
