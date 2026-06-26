import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../address/domain/entities/address.dart';
import '../../../address/presentation/bloc/address_bloc.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_address_selector.dart';

class CheckoutHomeDeliveryForm extends StatefulWidget {
  const CheckoutHomeDeliveryForm({super.key});

  @override
  State<CheckoutHomeDeliveryForm> createState() => _CheckoutHomeDeliveryFormState();
}

class _CheckoutHomeDeliveryFormState extends State<CheckoutHomeDeliveryForm> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAddressesFromBook());
  }

  void _syncAddressesFromBook() {
    final checkoutState = context.read<CheckoutBloc>().state;
    if (checkoutState.deliveryType != DeliveryType.homeDelivery) return;

    final addressState = context.read<AddressBloc>().state;
    if (addressState is AddressLoaded) {
      context.read<CheckoutBloc>().add(ApplyAddressesFromBookEvent(addressState.addresses));
    } else if (addressState is! AddressLoading) {
      context.read<AddressBloc>().add(LoadAddressesEvent());
    }
  }

  List<Address> _addressesFromState(AddressState addressState) {
    if (addressState is AddressLoaded) return addressState.addresses;
    if (addressState is AddressActionFailure) return addressState.previousAddresses;
    return const <Address>[];
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AddressBloc, AddressState>(
          listenWhen: (previous, current) => current is AddressLoaded,
          listener: (context, addressState) {
            if (addressState is AddressLoaded) {
              context.read<CheckoutBloc>().add(ApplyAddressesFromBookEvent(addressState.addresses));
            }
          },
        ),
        BlocListener<CheckoutBloc, CheckoutState>(
          listenWhen: (previous, current) =>
              previous.deliveryType != current.deliveryType &&
              current.deliveryType == DeliveryType.homeDelivery,
          listener: (context, _) => _syncAddressesFromBook(),
        ),
      ],
      child: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, addressState) {
          final addresses = _addressesFromState(addressState);
          final isLoading = addressState is AddressLoading;

          return BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, state) {
              if (state.deliveryType == DeliveryType.homeDelivery &&
                  state.selectedAddressId == null &&
                  addresses.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context.read<CheckoutBloc>().add(ApplyAddressesFromBookEvent(addresses));
                });
              }

              if (isLoading && addresses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return CheckoutAddressSelector(
                addresses: addresses,
                selectedAddressId: state.selectedAddressId,
              );
            },
          );
        },
      ),
    );
  }
}
