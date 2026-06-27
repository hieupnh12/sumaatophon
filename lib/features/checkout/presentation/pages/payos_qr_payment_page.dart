import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../utils/payos_link_launcher.dart';
import 'payos_checkout_page.dart';

class PayOsQrPaymentPage extends StatefulWidget {
  const PayOsQrPaymentPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.checkoutUrl,
    this.qrCode,
    required this.onPollPaymentStatus,
  });

  final String orderId;
  final int amount;
  final String checkoutUrl;
  final String? qrCode;
  final Future<PayOsPaymentStatus> Function() onPollPaymentStatus;

  @override
  State<PayOsQrPaymentPage> createState() => _PayOsQrPaymentPageState();
}

class _PayOsQrPaymentPageState extends State<PayOsQrPaymentPage> with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _isChecking = false;
  bool _isOpeningBank = false;

  String get _formattedAmount {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(widget.amount);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollPaymentStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollPaymentStatus();
    }
  }

  Future<void> _finish(bool success) async {
    if (!mounted) return;
    Navigator.of(context).pop(success);
  }

  Future<void> _pollPaymentStatus() async {
    if (_isChecking || !mounted) return;
    _isChecking = true;
    try {
      final status = await widget.onPollPaymentStatus();
      if (status.isPaid && mounted) {
        await _finish(true);
      }
    } catch (_) {
      // Ignore transient poll errors.
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _openExternalBrowser() async {
    if (_isOpeningBank) return;
    if (widget.checkoutUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trRead('checkout_payos_open_bank_failed')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final openFailedMessage = context.trRead('checkout_payos_open_external_browser_failed');
    final openingMessage = context.trRead('checkout_payos_open_bank_opening');
    setState(() => _isOpeningBank = true);
    try {
      final opened = await openPayOsCheckoutInBrowser(widget.checkoutUrl);
      if (!mounted) return;
      if (opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(openingMessage)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(openFailedMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningBank = false);
    }
  }

  Future<void> _openWebView() async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PayOsCheckoutPage(
          checkoutUrl: widget.checkoutUrl,
          orderId: widget.orderId,
        ),
      ),
    );

    if (!mounted) return;
    if (success == true) {
      await _finish(true);
    } else {
      await _pollPaymentStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final qrData = widget.qrCode?.trim();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      appBar: AppBar(
        title: Text(context.tr('checkout_payos_qr_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _formattedAmount,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('checkout_payos_order_label')}: #${widget.orderId}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.checkoutUrl.trim().isEmpty ? null : _openWebView,
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text(context.tr('checkout_payos_open_this_device')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('checkout_payos_open_this_device_hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isOpeningBank ? null : _openExternalBrowser,
                icon: _isOpeningBank
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_browser_outlined),
                label: Text(context.tr('checkout_payos_open_external_browser')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('checkout_payos_open_external_browser_hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      context.tr('checkout_payos_qr_other_device'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    if (qrData != null && qrData.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 64,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    Text(
                      context.tr('checkout_payos_qr_other_device_hint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _isChecking ? null : _pollPaymentStatus,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('checkout_payos_confirm_paid')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
