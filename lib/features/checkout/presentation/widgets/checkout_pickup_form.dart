import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_form_fields.dart';
import 'checkout_location_data.dart';

class CheckoutPickupForm extends StatefulWidget {
  const CheckoutPickupForm({super.key});

  @override
  State<CheckoutPickupForm> createState() => _CheckoutPickupFormState();
}

class _CheckoutPickupFormState extends State<CheckoutPickupForm> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: context.read<CheckoutBloc>().state.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        final districts = CheckoutLocationData.districts[state.province] ?? [];
        final stores = state.district != null ? (CheckoutLocationData.stores[state.district] ?? []) : <String>[];

        return Column(
          children: [
            CheckoutLabeledField(
              label: context.tr('checkout_province'),
              child: CheckoutDropdownField(
                value: state.province,
                items: CheckoutLocationData.provinces,
                onChanged: (value) {
                  if (value != null) {
                    context.read<CheckoutBloc>().add(UpdateProvinceEvent(value));
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            CheckoutLabeledField(
              label: context.tr('checkout_district'),
              child: CheckoutDropdownField(
                value: state.district,
                items: districts,
                hint: context.tr('checkout_select_district'),
                onChanged: (value) {
                  context.read<CheckoutBloc>().add(UpdateDistrictEvent(value));
                },
              ),
            ),
            const SizedBox(height: 16),
            CheckoutLabeledField(
              label: context.tr('checkout_store'),
              child: CheckoutDropdownField(
                value: state.selectedStore,
                items: stores,
                hint: context.tr('checkout_select_store'),
                onChanged: (value) {
                  context.read<CheckoutBloc>().add(UpdateStoreEvent(value));
                },
              ),
            ),
            const SizedBox(height: 16),
            CheckoutLabeledField(
              label: context.tr('checkout_notes'),
              child: CheckoutTextField(
                controller: _notesController,
                hintText: context.tr('checkout_notes_hint'),
                onChanged: (value) {
                  context.read<CheckoutBloc>().add(UpdateNotesEvent(value));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
