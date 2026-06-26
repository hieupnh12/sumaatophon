import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_form_fields.dart';
import 'checkout_section_card.dart';

class CheckoutCustomerSection extends StatefulWidget {
  const CheckoutCustomerSection({super.key});

  @override
  State<CheckoutCustomerSection> createState() => _CheckoutCustomerSectionState();
}

class _CheckoutCustomerSectionState extends State<CheckoutCustomerSection> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final state = context.read<CheckoutBloc>().state;
    _emailController = TextEditingController(text: state.customerEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckoutSectionTitle(title: context.tr('checkout_customer_info')),
              Text(
                state.customerName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      state.customerPhone,
                      style: TextStyle(fontSize: 14, height: 1.3, color: secondaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Text(
                      'S-${state.memberCode}',
                      style: TextStyle(fontSize: 11, height: 1.2, color: secondaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckoutLabeledField(
                label: context.tr('checkout_email'),
                child: CheckoutTextField(
                  controller: _emailController,
                  hintText: context.tr('checkout_email_hint'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    context.read<CheckoutBloc>().add(UpdateCustomerEmailEvent(value));
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('checkout_email_vat_note'),
                style: TextStyle(fontSize: 12, height: 1.4, color: secondaryColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
