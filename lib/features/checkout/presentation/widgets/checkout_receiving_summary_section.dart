import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_section_card.dart';

class CheckoutReceivingSummarySection extends StatelessWidget {
  const CheckoutReceivingSummarySection({super.key});

  String _formatHomeAddress(CheckoutState state) {
    final parts = <String>[
      if (state.homeAddress.trim().isNotEmpty) state.homeAddress.trim(),
      if (state.ward != null && state.ward!.trim().isNotEmpty) state.ward!.trim(),
      if (state.province.trim().isNotEmpty) state.province.trim(),
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: secondary,
    );

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        final isHomeDelivery = state.deliveryType == DeliveryType.homeDelivery;
        final displayName = state.recipientName.isNotEmpty ? state.recipientName : state.customerName;
        final displayPhone = state.recipientPhone.isNotEmpty ? state.recipientPhone : state.customerPhone;
        final addressText = isHomeDelivery
            ? _formatHomeAddress(state)
            : (state.selectedStore ?? '');

        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckoutSectionTitle(title: context.tr('checkout_receiving_summary')),
              if (isHomeDelivery) ...[
                _InlineSummaryRow(
                  label: context.tr('checkout_full_name'),
                  labelStyle: labelStyle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Text('S-${state.memberCode}', style: TextStyle(fontSize: 11, color: secondary)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          displayName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _InlineSummaryRow(
                  label: context.tr('checkout_phone'),
                  labelStyle: labelStyle,
                  child: Text(
                    displayPhone,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondary),
                  ),
                ),
                const SizedBox(height: 12),
                _InlineSummaryRow(
                  label: context.tr('checkout_pickup_at'),
                  labelStyle: labelStyle,
                  child: Text(
                    addressText,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: secondary),
                  ),
                ),
                const SizedBox(height: 12),
                _InlineSummaryRow(
                  label: context.tr('checkout_recipient_label'),
                  labelStyle: labelStyle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        displayName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayPhone,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _SummaryRow(
                  label: context.tr('checkout_full_name'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Text('S-${state.memberCode}', style: TextStyle(fontSize: 11, color: secondary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: context.tr('checkout_phone'),
                  child: Text(displayPhone, style: TextStyle(fontSize: 14, color: secondary)),
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: context.tr('checkout_pickup_at'),
                  child: Text(
                    addressText,
                    style: TextStyle(fontSize: 14, height: 1.4, color: secondary),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _InlineSummaryRow extends StatelessWidget {
  const _InlineSummaryRow({
    required this.label,
    required this.labelStyle,
    required this.child,
  });

  final String label;
  final TextStyle labelStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: labelStyle),
        ),
        Expanded(child: child),
      ],
    );
  }
}
