import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../../domain/repositories/chat_repository.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class InitChatEvent extends ChatEvent {
  final UserEntity user;
  const InitChatEvent(this.user);

  @override
  List<Object?> get props => [user];
}

class SelectThreadEvent extends ChatEvent {
  final ChatThreadEntity thread;
  const SelectThreadEvent(this.thread);

  @override
  List<Object?> get props => [thread];
}

class BackToInboxEvent extends ChatEvent {
  const BackToInboxEvent();
}

class SendMessageEvent extends ChatEvent {
  final String text;
  final String? imageUrl;

  const SendMessageEvent({required this.text, this.imageUrl});

  @override
  List<Object?> get props => [text, imageUrl];
}

class _NewMessageEvent extends ChatEvent {
  final ChatMessageEntity message;
  const _NewMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class _ThreadsUpdatedEvent extends ChatEvent {
  final List<ChatThreadEntity> threads;
  const _ThreadsUpdatedEvent(this.threads);

  @override
  List<Object?> get props => [threads];
}

class DisconnectChatEvent extends ChatEvent {
  const DisconnectChatEvent();
}

class ChatState extends Equatable {
  final UserEntity? user;
  final List<ChatThreadEntity> threads;
  final ChatThreadEntity? activeThread;
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final bool isSending;
  final bool showInbox;
  final String? error;

  const ChatState({
    this.user,
    this.threads = const [],
    this.activeThread,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.showInbox = false,
    this.error,
  });

  ChatState copyWith({
    UserEntity? user,
    List<ChatThreadEntity>? threads,
    ChatThreadEntity? activeThread,
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    bool? showInbox,
    String? error,
    bool clearError = false,
    bool clearActiveThread = false,
  }) {
    return ChatState(
      user: user ?? this.user,
      threads: threads ?? this.threads,
      activeThread: clearActiveThread ? null : (activeThread ?? this.activeThread),
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      showInbox: showInbox ?? this.showInbox,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [user, threads, activeThread, messages, isLoading, isSending, showInbox, error];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  StreamSubscription<ChatMessageEntity>? _messageSub;
  StreamSubscription<List<ChatThreadEntity>>? _threadsSub;

  ChatBloc({required this.repository}) : super(const ChatState()) {
    on<InitChatEvent>(_onInit);
    on<SelectThreadEvent>(_onSelectThread);
    on<BackToInboxEvent>(_onBackToInbox);
    on<SendMessageEvent>(_onSendMessage);
    on<_NewMessageEvent>(_onNewMessage);
    on<_ThreadsUpdatedEvent>(_onThreadsUpdated);
    on<DisconnectChatEvent>(_onDisconnect);
  }

  Future<void> _onInit(InitChatEvent event, Emitter<ChatState> emit) async {
    if (!event.user.canUseStaffChat) {
      emit(const ChatState());
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true, user: event.user));

    try {
      await _messageSub?.cancel();
      await _threadsSub?.cancel();
      await repository.connect(event.user);

      _messageSub = repository.messageStream.listen(
        (message) => add(_NewMessageEvent(message)),
      );

      if (event.user.canSupportChat) {
        _threadsSub = repository.threadsStream.listen(
          (threads) => add(_ThreadsUpdatedEvent(threads)),
        );
        final threads = await repository.getThreads();
        emit(state.copyWith(
          isLoading: false,
          threads: threads,
          showInbox: true,
          clearActiveThread: true,
          messages: const [],
        ));
      } else {
        final thread = await repository.getOrCreateMyThread(event.user);
        final messages = await repository.getMessages(
          threadId: thread.id,
          user: event.user,
        );
        emit(state.copyWith(
          isLoading: false,
          activeThread: thread,
          messages: messages,
          showInbox: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSelectThread(SelectThreadEvent event, Emitter<ChatState> emit) async {
    final user = state.user;
    if (user == null) return;

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await repository.joinThread(event.thread.id);
      final messages = await repository.getMessages(
        threadId: event.thread.id,
        user: user,
      );
      emit(state.copyWith(
        isLoading: false,
        activeThread: event.thread,
        messages: messages,
        showInbox: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onBackToInbox(BackToInboxEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      showInbox: true,
      clearActiveThread: true,
      messages: const [],
    ));
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final thread = state.activeThread;
    if (thread == null || event.text.trim().isEmpty) return;

    emit(state.copyWith(isSending: true, clearError: true));
    try {
      final message = await repository.sendMessage(
        threadId: thread.id,
        text: event.text.trim(),
        imageUrl: event.imageUrl,
      );
      final exists = state.messages.any((m) => m.id == message.id);
      if (!exists) {
        emit(state.copyWith(
          isSending: false,
          messages: [...state.messages, message],
        ));
      } else {
        emit(state.copyWith(isSending: false));
      }
    } catch (e) {
      emit(state.copyWith(isSending: false, error: e.toString()));
    }
  }

  void _onNewMessage(_NewMessageEvent event, Emitter<ChatState> emit) {
    if (state.activeThread?.id != event.message.threadId) return;
    if (state.messages.any((m) => m.id == event.message.id)) return;
    emit(state.copyWith(messages: [...state.messages, event.message]));
  }

  void _onThreadsUpdated(_ThreadsUpdatedEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(threads: event.threads));
  }

  Future<void> _onDisconnect(DisconnectChatEvent event, Emitter<ChatState> emit) async {
    await _messageSub?.cancel();
    await _threadsSub?.cancel();
    await repository.disconnect();
    emit(const ChatState());
  }

  @override
  Future<void> close() async {
    await _messageSub?.cancel();
    await _threadsSub?.cancel();
    await repository.disconnect();
    return super.close();
  }
}
