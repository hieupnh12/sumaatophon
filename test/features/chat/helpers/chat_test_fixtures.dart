import 'package:sumaatophon/features/auth/domain/entities/user_entity.dart';
import 'package:sumaatophon/features/chat/domain/entities/chat_thread_entity.dart';
import 'package:sumaatophon/features/chat/presentation/bloc/chat_bloc.dart';

/// Dữ liệu mẫu dùng chung cho test chat.
class ChatTestFixtures {
  static const testUser = UserEntity(
    id: '43',
    name: 'Test Customer',
    email: 'test@example.com',
  );

  static const testThread = ChatThreadEntity(
    id: 'thread-1',
    userId: '43',
    customerId: '43',
    userName: 'Hỗ trợ',
    userEmail: 'support@phoneshop.vn',
  );

  static const defaultChatState = ChatState(
    user: testUser,
    activeThread: testThread,
  );
}
