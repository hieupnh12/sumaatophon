import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../cart/domain/entities/cart_item.dart';
import 'checkout_format.dart';
import 'checkout_section_card.dart';

class CheckoutPaymentProductSection extends StatelessWidget {
  const CheckoutPaymentProductSection({super.key, required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: items.map((item) {
        final imageUrl = item.version.imageUrl.isNotEmpty ? item.version.imageUrl : item.product.imageUrl;
        final unitPrice = item.unitPrice;
        final originalPrice = item.product.originalPrice > 0 ? item.product.originalPrice : unitPrice;

        return Padding(
          padding: const EdgeInsets.only(bottom: CheckoutSpacing.sectionGap),
          child: CheckoutSectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      child: const Icon(Icons.phone_iphone, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.product.name} ${item.version.ramRom.isNotEmpty ? '| ${item.version.ramRom}' : ''}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCheckoutPrice(unitPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (originalPrice > unitPrice) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatCheckoutPrice(originalPrice),
                          style: TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr('checkout_item_quantity')}: ${item.quantity.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
