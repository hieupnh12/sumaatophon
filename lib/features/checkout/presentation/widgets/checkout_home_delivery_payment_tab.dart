import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_payment_details_section.dart';
import 'checkout_payment_methods_section.dart';
import 'checkout_payment_product_section.dart';
import 'checkout_receiving_summary_section.dart';
import 'checkout_section_card.dart';
import 'checkout_terms_section.dart';

class CheckoutHomeDeliveryPaymentTab extends StatelessWidget {
  const CheckoutHomeDeliveryPaymentTab({super.key});

  static double _shippingFeeFor(DeliverySpeed speed) {
    return speed == DeliverySpeed.superFast ? 50000 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, checkoutState) {
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                CheckoutPaymentProductSection(items: cartState.selectedItems),
                CheckoutPaymentDetailsSection(
                  shippingFee: _shippingFeeFor(checkoutState.deliverySpeed),
                ),
                const SizedBox(height: CheckoutSpacing.sectionGap),
                CheckoutPaymentMethodsSection(key: ValueKey(checkoutState.deliveryType)),
                const SizedBox(height: CheckoutSpacing.sectionGap),
                const CheckoutReceivingSummarySection(),
                const SizedBox(height: CheckoutSpacing.sectionGap),
                const CheckoutTermsSection(),
              ],
            );
          },
        );
      },
    );
  }
}
