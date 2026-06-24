import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../bloc/cart_bloc.dart';

// Widget hiển thị 1 dòng sản phẩm trong giỏ hàng (kiểu CellphoneS).
class CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const CartItemTile({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = cartItem.product;
    final version = cartItem.version;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final canDecrease = cartItem.quantity > 1;
    final canIncrease = cartItem.quantity < cartItem.maxQuantity;

    return Slidable(
      key: ValueKey(version.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.heavyImpact();
              context.read<CartBloc>().add(RemoveFromCartEvent(version.id));
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            SizedBox(
              width: 72,
              height: 88,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    version.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormatter.format(cartItem.unitPrice),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  if (product.hasDiscount) ...[
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(product.originalPrice),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        decoration: TextDecoration.lineThrough,
                        decorationColor:
                            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _QuantityStepper(
                      quantity: cartItem.quantity,
                      canDecrease: canDecrease,
                      canIncrease: canIncrease,
                      onDecrease: () {
                        HapticFeedback.selectionClick();
                        context.read<CartBloc>().add(
                              UpdateQuantityEvent(version.id, cartItem.quantity - 1),
                            );
                      },
                      onIncrease: () {
                        HapticFeedback.selectionClick();
                        context.read<CartBloc>().add(
                              UpdateQuantityEvent(version.id, cartItem.quantity + 1),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onPressed: canDecrease ? onDecrease : null,
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: borderColor),
              ),
            ),
            child: Text(
              '$quantity',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onPressed: canIncrease ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = onPressed != null;

    return SizedBox(
      width: 36,
      height: 32,
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: enabled
              ? (isDark ? AppColors.darkText : AppColors.lightText)
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 18,
      ),
    );
  }
}
