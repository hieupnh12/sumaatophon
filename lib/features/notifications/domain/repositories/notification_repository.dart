import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<({List<AppNotification> items, int unreadCount})> getNotifications(int customerId);
  Future<void> markRead(String notificationId, int customerId);
  Future<void> markAllRead(int customerId);
  Future<void> delete(String notificationId, int customerId);
}
