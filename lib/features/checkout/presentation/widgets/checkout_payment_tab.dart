import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_home_delivery_payment_tab.dart';
import 'checkout_pickup_payment_tab.dart';

class CheckoutPaymentTab extends StatelessWidget {
  const CheckoutPaymentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        if (state.deliveryType == DeliveryType.storePickup) {
          return const CheckoutPickupPaymentTab();
        }
        return const CheckoutHomeDeliveryPaymentTab();
      },
    );
  }
}
