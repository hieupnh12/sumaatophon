import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_company_invoice_section.dart';
import 'checkout_customer_section.dart';
import 'checkout_delivery_speed_section.dart';
import 'checkout_delivery_type_tabs.dart';
import 'checkout_home_delivery_form.dart';
import 'checkout_pickup_form.dart';
import 'checkout_section_card.dart';

class CheckoutInfoTab extends StatelessWidget {
  const CheckoutInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const CheckoutCustomerSection(),
            const SizedBox(height: 12),
            CheckoutSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('checkout_receiving_info'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  CheckoutDeliveryTypeTabs(
                    activeType: state.deliveryType,
                    onTypeChanged: (type) {
                      context.read<CheckoutBloc>().add(SetDeliveryTypeEvent(type));
                    },
                  ),
                  const SizedBox(height: 20),
                  if (state.deliveryType == DeliveryType.storePickup)
                    const CheckoutPickupForm()
                  else
                    const CheckoutHomeDeliveryForm(),
                ],
              ),
            ),
            if (state.deliveryType == DeliveryType.homeDelivery) ...[
              const SizedBox(height: 12),
              const CheckoutDeliverySpeedSection(),
              const SizedBox(height: 12),
              const CheckoutCompanyInvoiceSection(),
            ],
          ],
        );
      },
    );
  }
}
