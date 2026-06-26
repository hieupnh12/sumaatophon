import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../address/presentation/bloc/address_bloc.dart';
import '../bloc/checkout_bloc.dart';
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
            const SizedBox(height: CheckoutSpacing.sectionGap),
            CheckoutSectionCard(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: CheckoutDeliveryTypeTabs(
                activeType: state.deliveryType,
                onTypeChanged: (type) {
                  context.read<CheckoutBloc>().add(SetDeliveryTypeEvent(type));
                  if (type == DeliveryType.homeDelivery) {
                    final addressState = context.read<AddressBloc>().state;
                    if (addressState is AddressLoaded) {
                      context.read<CheckoutBloc>().add(
                            ApplyAddressesFromBookEvent(addressState.addresses),
                          );
                    } else {
                      context.read<AddressBloc>().add(LoadAddressesEvent());
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: CheckoutSpacing.sectionGap),
            if (state.deliveryType == DeliveryType.storePickup) ...[
              CheckoutSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckoutSectionTitle(title: context.tr('checkout_receiving_info')),
                    const CheckoutPickupForm(),
                  ],
                ),
              ),
            ] else ...[
              const CheckoutHomeDeliveryForm(),
              const SizedBox(height: CheckoutSpacing.sectionGap),
              const CheckoutDeliverySpeedSection(),
            ],
          ],
        );
      },
    );
  }
}
