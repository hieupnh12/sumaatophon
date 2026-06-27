import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_section_card.dart';

/// Chọn có/không nhận biên lai xác nhận qua email (dùng email ở Thông tin khách hàng).
class CheckoutCompanyInvoiceSection extends StatelessWidget {
  const CheckoutCompanyInvoiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        final wantsReceipt = state.wantsCompanyInvoice == true;

        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('checkout_email_receipt_question'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('checkout_email_receipt_desc'),
                style: TextStyle(fontSize: 12, height: 1.4, color: secondaryColor),
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
              if (wantsReceipt) ...[
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: state.receiptEmailConfirmed,
                  onChanged: (value) {
                    context
                        .read<CheckoutBloc>()
                        .add(SetReceiptEmailConfirmedEvent(value == true));
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    context.tr('checkout_email_receipt_confirm'),
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
