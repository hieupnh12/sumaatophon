import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_colors.dart';

/// Popup xác nhận chuẩn của app (mascot, nút đóng góc, 2 nút ngang).
///
/// Trả về `true` khi bấm nút xác nhận (outlined bên phải),
/// `false` khi bấm đóng / hủy (filled bên trái hoặc icon X).
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String dismissLabel,
  required String confirmLabel,
  String? imageAsset,
  Color accentColor = AppColors.primary,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
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
                  onTap: () => Navigator.pop(dialogContext, false),
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              if (imageAsset != null) ...[
                Image.asset(
                  imageAsset,
                  height: 120,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.help_outline_rounded,
                    size: 80,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        dismissLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: accentColor),
                        foregroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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

/// Shortcut cho popup yêu cầu đăng nhập trước khi dùng giỏ hàng.
Future<bool?> showCartLoginConfirmDialog(BuildContext context) {
  return showAppConfirmDialog(
    context,
    title: context.trRead('cart_login_confirm_title'),
    message: context.trRead('cart_login_confirm_message'),
    dismissLabel: context.trRead('close'),
    confirmLabel: context.trRead('login_btn'),
    imageAsset: 'assets/images/guest_illustration.png',
    accentColor: AppColors.primary,
  );
}

/// Shortcut cho popup xác nhận đăng xuất.
Future<bool?> showLogoutConfirmDialog(BuildContext context) {
  return showAppConfirmDialog(
    context,
    title: context.trRead('logout_confirm_title'),
    message: context.trRead('logout_confirm_message'),
    dismissLabel: context.trRead('close'),
    confirmLabel: context.trRead('logout'),
    imageAsset: 'assets/images/logout_mascot.png',
    accentColor: AppColors.error,
  );
}
