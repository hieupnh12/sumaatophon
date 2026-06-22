/// Feature flags tạm thời — đổi tại đây khi cần bật/tắt nhanh.
class AppFeatureFlags {
  AppFeatureFlags._();

  /// `false` = bỏ qua onboarding/login, vào thẳng app.
  static const bool authRequired = false;
}
