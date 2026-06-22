import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../bloc/cart_bloc.dart';

// Widget ô nhập mã giảm giá.
// Khi mã đã được áp dụng, hiển thị tag xanh với nút xóa.
class PromoCodeBox extends StatefulWidget {
  const PromoCodeBox({super.key});

  @override
  State<PromoCodeBox> createState() => _PromoCodeBoxState();
}

class _PromoCodeBoxState extends State<PromoCodeBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.promoCode != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('cart_promo_applied').replaceAll('{code}', state.promoCode!),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    context.read<CartBloc>().add(RemovePromoCodeEvent());
                  },
                  child: const Icon(Icons.close, color: AppColors.success, size: 20),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: context.tr('promo_hint'),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  context
                      .read<CartBloc>()
                      .add(ApplyPromoCodeEvent(_controller.text));
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('apply')),
            ),
          ],
        );
      },
    );
  }
}
