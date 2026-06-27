import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../models/chat_models.dart';

class ChatRemoteDataSource {
  final ApiClient apiClient;
  io.Socket? _socket;
  UserEntity? _user;

  final _messageController = StreamController<ChatMessageEntity>.broadcast();
  final _threadsController = StreamController<List<ChatThreadEntity>>.broadcast();

  ChatRemoteDataSource(this.apiClient);

  Stream<ChatMessageEntity> get messageStream => _messageController.stream;
  Stream<List<ChatThreadEntity>> get threadsStream => _threadsController.stream;

  Future<void> connect(UserEntity user) async {
    if (_socket?.connected == true && _user?.id == user.id) return;

    await disconnect();
    _user = user;

    final socketConfig = ApiConfig.socketConfig;

    _socket = io.io(
      socketConfig.origin,
      io.OptionBuilder()
          .setPath(socketConfig.path)
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setQuery({
            'userId': user.id,
            'role': user.canSupportChat ? 'staff' : 'user',
            'accountType': user.accountType.name,
            'userName': user.name,
            'userEmail': user.email,
            if (user.phoneNumber != null) 'userPhone': user.phoneNumber!,
            if (user.avatarUrl != null) 'userAvatar': user.avatarUrl!,
          })
          .build(),
    );

    final connected = Completer<void>();
    _socket!
      ..on('connect', (_) {
        if (!connected.isCompleted) connected.complete();
      })
      ..on('connect_error', (error) {
        if (!connected.isCompleted) {
          connected.completeError(Exception('Socket connect failed: $error'));
        }
      })
      ..on('new_message', (data) {
        if (data is Map) {
          final message = ChatMessageModel.fromJson(
            Map<String, dynamic>.from(data),
          ).toEntity();
          _messageController.add(message);
        }
      })
      ..on('threads_updated', (data) {
        if (data is List) {
          final threads = data
              .map((item) => ChatThreadModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ).toEntity())
              .toList();
          _threadsController.add(threads);
        }
      });

    await connected.future.timeout(const Duration(seconds: 12));
  }

  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
    _user = null;
  }

  Future<List<ChatThreadEntity>> getThreads() async {
    final data = await apiClient.get(
      ApiEndpoints.chatThreads,
      queryParameters: {'role': 'staff', 'accountType': 'employee'},
    );
    if (data is! List) return [];
    return data
        .map((item) =>
            ChatThreadModel.fromJson(item as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<ChatThreadEntity> getOrCreateMyThread(UserEntity user) async {
    final data = await apiClient.get(
      ApiEndpoints.chatThreadsMine,
      queryParameters: {
        'customerId': user.id,
      },
    );
    return ChatThreadModel.fromJson(data as Map<String, dynamic>).toEntity();
  }

  Future<List<ChatMessageEntity>> getMessages({
    required String threadId,
    required UserEntity user,
  }) async {
    final data = await apiClient.get(
      ApiEndpoints.chatThreadMessages(threadId),
      queryParameters: {'role': user.canSupportChat ? 'staff' : 'user'},
    );
    if (data is! List) return [];
    return data
        .map((item) =>
            ChatMessageModel.fromJson(item as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<void> joinThread(String threadId) async {
    final completer = Completer<void>();
    _socket?.emitWithAck('join_thread', {'threadId': threadId}, ack: (response) {
      if (response is Map && response['ok'] == true) {
        completer.complete();
      } else {
        completer.completeError(Exception('Failed to join thread'));
      }
    });
    return completer.future.timeout(const Duration(seconds: 10));
  }

  Future<ChatMessageEntity> sendMessage({
    required String threadId,
    required String text,
    String? imageUrl,
  }) async {
    final completer = Completer<ChatMessageEntity>();
    _socket?.emitWithAck(
      'send_message',
      {
        'threadId': threadId,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
      ack: (response) {
        if (response is Map && response['ok'] == true && response['message'] != null) {
          completer.complete(
            ChatMessageModel.fromJson(
              Map<String, dynamic>.from(response['message'] as Map),
            ).toEntity(),
          );
        } else {
          completer.completeError(
            Exception(response is Map ? response['message'] ?? 'Send failed' : 'Send failed'),
          );
        }
      },
    );
    return completer.future.timeout(const Duration(seconds: 10));
  }
}
