import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart';import '../../domain/repositories/product_repository.dart';
import '../bloc/product_bloc.dart';

Future<bool?> showProductReviewSheet({
  required BuildContext context,
  required String productId,
  required int customerId,
  required String productName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProductReviewSheet(
      productId: productId,
      customerId: customerId,
      productName: productName,
    ),
  );
}

class ProductReviewSheet extends StatefulWidget {
  const ProductReviewSheet({
    super.key,
    required this.productId,
    required this.customerId,
    required this.productName,
  });

  final String productId;
  final int customerId;
  final String productName;

  @override
  State<ProductReviewSheet> createState() => _ProductReviewSheetState();
}

class _ProductReviewSheetState extends State<ProductReviewSheet> {
  final _contentController = TextEditingController();
  int _rate = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('product_review_content_min'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await sl<ProductRepository>().submitFeedback(
        productId: widget.productId,
        customerId: widget.customerId,
        rate: _rate,
        content: content,
      );

      if (!mounted) return;
      _reloadProductDetailIfPresent();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = _mapError(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _reloadProductDetailIfPresent() {
    try {
      context.read<ProductBloc>().add(
            LoadProductByIdEvent(
              widget.productId,
              customerId: widget.customerId,
            ),
          );
    } catch (_) {
      // Không có ProductBloc (vd. mở từ chi tiết đơn) — bỏ qua.
    }
  }

  String _mapError(BuildContext context, Object error) {
    if (error is ApiException) {
      if (error.statusCode == 404) {
        return context.trRead('product_review_api_not_deployed');
      }

      try {
        final decoded = jsonDecode(error.body);
        if (decoded is Map) {
          final code = decoded['code']?.toString() ?? '';
          if (code == 'FEEDBACK_ALREADY_EXISTS') {
            return context.trRead('product_review_already');
          }
          if (code == 'FEEDBACK_NOT_ELIGIBLE') {
            return context.trRead('product_review_not_eligible');
          }
          final message = decoded['message']?.toString();
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      } catch (_) {
        // Body không phải JSON — dùng fallback bên dưới.
      }
    }

    final raw = error.toString();
    if (raw.contains('FEEDBACK_ALREADY_EXISTS')) {
      return context.trRead('product_review_already');
    }
    if (raw.contains('FEEDBACK_NOT_ELIGIBLE')) {
      return context.trRead('product_review_not_eligible');
    }
    return context.trRead('product_review_error');
  }

  BoxDecoration _sectionDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    );
  }

  InputBorder _fieldBorder(bool isDark, {bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: focused
            ? AppColors.primary
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        width: focused ? 1.5 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('product_review_write'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.productName,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: _sectionDecoration(isDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('product_review_rate_label'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final filled = star <= _rate;
                      return IconButton(
                        onPressed: _isSubmitting ? null : () => setState(() => _rate = star),
                        icon: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: filled ? const Color(0xFFFFB800) : Colors.grey,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _sectionDecoration(isDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('product_review_content_label'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 4,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      hintText: context.tr('product_review_content_hint'),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      enabledBorder: _fieldBorder(isDark),
                      focusedBorder: _fieldBorder(isDark, focused: true),
                      border: _fieldBorder(isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('close')),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(context.tr('product_review_submit')),
            ),
          ],
        ),
      ),
    );
  }
}
