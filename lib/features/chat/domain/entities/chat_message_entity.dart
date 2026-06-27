import 'package:equatable/equatable.dart';

enum MessageSenderRole { user, admin }

class ChatMessageEntity extends Equatable {
  final String id;
  final String threadId;
  final String senderId;
  final MessageSenderRole senderRole;
  final String text;
  final String? imageUrl;
  final bool isSeen;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.imageUrl,
    this.isSeen = false,
    required this.createdAt,
  });

  bool isMine({required String userId, required bool isSupportStaff}) {
    if (isSupportStaff) return senderRole == MessageSenderRole.admin;
    return senderId == userId;
  }

  @override
  List<Object?> get props =>
      [id, threadId, senderId, senderRole, text, imageUrl, isSeen, createdAt];
}
