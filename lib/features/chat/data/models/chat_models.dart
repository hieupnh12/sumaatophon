import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';

class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String senderRole;
  final String text;
  final String? imageUrl;
  final bool isSeen;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.imageUrl,
    required this.isSeen,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      senderId: json['senderId'] as String,
      senderRole: json['senderRole'] as String,
      text: json['text'] as String,
      imageUrl: json['imageUrl'] as String?,
      isSeen: json['isSeen'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );
  }

  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      threadId: threadId,
      senderId: senderId,
      senderRole: senderRole == 'admin'
          ? MessageSenderRole.admin
          : MessageSenderRole.user,
      text: text,
      imageUrl: imageUrl,
      isSeen: isSeen,
      createdAt: DateTimeUtils.parseApiUtc(createdAt),
    );
  }
}

class ChatThreadModel {
  final String id;
  final String userId;
  final String? customerId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String? userAvatar;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  ChatThreadModel({
    required this.id,
    required this.userId,
    this.customerId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.userAvatar,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      customerId: json['customerId'] as String?,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String? ?? '',
      userPhone: json['userPhone'] as String?,
      userAvatar: json['userAvatar'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  ChatThreadEntity toEntity() {
    return ChatThreadEntity(
      id: id,
      userId: userId,
      customerId: customerId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      userAvatar: userAvatar,
      lastMessage: lastMessage,
      lastMessageAt: DateTimeUtils.tryParseApiUtc(lastMessageAt),
      unreadCount: unreadCount,
    );
  }
}
