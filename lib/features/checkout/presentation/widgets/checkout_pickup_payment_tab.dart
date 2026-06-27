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

class CheckoutPickupPaymentTab extends StatelessWidget {
  const CheckoutPickupPaymentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            CheckoutPaymentProductSection(items: cartState.selectedItems),
            const CheckoutPaymentDetailsSection(shippingFee: 0),
            const SizedBox(height: CheckoutSpacing.sectionGap),
            BlocBuilder<CheckoutBloc, CheckoutState>(
              builder: (context, checkoutState) {
                return CheckoutPaymentMethodsSection(
                  key: ValueKey(checkoutState.deliveryType),
                );
              },
            ),
            const SizedBox(height: CheckoutSpacing.sectionGap),
            const CheckoutReceivingSummarySection(),
            const SizedBox(height: CheckoutSpacing.sectionGap),
            const CheckoutTermsSection(),
          ],
        );
      },
    );
  }
}
