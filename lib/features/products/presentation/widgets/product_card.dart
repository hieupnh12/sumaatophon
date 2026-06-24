import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
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
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    final isElevated = _isHovered || _isPressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          // ignore: deprecated_member_use
          transform: Matrix4.identity()..translate(0.0, isElevated ? -6.0 : 0.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isElevated 
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : (isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder.withValues(alpha: 0.5)),
              width: isElevated ? 1.5 : 1,
            ),
            boxShadow: [
              if (isElevated)
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              else if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE SECTION ---
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16), // Prevent overflow
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Hero(
                        tag: 'product_image_${widget.product.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.product.imageUrl,
                            fit: BoxFit.contain, // Maintain aspect ratio without overflowing
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported_outlined,
                              color: isDark ? Colors.white54 : Colors.black26,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // BADGES
                    if (widget.product.hasDiscount || widget.product.isNew)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.product.hasDiscount ? AppColors.error : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Text(
                            widget.product.hasDiscount ? '-${widget.product.discountPercentage}%' : 'NEW',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // --- INFO SECTION ---
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand
                    Text(
                      widget.product.brand.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Name
                    SizedBox(
                      height: 40,
                      child: Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.product.hasDiscount)
                          Text(
                            currencyFormatter.format(widget.product.originalPrice),
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                        Text(
                          currencyFormatter.format(widget.product.price),
                          style: TextStyle(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: -0.5,
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
