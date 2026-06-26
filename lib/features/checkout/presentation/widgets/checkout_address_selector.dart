import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../main.dart';
import '../../../address/domain/entities/address.dart';
import '../../../address/domain/repositories/address_repository.dart';
import '../../../address/data/models/location_models.dart';
import '../../../address/presentation/bloc/address_bloc.dart';
import '../../../address/presentation/pages/address_form_page.dart';
import '../../../address/presentation/widgets/location_picker_sheet.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_form_fields.dart';
import 'checkout_section_card.dart';

class CheckoutAddressSelector extends StatefulWidget {
  const CheckoutAddressSelector({
    super.key,
    required this.addresses,
    required this.selectedAddressId,
  });

  final List<Address> addresses;
  final String? selectedAddressId;

  @override
  State<CheckoutAddressSelector> createState() => _CheckoutAddressSelectorState();
}

class _CheckoutAddressSelectorState extends State<CheckoutAddressSelector> {
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

  Address? get _selectedAddress {
    if (widget.selectedAddressId == null) return null;
    for (final address in widget.addresses) {
      if (address.id == widget.selectedAddressId) return address;
    }
    return null;
  }

  Address? get _displayAddress {
    final selected = _selectedAddress;
    if (selected != null) return selected;
    if (widget.addresses.isEmpty) return null;
    final defaults = widget.addresses.where((a) => a.isDefault).toList();
    return defaults.isNotEmpty ? defaults.first : widget.addresses.first;
  }

  Future<void> _openAddAddressPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressFormPage()),
    );
    if (context.mounted) {
      context.read<AddressBloc>().add(LoadAddressesEvent());
    }
  }

  void _openAddressSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('checkout_select_saved_address'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final address = widget.addresses[index];
                      final isSelected = address.id == widget.selectedAddressId;

                      return InkWell(
                        onTap: () {
                          context.read<CheckoutBloc>().add(SelectSavedAddressEvent(address));
                          Navigator.pop(sheetContext);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      address.type == 'home'
                                          ? context.tr('address_type_home')
                                          : context.tr('address_type_office'),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                  if (address.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        context.tr('address_default_badge'),
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                address.fullAddress,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _openAddAddressPage(context);
                    },
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: Text(context.tr('checkout_add_new_address')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _displayAddress;
    final hasAddresses = widget.addresses.isNotEmpty;
    final hasResolvedSelection = hasAddresses && selected != null;

    return BlocListener<CheckoutBloc, CheckoutState>(
      listenWhen: (previous, current) => previous.notes != current.notes,
      listener: (context, state) {
        if (_notesController.text != state.notes) {
          _notesController.text = state.notes;
        }
      },
      child: CheckoutSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckoutSubsectionTitle(title: context.tr('checkout_delivery_address_section')),
            if (hasResolvedSelection) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((selected.receiverName ?? '').isNotEmpty || (selected.receiverPhone ?? '').isNotEmpty)
                      Text(
                        '${selected.receiverName ?? ''}${(selected.receiverName ?? '').isNotEmpty && (selected.receiverPhone ?? '').isNotEmpty ? ' | ' : ''}${selected.receiverPhone ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3),
                      ),
                    if ((selected.receiverName ?? '').isNotEmpty || (selected.receiverPhone ?? '').isNotEmpty)
                      const SizedBox(height: 6),
                    Text(
                      selected.fullAddress,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openAddressSheet(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(context.tr('checkout_change_address')),
                ),
              ),
              const SizedBox(height: CheckoutSpacing.fieldGap),
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
            ] else ...[
              Text(
                context.tr('checkout_no_saved_address_desc'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddAddressPage(context),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  label: Text(context.tr('checkout_add_new_address')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckoutLocationTapField extends StatelessWidget {
  const CheckoutLocationTapField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null && value!.isNotEmpty;

    return CheckoutLabeledField(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: CheckoutSpacing.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value! : hint,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasValue
                        ? (isDark ? AppColors.darkText : AppColors.lightText)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> pickCheckoutProvince(BuildContext context, CheckoutState state) async {
  final repo = sl<AddressRepository>();
  final provinces = await repo.getProvinces();
  if (!context.mounted) return;

  final selected = await showModalBottomSheet<Province>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LocationPickerSheet<Province>(
      title: context.tr('address_select_province'),
      items: provinces,
      getName: (p) => p.name,
      selectedItem: state.province.isNotEmpty ? Province(code: -1, name: state.province) : null,
    ),
  );

  if (selected != null && context.mounted) {
    context.read<CheckoutBloc>().add(UpdateProvinceEvent(selected.name));
  }
}

Future<void> pickCheckoutWard(BuildContext context, CheckoutState state) async {
  if (state.province.isEmpty) return;

  final repo = sl<AddressRepository>();
  final provinces = await repo.getProvinces();
  Province? province;
  for (final item in provinces) {
    if (item.name == state.province) {
      province = item;
      break;
    }
  }
  if (province == null || !context.mounted) return;
  final selectedProvince = province;

  final wards = await repo.getWards(selectedProvince.code);
  if (!context.mounted) return;

  final selected = await showModalBottomSheet<Ward>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LocationPickerSheet<Ward>(
      title: context.tr('address_select_ward'),
      items: wards,
      getName: (w) => w.name,
      selectedItem: state.ward != null && state.ward!.isNotEmpty
          ? Ward(code: -1, name: state.ward!, provinceCode: selectedProvince.code)
          : null,
    ),
  );

  if (selected != null && context.mounted) {
    context.read<CheckoutBloc>().add(UpdateWardEvent(selected.name));
  }
}
