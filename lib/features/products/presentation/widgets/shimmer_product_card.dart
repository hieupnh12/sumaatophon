import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/design_system/app_colors.dart';

class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final imageBg = isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF6F3F2);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: imageBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(width: 40, height: 10, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(width: double.infinity, height: 13, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(width: 70, height: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(width: 36, height: 13, color: Colors.white),
                    ),
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(width: 20, height: 20, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
