import 'package:flutter_bloc/flutter_bloc.dart';

enum SenderType { user, admin }

class ChatMessage {
  final String id;
  final String text;
  final SenderType sender;
  final DateTime timestamp;
  final bool isSeen;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isSeen = false,
    this.imageUrl,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    SenderType? sender,
    DateTime? timestamp,
    bool? isSeen,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

abstract class ChatBlocEvent {}

class LoadChatHistoryEvent extends ChatBlocEvent {}

class SendMessageEvent extends ChatBlocEvent {
  final String text;
  final String? imageUrl;
  SendMessageEvent({required this.text, this.imageUrl});
}

class ChatBlocState {
  final List<ChatMessage> messages;
  final bool isTyping;

  ChatBlocState({this.messages = const [], this.isTyping = false});

  ChatBlocState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) {
    return ChatBlocState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatBloc extends Bloc<ChatBlocEvent, ChatBlocState> {
  ChatBloc() : super(ChatBlocState()) {
    on<LoadChatHistoryEvent>((event, emit) {
      final history = [
        ChatMessage(
          id: '1',
          text: 'Xin chào! phoneShop có thể giúp gì cho bạn hôm nay?',
          sender: SenderType.admin,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isSeen: true,
        ),
      ];
      emit(state.copyWith(messages: history));
    });

    on<SendMessageEvent>((event, emit) async {
      // Add user message
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.text,
        sender: SenderType.user,
        timestamp: DateTime.now(),
        imageUrl: event.imageUrl,
        isSeen: false,
      );

      final currentMessages = List<ChatMessage>.from(state.messages)..add(newMessage);
      emit(state.copyWith(messages: currentMessages, isTyping: true));

      // Simulate bot processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mark user message as seen and add bot reply
      final updatedMessages = currentMessages.map((m) {
        if (m.sender == SenderType.user && !m.isSeen) {
          return m.copyWith(isSeen: true);
        }
        return m;
      }).toList();

      final botReply = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Cảm ơn bạn! Hệ thống đã ghi nhận. Tư vấn viên sẽ phản hồi bạn trong ít phút tới nhé.',
        sender: SenderType.admin,
        timestamp: DateTime.now(),
        isSeen: true,
      );
      
      updatedMessages.add(botReply);
      emit(state.copyWith(messages: updatedMessages, isTyping: false));
    });
  }
}
