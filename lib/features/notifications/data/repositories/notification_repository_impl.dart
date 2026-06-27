import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remote;

  NotificationRepositoryImpl(this.remote);

  @override
  Future<({List<AppNotification> items, int unreadCount})> getNotifications(int customerId) async {
    final result = await remote.fetchNotifications(customerId);
    return (
      items: result.items.map((m) => m.toEntity()).toList(),
      unreadCount: result.unreadCount,
    );
  }

  @override
  Future<void> markRead(String notificationId, int customerId) {
    return remote.markRead(notificationId, customerId);
  }

  @override
  Future<void> markAllRead(int customerId) {
    return remote.markAllRead(customerId);
  }
}
