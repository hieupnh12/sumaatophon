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

    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final imageBg = isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF6F3F2);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);

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
            color: cardBg,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: imageBg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Hero(
                        tag: 'product_image_${widget.product.id}',
                        createRectTween: (begin, end) => MaterialRectCenterArcTween(begin: begin, end: end),
                        child: Material(
                          color: Colors.transparent,
                          child: Image.network(
                            widget.product.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported_outlined,
                              color: isDark ? Colors.white54 : Colors.black26,
                              size: 40,
                            ),
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
                          bg: AppColors.primary,
                          fg: Colors.white,
                        ),
                      ),
                    if (widget.product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          label: '-${widget.product.discountPercentage}%',
                          bg: AppColors.error,
                          fg: Colors.white,
                        ),
                      ),
                    if (!widget.product.isNew && !widget.product.hasDiscount)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _Badge(
                          label: context.tr('product_installment'),
                          bg: const Color(0xFF896100),
                          fg: const Color(0xFFFFE5BC),
                          fontSize: 9,
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
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: widget.product.hasDiscount ? 34 : 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.product.hasDiscount)
                            Text(
                              currencyFormatter.format(widget.product.originalPrice),
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                          Text(
                            currencyFormatter.format(widget.product.price),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFBA20),
                              size: 15,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.product.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isFavorite = !_isFavorite);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: _isFavorite
                                ? AppColors.error
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
  final Color bg;
  final Color fg;
  final double fontSize;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
