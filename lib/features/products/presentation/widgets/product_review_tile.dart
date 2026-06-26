import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/product_feedback.dart';

class ProductReviewTile extends StatelessWidget {
  final ProductFeedback feedback;

  const ProductReviewTile({
    super.key,
    required this.feedback,
  });

  String _displayName(BuildContext context) {
    final name = feedback.customerName.trim();
    if (name.isEmpty || name.toLowerCase() == 'customer') {
      return context.tr('product_review_guest');
    }
    return name;
  }

  String _formatDate(BuildContext context) {
    if (feedback.createdAt == null) return '';
    final lang = Localizations.localeOf(context).languageCode;
    final pattern = lang == 'ja' ? 'yyyy/MM/dd' : (lang == 'vi' ? 'dd/MM/yyyy' : 'MMM d, yyyy');
    return DateFormat(pattern).format(feedback.createdAt!);
  }

  String _initial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outlineVariant = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : const Color(0xFFC1C6D5).withValues(alpha: 0.3);
    final displayName = _displayName(context);
    final dateText = _formatDate(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  _initial(displayName),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (dateText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF414753),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final filled = index < feedback.rate.round();
                  return Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: filled ? const Color(0xFFFFB800) : const Color(0xFFE0E0E0),
                  );
                }),
              ),
            ],
          ),
          if (feedback.content.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              feedback.content.trim(),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
