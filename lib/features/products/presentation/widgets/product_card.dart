import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/product.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final imageBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : AppColors.outlineVariant.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: imageBg),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Hero(
                        tag: 'product_image_${widget.product.id}',
                        child: Image.network(
                          widget.product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported_outlined,
                            color: isDark ? Colors.white54 : AppColors.onSurfaceVariant,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    if (widget.product.isNew)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          label: 'NEW',
                          background: AppColors.primary,
                          foreground: Colors.white,
                        ),
                      ),
                    if (widget.product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: widget.product.isNew ? 52 : 8,
                        child: _Badge(
                          label: '-${widget.product.discountPercentage}%',
                          background: AppColors.error,
                          foreground: Colors.white,
                        ),
                      ),
                    if (!widget.product.hasDiscount && widget.product.price >= 10000000)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _Badge(
                          label: context.tr('product_installment_badge'),
                          background: AppColors.tertiaryContainer,
                          foreground: AppColors.onTertiaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.brand.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.product.hasDiscount)
                      Text(
                        currencyFormatter.format(widget.product.originalPrice),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
                    Text(
                      currencyFormatter.format(widget.product.price),
                      style: const TextStyle(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.tertiaryFixedDim,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isFavorite = !_isFavorite);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 22,
                            color: _isFavorite
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
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

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
