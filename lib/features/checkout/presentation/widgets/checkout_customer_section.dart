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

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('checkout_customer_info'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                state.customerName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                state.customerPhone,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'S-${state.memberCode}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 8),
              Text(
                context.tr('checkout_email_vat_note'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
