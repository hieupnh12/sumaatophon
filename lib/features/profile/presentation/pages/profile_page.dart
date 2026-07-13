import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'help_center_page.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/language_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'account_info_page.dart';
import '../../../orders/presentation/pages/order_list_page.dart';
import '../../../address/presentation/pages/address_list_page.dart';
import '../../../../features/warranty/presentation/pages/warranty_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const ProfilePage({super.key, this.onLoginSuccess});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showLanguageSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLang = context.read<LanguageCubit>().state;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final languages = {
          'vi': ctx.tr('lang_vi'),
          'en': ctx.tr('lang_en'),
          'ja': ctx.tr('lang_ja'),
        };
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

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = context.tr('profile_guest');
        String email = '';
        bool isGuest = true;
        String gender = 'Other';

        if (state is AuthenticatedState && state.user.id != 'guest') {
          isGuest = false;
          userName = state.user.name;
          email = state.user.email;
          if (state.user.gender == 1) gender = 'Male';
          else if (state.user.gender == 2) gender = 'Female';
        }

        String avatarUrl = '';
        if (!isGuest) {
          final seed = Uri.encodeComponent(userName.isEmpty ? 'User' : userName);
          if (gender == 'Male') {
            avatarUrl = 'https://api.dicebear.com/9.x/croodles/png?seed=$seed-boy&backgroundColor=b6e3f4';
          } else if (gender == 'Female') {
            avatarUrl = 'https://api.dicebear.com/9.x/croodles/png?seed=$seed-girl&backgroundColor=ffdfbf';
          } else {
            avatarUrl = 'https://api.dicebear.com/9.x/croodles/png?seed=$seed&backgroundColor=e2e2e2';
          }
        }


        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            toolbarHeight: 90,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: !isGuest
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                          ),
                        )
                      : Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: const [],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              // Simulating refresh action
              await Future.delayed(const Duration(seconds: 1));
            },
            color: theme.colorScheme.primary,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: isGuest
                ? _buildGuestBody(context, theme, isDark)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                // Unified Orders Section
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
                          child: Text(
                            context.tr('profile_orders'), 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF637381)
                            )
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOrderAction(
                                Icons.pending_actions_rounded,
                                context.tr('profile_order_pending'),
                                isDark,
                                onTap: () => _openOrderList(
                                  context,
                                  tabIndex: OrderListPage.tabPending,
                                  titleKey: 'profile_order_pending',
                                ),
                              ),
                              _buildOrderAction(
                                Icons.local_shipping_outlined,
                                context.tr('profile_order_shipping'),
                                isDark,
                                onTap: () => _openOrderList(
                                  context,
                                  tabIndex: OrderListPage.tabShipping,
                                  titleKey: 'profile_order_shipping',
                                ),
                              ),
                              _buildOrderAction(
                                Icons.rate_review_outlined,
                                context.tr('profile_order_review'),
                                isDark,
                                onTap: () => _openOrderList(
                                  context,
                                  tabIndex: OrderListPage.tabCompleted,
                                  titleKey: 'profile_order_review',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildDivider(isDark),
                        _buildListItem(
                          Icons.inventory_2_outlined, 
                          context.tr('profile_orders_title'), 
                          isDark, 
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OrderListPage()),
                            );
                          },
                        ),
                        _buildDivider(isDark),

                        _buildListItem(
                          Icons.shield_outlined, 
                          context.tr('profile_warranty_info'), 
                          isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WarrantyPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Utilities Section
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
                          child: Text(
                            context.tr('profile_utilities'), 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF637381)
                            )
                          ),
                        ),
                      _buildListItem(
                        Icons.person_outline_rounded, 
                        context.tr('profile_account_info'), 
                        isDark, 
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AccountInfoPage()),
                          );
                        },
                      ),
                      _buildDivider(isDark),
                      _buildListItem(
                        Icons.location_on_outlined, 
                        context.tr('profile_address'), 
                        isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddressListPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 24),

                // Settings Section
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
                          child: Text(
                            context.tr('profile_settings'), 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF637381)
                            )
                          ),
                        ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: theme.colorScheme.primary),
                        ),
                        title: Text(context.tr('theme'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Switch(
                          value: isDark,
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (_) {
                            HapticFeedback.lightImpact();
                            context.read<ThemeCubit>().toggleTheme();
                          },
                        ),
                      ),
                      _buildDivider(isDark),
                      _buildListItem(
                        Icons.language_rounded, 
                        context.tr('language'), 
                        isDark, 
                        trailingText: {
                          'vi': context.tr('lang_vi'),
                          'en': context.tr('lang_en'),
                          'ja': context.tr('lang_ja'),
                        }[context.watch<LanguageCubit>().state],
                        onTap: _showLanguageSelector,
                      ),
                      _buildDivider(isDark),
                      _buildListItem(
                        Icons.help_outline_rounded, 
                        context.tr('help_center'), 
                        isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 32),

                  // Logout Button
                  OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showLogoutConfirmDialog(context);
                      if (confirmed == true && context.mounted) {
                        context.read<AuthBloc>().add(LogoutRequested());
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(context.tr('logout'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildGuestBody(BuildContext context, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Content section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/guest_banner.png',
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24), // Reduced from 32

                // 3D Illustration & Features
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16), // Reduced from 24
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EBEE), // Matches the background color of guest_illustration.png
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/guest_illustration.png',
                        height: 140, // Reduced from 180
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.card_giftcard, size: 80, color: Colors.grey), // Reduced icon size
                      ),
                      const SizedBox(height: 16), // Reduced from 32
                      _buildGuestFeatureItem(context.tr('profile_guest_feature_1'), isDark),
                      _buildGuestFeatureItem(context.tr('profile_guest_feature_2'), isDark),
                      _buildGuestFeatureItem(context.tr('profile_guest_feature_3'), isDark),
                      _buildGuestFeatureItem(context.tr('profile_guest_feature_4'), isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 24), // Reduced from 48

                // Login Button
                ElevatedButton(
                  onPressed: () async {
                    final loggedIn = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen(returnAfterAuth: true)),
                    );
                    if (loggedIn == true && context.mounted && widget.onLoginSuccess != null) {
                      widget.onLoginSuccess!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    context.tr('profile_login_now'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24), // Reduced from 40
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Reduced from 12.0
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, {VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onActionTap,
          child: Text(action, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  void _openOrderList(
    BuildContext context, {
    required int tabIndex,
    required String titleKey,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderListPage(
          titleKey: titleKey,
          initialTabIndex: tabIndex,
        ),
      ),
    );
  }

  Widget _buildOrderAction(
    IconData icon,
    String label,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 34, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, bool isDark, {String? trailingText, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: trailingText != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trailingText, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            )
          : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 16,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
