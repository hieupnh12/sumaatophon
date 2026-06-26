import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_company_invoice_section.dart';
import 'checkout_section_card.dart';

/// Hiển thị xác nhận xuất hóa đơn khi chọn thanh toán QR PayOS.
class CheckoutPaymentInvoiceSection extends StatelessWidget {
  const CheckoutPaymentInvoiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        if (state.selectedPaymentMethod != 'checkout_payment_qr') {
          return const SizedBox.shrink();
        }

        return const Column(
          children: [
            CheckoutCompanyInvoiceSection(),
            SizedBox(height: CheckoutSpacing.sectionGap),
          ],
        );
      },
    );
  }
}
