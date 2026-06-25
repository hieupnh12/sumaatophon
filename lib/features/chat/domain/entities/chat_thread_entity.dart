import 'package:equatable/equatable.dart';

class ChatThreadEntity extends Equatable {
  final String id;
  final String userId;
  final String? customerId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String? userAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatThreadEntity({
    required this.id,
    required this.userId,
    this.customerId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.userAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        customerId,
        userName,
        userEmail,
        userPhone,
        userAvatar,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}
