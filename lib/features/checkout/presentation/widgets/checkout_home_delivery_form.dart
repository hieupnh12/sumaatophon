import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_form_fields.dart';
import 'checkout_location_data.dart';
import 'checkout_section_card.dart';

class CheckoutHomeDeliveryForm extends StatefulWidget {
  const CheckoutHomeDeliveryForm({super.key});

  @override
  State<CheckoutHomeDeliveryForm> createState() => _CheckoutHomeDeliveryFormState();
}

class _CheckoutHomeDeliveryFormState extends State<CheckoutHomeDeliveryForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _homeAddressController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final state = context.read<CheckoutBloc>().state;
    _nameController = TextEditingController(text: state.recipientName);
    _phoneController = TextEditingController(text: state.recipientPhone);
    _homeAddressController = TextEditingController(text: state.homeAddress);
    _notesController = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        final districts = CheckoutLocationData.districts[state.province] ?? [];
        final wards = state.district != null ? (CheckoutLocationData.wards[state.district] ?? []) : <String>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckoutSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('checkout_recipient_info'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  CheckoutLabeledField(
                    label: context.tr('checkout_full_name'),
                    child: CheckoutTextField(
                      controller: _nameController,
                      showClear: true,
                      onChanged: (value) {
                        context.read<CheckoutBloc>().add(UpdateRecipientNameEvent(value));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckoutLabeledField(
                    label: context.tr('checkout_phone'),
                    child: CheckoutTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      showClear: true,
                      onChanged: (value) {
                        context.read<CheckoutBloc>().add(UpdateRecipientPhoneEvent(value));
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CheckoutSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('checkout_delivery_address_section'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
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
                    label: context.tr('checkout_ward'),
                    child: CheckoutDropdownField(
                      value: state.ward,
                      items: wards,
                      hint: context.tr('checkout_select_ward'),
                      onChanged: (value) {
                        context.read<CheckoutBloc>().add(UpdateWardEvent(value));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckoutLabeledField(
                    label: context.tr('checkout_home_address'),
                    child: CheckoutTextField(
                      controller: _homeAddressController,
                      hintText: context.tr('checkout_home_address_hint'),
                      onChanged: (value) {
                        context.read<CheckoutBloc>().add(UpdateHomeAddressEvent(value));
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
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: state.saveToAddressBook,
                    onChanged: (value) {
                      context.read<CheckoutBloc>().add(ToggleSaveAddressEvent(value ?? false));
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(context.tr('checkout_save_address'), style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
