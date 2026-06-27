import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  void _callPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          context.tr('help_center'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  context.tr('help_center_other_support'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              _buildSupportItem(
                context: context,
                isDark: isDark,
                icon: Icons.shopping_cart_outlined,
                title: context.tr('help_center_sales_support'),
                subtitle: context.tr('help_center_sales_phone'),
                onTap: () => _callPhone('0982481094'),
              ),
              _buildDivider(isDark),
              _buildSupportItem(
                context: context,
                isDark: isDark,
                icon: Icons.settings_outlined,
                title: context.tr('help_center_tech_support'),
                subtitle: context.tr('help_center_tech_phone'),
                onTap: () => _callPhone('03955710052'),
              ),
              _buildDivider(isDark),
              _buildSupportItem(
                context: context,
                isDark: isDark,
                icon: Icons.headset_mic_outlined,
                title: context.tr('help_center_customer_care'),
                subtitle: context.tr('help_center_care_phone'),
                onTap: () => _callPhone('0385546145'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: const Color(0xFF7A1C1C), // Maroon color matching the UI
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        height: 1,
      ),
    );
  }
}
