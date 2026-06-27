import 'package:equatable/equatable.dart';

enum NotificationType { productNew, orderStatus, chatMessage }

class AppNotification extends Equatable {
  final String id;
  final String? customerId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    this.customerId,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    this.isRead = false,
    this.createdAt,
  });

  int? get orderId => int.tryParse('${payload?['orderId']}');
  String? get productId => payload?['productId']?.toString();
  String? get threadId => payload?['threadId']?.toString();

  @override
  List<Object?> get props => [id, customerId, type, title, body, payload, isRead, createdAt];
}
