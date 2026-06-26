import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_format.dart';
import 'checkout_section_card.dart';

class CheckoutDeliverySpeedSection extends StatelessWidget {
  const CheckoutDeliverySpeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final superFastTime = formatDeliveryDeadline(DateTime(now.year, now.month, now.day, 13));
    final standardTime = formatDeliveryDeadline(DateTime(now.year, now.month, now.day, 21));

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('checkout_select_delivery_method'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _DeliveryOptionCard(
                icon: Icons.inventory_2_outlined,
                label: context.tr('checkout_super_fast_delivery').replaceAll('{time}', superFastTime),
                isSelected: state.deliverySpeed == DeliverySpeed.superFast,
                onTap: () {
                  context.read<CheckoutBloc>().add(const SelectDeliverySpeedEvent(DeliverySpeed.superFast));
                },
              ),
              const SizedBox(height: 12),
              _DeliveryOptionCard(
                icon: Icons.local_shipping_outlined,
                label: context.tr('checkout_standard_delivery').replaceAll('{time}', standardTime),
                isSelected: state.deliverySpeed == DeliverySpeed.standard,
                onTap: () {
                  context.read<CheckoutBloc>().add(const SelectDeliverySpeedEvent(DeliverySpeed.standard));
                },
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('checkout_address_book_tip'),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
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

class _DeliveryOptionCard extends StatelessWidget {
  const _DeliveryOptionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
