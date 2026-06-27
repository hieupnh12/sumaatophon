import '../../domain/entities/app_notification.dart';

class NotificationModel {
  final String id;
  final String? customerId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    this.customerId,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      customerId: json['customerId']?.toString(),
      type: _parseType(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static NotificationType _parseType(String? raw) {
    switch (raw) {
      case 'product_new':
        return NotificationType.productNew;
      case 'order_status':
        return NotificationType.orderStatus;
      case 'chat_message':
        return NotificationType.chatMessage;
      default:
        return NotificationType.orderStatus;
    }
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      customerId: customerId,
      type: type,
      title: title,
      body: body,
      payload: payload,
      isRead: isRead,
      createdAt: createdAt,
    );
  }
}
