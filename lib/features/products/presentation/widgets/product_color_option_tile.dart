import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

class ProductColorOptionTile extends StatelessWidget {
  final String colorName;
  final String imageUrl;
  final String priceLabel;
  final bool isSelected;
  final bool isDark;
  final bool enabled;
  final String? statusLabel;
  final VoidCallback onTap;

  const ProductColorOptionTile({
    super.key,
    required this.colorName,
    required this.imageUrl,
    required this.priceLabel,
    required this.isSelected,
    required this.isDark,
    this.enabled = true,
    this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineVariant = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);
    final selectedBorder = theme.colorScheme.primary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.55,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBorder : outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: isDark ? AppColors.darkSurface : const Color(0xFFF6F3F2),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.smartphone,
                                size: 22,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF414753),
                              ),
                            )
                          : Icon(
                              Icons.smartphone,
                              size: 22,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF414753),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          colorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          priceLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            height: 1.1,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF414753),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            statusLabel!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              height: 1.1,
                              color: AppColors.error,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: selectedBorder,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
