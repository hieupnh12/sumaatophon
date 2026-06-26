import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_form_fields.dart';
import 'checkout_location_data.dart';
import 'checkout_section_card.dart';

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
    final state = context.read<CheckoutBloc>().state;
    _notesController = TextEditingController(text: state.notes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutBloc>().add(const ApplyDefaultPickupStoreEvent());
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return Column(
          children: [
            CheckoutLabeledField(
              label: context.tr('checkout_store'),
              child: Container(
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
                    Text(
                      CheckoutLocationData.defaultStoreName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CheckoutLocationData.defaultStoreAddress,
                      style: TextStyle(fontSize: 14, height: 1.4, color: secondary),
                    ),
                  ],
                ),
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
          ],
        );
      },
    );
  }
}
