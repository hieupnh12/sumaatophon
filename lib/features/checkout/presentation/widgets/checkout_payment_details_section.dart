import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import 'checkout_format.dart';
import 'checkout_form_fields.dart';
import 'checkout_section_card.dart';

class CheckoutPaymentDetailsSection extends StatefulWidget {
  const CheckoutPaymentDetailsSection({
    super.key,
    required this.shippingFee,
  });

  final double shippingFee;

  @override
  State<CheckoutPaymentDetailsSection> createState() => _CheckoutPaymentDetailsSectionState();
}

class _CheckoutPaymentDetailsSectionState extends State<CheckoutPaymentDetailsSection> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final merchandiseTotal = cartState.selectedSubtotal;
        final discount = cartState.selectedDiscountAmount;
        final grandTotal = cartState.selectedFinalPrice + widget.shippingFee;

        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckoutSectionTitle(title: context.tr('checkout_payment_summary_title')),
              Row(
                children: [
                  Expanded(
                    child: CheckoutTextField(
                      controller: _promoController,
                      hintText: context.tr('checkout_promo_hint'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final code = _promoController.text.trim();
                      if (code.isNotEmpty) {
                        context.read<CartBloc>().add(ApplyPromoCodeEvent(code));
                      }
                    },
                    child: Text(context.tr('checkout_promo_apply')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: context.tr('checkout_product_quantity'),
                value: cartState.selectedTotalItems.toString().padLeft(2, '0'),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                label: context.tr('checkout_merchandise_total'),
                value: formatCheckoutPrice(merchandiseTotal),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                label: context.tr('checkout_shipping_fee'),
                value: widget.shippingFee <= 0
                    ? context.tr('checkout_shipping_free')
                    : formatCheckoutPrice(widget.shippingFee),
                valueColor: widget.shippingFee <= 0 ? AppColors.success : null,
              ),
              if (discount > 0) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  label: context.tr('checkout_direct_discount'),
                  value: '- ${formatCheckoutPrice(discount)}',
                  valueColor: AppColors.success,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Text(
                context.tr('checkout_grand_total'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(context.tr('checkout_vat_note'), style: TextStyle(fontSize: 12, color: secondary)),
              const SizedBox(height: 8),
              Text(
                formatCheckoutPrice(grandTotal),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
