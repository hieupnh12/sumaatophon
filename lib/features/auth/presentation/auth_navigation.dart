import 'package:flutter/material.dart';

import '../../../core/config/app_feature_flags.dart';

/// Điều hướng an toàn sau khi đăng nhập thành công.
void navigateAfterAuth(BuildContext context) {
  if (AppFeatureFlags.authRequired) return;

  final navigator = Navigator.of(context);
  if (!navigator.canPop()) return;

  navigator.popUntil((route) => route.isFirst);
}
