import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_feature_flags.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/language_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'account_info_page.dart';
import '../../../orders/presentation/pages/order_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showLanguageSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLang = context.read<LanguageCubit>().state;
    final languages = {'vi': 'Tiếng Việt', 'en': 'English', 'ja': '日本語'};

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(context.tr('profile'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String userName = context.tr('profile_guest');
          String email = '';
          bool isGuest = false;

          if (state is AuthenticatedState) {
            if (state.user.id == 'guest') {
              isGuest = true;
            } else {
              userName = state.user.name;
              email = state.user.email;
            }
          }

          if (isGuest) {
            return _buildGuestBody(context, theme, isDark);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Avatar & Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: (!isGuest && state is AuthenticatedState && state.user.avatarUrl != null && state.user.avatarUrl!.isNotEmpty)
                          ? NetworkImage(state.user.avatarUrl!)
                          : null,
                      child: (!isGuest && state is AuthenticatedState && state.user.avatarUrl != null && state.user.avatarUrl!.isNotEmpty)
                          ? null
                          : Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: AppColors.warning, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('profile_gold_member'),
                                  style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Orders Section
                _buildSectionHeader(
                  context.tr('profile_orders_title'), 
                  context.tr('profile_view_all'),
                  onActionTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderListPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOrderAction(Icons.account_balance_wallet_outlined, context.tr('profile_order_pending'), isDark),
                      _buildOrderAction(Icons.local_shipping_outlined, context.tr('profile_order_shipping'), isDark),
                      _buildOrderAction(Icons.star_outline_rounded, context.tr('profile_order_review'), isDark),
                      _buildOrderAction(Icons.sync_rounded, context.tr('profile_order_return'), isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Utilities Section
                Text(context.tr('profile_utilities'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
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
                        Icons.receipt_long_outlined, 
                        context.tr('profile_transaction_history'), 
                        isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OrderListPage()),
                          );
                        },
                      ),
                      _buildDivider(isDark),
                      _buildListItem(Icons.local_offer_outlined, context.tr('profile_voucher'), isDark, trailingText: '5 ${context.tr('offers_count')}'),
                      _buildDivider(isDark),
                      _buildListItem(Icons.location_on_outlined, context.tr('profile_address'), isDark),
                      _buildDivider(isDark),
                      _buildListItem(Icons.payment_rounded, context.tr('profile_payment_methods'), isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Section
                Text(context.tr('profile_settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: theme.colorScheme.primary),
                        ),
                        title: Text(context.tr('theme'), style: const TextStyle(fontWeight: FontWeight.w500)),
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
                        trailingText: {'vi': 'Tiếng Việt', 'en': 'English', 'ja': '日本語'}[context.watch<LanguageCubit>().state],
                        onTap: _showLanguageSelector,
                      ),
                      _buildDivider(isDark),
                      _buildListItem(Icons.help_outline_rounded, context.tr('help_center'), isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (AppFeatureFlags.authRequired) ...[
                  // Logout Button
                  OutlinedButton(
                    onPressed: () {
                      _showLogoutConfirmDialog(context, isDark);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(context.tr('logout'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestBody(BuildContext context, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section with gradient
          Container(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE8F5E9),
                  isDark ? AppColors.darkBackground : AppColors.lightBackground,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Quý khách',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                const SizedBox(height: 32),

                // 3D Illustration
                Image.asset(
                  'assets/images/guest_illustration.png',
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.card_giftcard, size: 100, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Features list
                _buildGuestFeatureItem('Theo dõi đơn hàng mọi lúc, nhận cập nhật tức thì', isDark),
                _buildGuestFeatureItem('Tích điểm & nhận ưu đãi dành riêng cho bạn', isDark),
                _buildGuestFeatureItem('Xem thông tin bảo hành nhanh chóng, chính xác', isDark),
                _buildGuestFeatureItem('Tra cứu lịch sử giao dịch đầy đủ, rõ ràng', isDark),

                const SizedBox(height: 48),

                // Login Button
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequested()); // Clear guest and redirect to login
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
                  child: const Text('Đăng nhập ngay!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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

  void _showLogoutConfirmDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ),
                Image.asset(
                  'assets/images/logout_mascot.png',
                  height: 120,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.help_outline_rounded, size: 80, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn có chắc chắn không? Tài khoản của bạn sẽ không nhận được đặc quyền riêng dành cho thành viên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<AuthBloc>().add(LogoutRequested());
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildOrderAction(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 28, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
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
