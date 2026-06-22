import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/cart_item.dart';
import '../bloc/cart_bloc.dart';

// Widget hiển thị 1 dòng sản phẩm trong giỏ hàng.
class CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const CartItemTile({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = cartItem.product;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final canDecrease = cartItem.quantity > 1;
    final canIncrease = cartItem.quantity < product.stockQuantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(product.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(product.price),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: canDecrease
                      ? () {
                          HapticFeedback.selectionClick();
                          context.read<CartBloc>().add(
                                UpdateQuantityEvent(product, cartItem.quantity - 1),
                              );
                        }
                      : null,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                Text(
                  '${cartItem.quantity}',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: canIncrease
                      ? () {
                          HapticFeedback.selectionClick();
                          context.read<CartBloc>().add(
                                UpdateQuantityEvent(product, cartItem.quantity + 1),
                              );
                        }
                      : null,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('cart_remove_item'),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error.withValues(alpha: 0.85),
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              context.read<CartBloc>().add(RemoveFromCartEvent(product));
            },
          ),
        ],
      ),
    );
  }
}
