import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'checkout_section_card.dart';

class CheckoutTermsSection extends StatelessWidget {
  const CheckoutTermsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CheckoutSectionCard(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          children: [
            TextSpan(text: '${context.tr('checkout_terms_prefix')} '),
            TextSpan(
              text: context.tr('checkout_terms_link'),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' ${context.tr('checkout_terms_suffix')}'),
          ],
        ),
      ),
    );
  }
}
