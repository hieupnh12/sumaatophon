import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';

class CheckoutStepTabs extends StatelessWidget {
  const CheckoutStepTabs({
    super.key,
    required this.activeStep,
    required this.onStepChanged,
  });

  final CheckoutStep activeStep;
  final ValueChanged<CheckoutStep> onStepChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          _StepTab(
            label: context.tr('checkout_tab_info'),
            isActive: activeStep == CheckoutStep.information,
            onTap: () => onStepChanged(CheckoutStep.information),
          ),
          _StepTab(
            label: context.tr('checkout_tab_payment'),
            isActive: activeStep == CheckoutStep.payment,
            onTap: () => onStepChanged(CheckoutStep.payment),
          ),
        ],
      ),
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({
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

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            Container(
              height: 2,
              color: isActive ? activeColor : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
