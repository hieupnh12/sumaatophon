import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/language_cubit.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingPage({super.key, required this.onFinish});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  IconData _getIcon(String name) {
    switch(name) {
      case "verified_user_rounded": return Icons.verified_user_rounded;
      case "local_shipping_rounded": return Icons.local_shipping_rounded;
      case "support_agent_rounded": return Icons.support_agent_rounded;
      default: return Icons.phone_iphone_rounded;
    }
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    widget.onFinish();
  }

  void _showLanguageSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLang = context.read<LanguageCubit>().state;
    final languages = {'vi': 'Tiếng Việt', 'en': 'English', 'ja': '日本語'};

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ctx.tr('select_language'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...languages.entries.map((entry) {
                final isSelected = currentLang == entry.key;
                return ListTile(
                  title: Text(entry.value, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<LanguageCubit>().changeLanguage(entry.key);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, String>> onboardingData = [
      {
        "title": context.tr('onboarding_title_1'),
        "description": context.tr('onboarding_desc_1'),
        "icon": "verified_user_rounded"
      },
      {
        "title": context.tr('onboarding_title_2'),
        "description": context.tr('onboarding_desc_2'),
        "icon": "local_shipping_rounded"
      },
      {
        "title": context.tr('onboarding_title_3'),
        "description": context.tr('onboarding_desc_3'),
        "icon": "support_agent_rounded"
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header (Language Selector & Skip)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showLanguageSelector(context),
                    icon: Icon(Icons.language_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, size: 20),
                    label: Text(
                      context.watch<LanguageCubit>().state.toUpperCase(),
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      context.tr('skip'), 
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      )
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(onboardingData[index]["icon"]!),
                            size: 100,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          onboardingData[index]["title"]!,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          onboardingData[index]["description"]!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Section (Indicators & Button)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                            ? theme.colorScheme.primary 
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _nextPage(onboardingData.length),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _currentPage == onboardingData.length - 1 ? context.tr('start') : context.tr('next'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
