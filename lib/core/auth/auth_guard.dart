import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../design_system/app_confirm_dialog.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
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
    final confirmed = await showCartLoginConfirmDialog(context);

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
