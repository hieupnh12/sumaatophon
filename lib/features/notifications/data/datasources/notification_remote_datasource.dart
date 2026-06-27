import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<({List<NotificationModel> items, int unreadCount})> fetchNotifications(int customerId);
  Future<void> markRead(String notificationId, int customerId);
  Future<void> markAllRead(int customerId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl(this.apiClient);

  @override
  Future<({List<NotificationModel> items, int unreadCount})> fetchNotifications(int customerId) async {
    final response = await apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'customerId': customerId},
    );

    final map = response as Map<String, dynamic>;
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final unreadCount = (map['unreadCount'] as num?)?.toInt() ?? 0;
    return (items: items, unreadCount: unreadCount);
  }

  @override
  Future<void> markRead(String notificationId, int customerId) async {
    await apiClient.patch(
      ApiEndpoints.notificationRead(notificationId),
      body: {'customerId': customerId},
    );
  }

  @override
  Future<void> markAllRead(int customerId) async {
    await apiClient.patch(
      ApiEndpoints.notificationsReadAll,
      body: {'customerId': customerId},
    );
  }
}
