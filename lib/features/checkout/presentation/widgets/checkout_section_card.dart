import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

/// Spacing chuẩn cho các section checkout.
class CheckoutSpacing {
  static const double sectionGap = 12;
  static const double fieldGap = 12;
  static const double titleBottom = 12;
  static const double cardPadding = 16;
  static const double inputHeight = 48;
}

class CheckoutSectionCard extends StatelessWidget {
  const CheckoutSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CheckoutSpacing.cardPadding),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: child,
    );
  }
}

class CheckoutSectionTitle extends StatelessWidget {
  const CheckoutSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CheckoutSpacing.titleBottom),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
      ),
    );
  }
}

class CheckoutSubsectionTitle extends StatelessWidget {
  const CheckoutSubsectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CheckoutSpacing.titleBottom),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
      ),
    );
  }
}
