import '../entities/chat_message_entity.dart';
import '../entities/chat_thread_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ChatRepository {
  Stream<ChatMessageEntity> get messageStream;
  Stream<List<ChatThreadEntity>> get threadsStream;

  Future<void> connect(UserEntity user);
  Future<void> disconnect();

  Future<List<ChatThreadEntity>> getThreads();
  Future<ChatThreadEntity> getOrCreateMyThread(UserEntity user);
  Future<List<ChatMessageEntity>> getMessages({
    required String threadId,
    required UserEntity user,
  });

  Future<void> joinThread(String threadId);
  Future<ChatMessageEntity> sendMessage({
    required String threadId,
    required String text,
    String? imageUrl,
  });
}
