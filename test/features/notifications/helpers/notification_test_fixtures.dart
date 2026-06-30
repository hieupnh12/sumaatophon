import 'package:sumaatophon/features/notifications/domain/entities/app_notification.dart';

/// Dữ liệu mẫu dùng chung cho test thông báo.
class NotificationTestFixtures {
  static const int customerId = 43;

  static const List<AppNotification> sampleItems = [
    AppNotification(
      id: 'n1',
      customerId: '43',
      type: NotificationType.productNew,
      title: 'Sản phẩm mới',
      body: 'iPhone 16 vừa lên kệ',
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      customerId: '43',
      type: NotificationType.orderStatus,
      title: 'Đơn hàng',
      body: 'Đơn #101 đang giao',
      isRead: true,
    ),
  ];

  static const int sampleUnreadCount = 1;

  static ({List<AppNotification> items, int unreadCount}) get loadResult => (
        items: sampleItems,
        unreadCount: sampleUnreadCount,
      );
}
