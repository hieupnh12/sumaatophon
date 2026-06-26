import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource dataSource;

  ChatRepositoryImpl(this.dataSource);

  @override
  Stream<ChatMessageEntity> get messageStream => dataSource.messageStream;

  @override
  Stream<List<ChatThreadEntity>> get threadsStream => dataSource.threadsStream;

  @override
  Future<void> connect(UserEntity user) => dataSource.connect(user);

  @override
  Future<void> disconnect() => dataSource.disconnect();

  @override
  Future<List<ChatThreadEntity>> getThreads() => dataSource.getThreads();

  @override
  Future<ChatThreadEntity> getOrCreateMyThread(UserEntity user) =>
      dataSource.getOrCreateMyThread(user);

  @override
  Future<List<ChatMessageEntity>> getMessages({
    required String threadId,
    required UserEntity user,
  }) =>
      dataSource.getMessages(threadId: threadId, user: user);

  @override
  Future<void> joinThread(String threadId) => dataSource.joinThread(threadId);

  @override
  Future<ChatMessageEntity> sendMessage({
    required String threadId,
    required String text,
    String? imageUrl,
  }) =>
      dataSource.sendMessage(threadId: threadId, text: text, imageUrl: imageUrl);
}
