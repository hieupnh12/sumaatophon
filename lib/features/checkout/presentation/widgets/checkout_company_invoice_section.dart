import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_section_card.dart';

class CheckoutCompanyInvoiceSection extends StatelessWidget {
  const CheckoutCompanyInvoiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('checkout_company_invoice_question'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: state.wantsCompanyInvoice,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<CheckoutBloc>().add(SetCompanyInvoiceEvent(value));
                      }
                    },
                  ),
                  Text(context.tr('checkout_yes')),
                  const SizedBox(width: 16),
                  Radio<bool>(
                    value: false,
                    groupValue: state.wantsCompanyInvoice,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<CheckoutBloc>().add(SetCompanyInvoiceEvent(value));
                      }
                    },
                  ),
                  Text(context.tr('checkout_no')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
