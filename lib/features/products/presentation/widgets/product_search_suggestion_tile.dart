import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/product.dart';

class ProductSearchSuggestionTile extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onTap;

  const ProductSearchSuggestionTile({
    super.key,
    required this.product,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? AppColors.darkSurface : const Color(0xFFF6F3F2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52,
                  height: 52,
                  color: isDark ? AppColors.darkCard : Colors.white,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.smartphone,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.smartphone,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
