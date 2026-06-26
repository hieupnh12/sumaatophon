import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';

class CheckoutDeliveryTypeTabs extends StatelessWidget {
  const CheckoutDeliveryTypeTabs({
    super.key,
    required this.activeType,
    required this.onTypeChanged,
  });

  final DeliveryType activeType;
  final ValueChanged<DeliveryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DeliveryTab(
          label: context.tr('checkout_pickup_store'),
          isActive: activeType == DeliveryType.storePickup,
          onTap: () => onTypeChanged(DeliveryType.storePickup),
        ),
        const SizedBox(width: 24),
        _DeliveryTab(
          label: context.tr('checkout_home_delivery'),
          isActive: activeType == DeliveryType.homeDelivery,
          onTap: () => onTypeChanged(DeliveryType.homeDelivery),
        ),
      ],
    );
  }
}

class _DeliveryTab extends StatelessWidget {
  const _DeliveryTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: label.length * 7.0 + 16,
            color: isActive ? activeColor : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
