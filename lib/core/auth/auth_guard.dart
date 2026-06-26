import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';
import '../../features/auth/domain/entities/user_entity.dart';import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';

/// Chỉ coi là đăng nhập thật khi có customer_id từ MySQL (không phải guest/biometric demo).
bool isRealAuthenticatedUser(UserEntity user) {
  final id = user.id.trim();
  if (id.isEmpty) return false;
  if (id == 'guest' || id == 'bio_user') return false;
  return int.tryParse(id) != null;
}

bool isRealAuthenticatedState(AuthState state) {
  if (state is AuthenticatedState) {
    return isRealAuthenticatedUser(state.user);
  }
  return false;
}

/// Yêu cầu đăng nhập trước khi dùng giỏ hàng. Trả về true nếu đã đăng nhập.
Future<bool> requireAuthForCart(
  BuildContext context, {
  bool confirmBeforeLogin = false,
}) async {
  if (isRealAuthenticatedState(context.read<AuthBloc>().state)) {
    return true;
  }

  if (confirmBeforeLogin) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            dialogContext.tr('cart_login_confirm_title'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(dialogContext.tr('cart_login_confirm_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(dialogContext.tr('login_btn')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return false;
    }
  }

  final loggedIn = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen(returnAfterAuth: true)),
  );

  return loggedIn == true && isRealAuthenticatedState(context.read<AuthBloc>().state);
}
