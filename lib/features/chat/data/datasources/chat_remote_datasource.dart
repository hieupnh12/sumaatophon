import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  Future<void>? _connecting;
  bool _useRestFallback = false;
  Timer? _pollTimer;
  String? _pollingThreadId;
  final Set<String> _knownMessageIds = {};

  final _messageController = StreamController<ChatMessageEntity>.broadcast();
  final _threadsController = StreamController<List<ChatThreadEntity>>.broadcast();

  ChatRemoteDataSource(this.apiClient);

  Stream<ChatMessageEntity> get messageStream => _messageController.stream;
  Stream<List<ChatThreadEntity>> get threadsStream => _threadsController.stream;
  bool get usesRestFallback => _useRestFallback;

  Future<void> connect(UserEntity user) async {
    if (!_useRestFallback && _socket?.connected == true && _user?.id == user.id) {
      return;
    }
    if (_connecting != null) {
      await _connecting;
      if ((!_useRestFallback && _socket?.connected == true || _useRestFallback) &&
          _user?.id == user.id) {
        return;
      }
    }

    _connecting = _connectInternal(user);
    try {
      await _connecting;
    } finally {
      _connecting = null;
    }
  }

  Future<void> _connectInternal(UserEntity user) async {
    await _disconnectSocket();
    _stopPolling();
    _useRestFallback = false;
    _pollingThreadId = null;
    _knownMessageIds.clear();
    _user = user;

    if (kDebugMode) {
      await ApiConfig.recheckBaseUrl();
    }

    try {
      await _connectSocket(user);
      if (kDebugMode) debugPrint('[Chat] Socket connected');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Chat] Socket failed → REST polling fallback: $e');
      }
      _useRestFallback = true;
      _startPolling();
    }
  }

  Future<void> _connectSocket(UserEntity user) async {
    final socketConfig = ApiConfig.socketConfig;
    if (kDebugMode) {
      debugPrint('[Chat] Socket.IO → ${socketConfig.origin}${socketConfig.path}');
    }

    await _preflightSocketHandshake(socketConfig);

    // Polling trước — ổn định qua nginx /mobile/ (websocket upgrade hay lỗi trên một số proxy).
    _socket = io.io(
      socketConfig.origin,
      io.OptionBuilder()
          .setPath(socketConfig.path)
          .setTransports(['polling', 'websocket'])
          .setTimeout(20000)
          .disableAutoConnect()
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
    final socket = _socket!;
    socket
      ..on('connect', (_) {
        if (!connected.isCompleted) connected.complete();
      })
      ..on('connect_error', (error) {
        if (kDebugMode) debugPrint('[Chat] connect_error: $error');
        if (!connected.isCompleted) {
          connected.completeError(
            ChatSocketException(
              code: ChatSocketErrorCode.timeout,
              socketUrl: '${socketConfig.origin}${socketConfig.path}',
            ),
          );
        }
      })
      ..on('error', (error) {
        if (!connected.isCompleted) {
          connected.completeError(
            ChatSocketException(
              code: ChatSocketErrorCode.timeout,
              socketUrl: '${socketConfig.origin}${socketConfig.path}',
            ),
          );
        }
      })
      ..on('disconnect', (reason) {
        if (!connected.isCompleted) {
          connected.completeError(
            ChatSocketException(
              code: ChatSocketErrorCode.notConnected,
              socketUrl: '${socketConfig.origin}${socketConfig.path}',
            ),
          );
        }
      })
      ..on('new_message', (data) {
        if (data is Map) {
          final message = ChatMessageModel.fromJson(
            Map<String, dynamic>.from(data),
          ).toEntity();
          _knownMessageIds.add(message.id);
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

    socket.connect();

    try {
      await connected.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      await _disconnectSocket();
      throw ChatSocketException(
        code: ChatSocketErrorCode.timeout,
        socketUrl: '${socketConfig.origin}${socketConfig.path}',
      );
    } catch (e) {
      if (e is ChatSocketException) rethrow;
      throw ChatSocketException(
        code: ChatSocketErrorCode.timeout,
        socketUrl: '${socketConfig.origin}${socketConfig.path}',
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollRest());
    unawaited(_pollRest());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollRest() async {
    final user = _user;
    if (user == null || !_useRestFallback) return;

    try {
      if (user.canSupportChat) {
        final threads = await getThreads();
        _threadsController.add(threads);
      }

      final threadId = _pollingThreadId;
      if (threadId == null) return;

      final messages = await getMessages(threadId: threadId, user: user);
      for (final message in messages) {
        if (_knownMessageIds.add(message.id)) {
          _messageController.add(message);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Chat] REST poll error: $e');
    }
  }

  Future<void> disconnect() async {
    _stopPolling();
    _useRestFallback = false;
    _pollingThreadId = null;
    _knownMessageIds.clear();
    _user = null;
    await _disconnectSocket();
  }

  Future<void> _disconnectSocket() async {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      if (socket.connected) socket.disconnect();
      socket.dispose();
    } catch (_) {
      // ignore cleanup errors
    }
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
    _pollingThreadId = threadId;
    if (_useRestFallback) {
      final user = _user;
      if (user != null) {
        final messages = await getMessages(threadId: threadId, user: user);
        _knownMessageIds
          ..clear()
          ..addAll(messages.map((m) => m.id));
      }
      return;
    }

    _ensureSocketConnected();
    final completer = Completer<void>();
    _socket!.emitWithAck('join_thread', {'threadId': threadId}, ack: (response) {
      if (response is Map && response['ok'] == true) {
        completer.complete();
      } else {
        completer.completeError(Exception('Failed to join thread'));
      }
    });
    try {
      await completer.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw ChatSocketException(code: ChatSocketErrorCode.ackTimeout);
    }
  }

  Future<String> uploadChatImage(String filePath) async {
    final data = await apiClient.postMultipart(
      ApiEndpoints.chatUploadImage,
      filePath: filePath,
    );
    final rawUrl = data is Map ? data['imageUrl'] as String? : null;
    if (rawUrl == null || rawUrl.isEmpty) {
      throw Exception('Upload failed');
    }
    return rawUrl;
  }

  Future<ChatMessageEntity> sendMessage({
    required String threadId,
    required String text,
    String? imageUrl,
  }) async {
    if (_useRestFallback) {
      return _sendMessageRest(
        threadId: threadId,
        text: text,
        imageUrl: imageUrl,
      );
    }

    _ensureSocketConnected();
    final completer = Completer<ChatMessageEntity>();
    _socket!.emitWithAck(
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
    try {
      final message = await completer.future.timeout(const Duration(seconds: 10));
      _knownMessageIds.add(message.id);
      return message;
    } on TimeoutException {
      throw ChatSocketException(code: ChatSocketErrorCode.ackTimeout);
    }
  }

  Future<ChatMessageEntity> _sendMessageRest({
    required String threadId,
    required String text,
    String? imageUrl,
  }) async {
    final user = _user;
    if (user == null) {
      throw ChatSocketException(code: ChatSocketErrorCode.notConnected);
    }

    final isStaff = user.canSupportChat;
    final data = await apiClient.post(
      ApiEndpoints.chatThreadMessages(threadId),
      queryParameters: isStaff
          ? {
              'role': 'staff',
              'accountType': 'employee',
              'userId': user.id,
              'userName': user.name,
            }
          : {
              'role': 'user',
              'customerId': user.id,
            },
      body: {
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (isStaff) ...{
          'staffId': user.id,
          'staffName': user.name,
        } else ...{
          'customerId': user.id,
        },
      },
    );

    final message =
        ChatMessageModel.fromJson(data as Map<String, dynamic>).toEntity();
    _knownMessageIds.add(message.id);
    _messageController.add(message);
    if (isStaff) {
      unawaited(_pollRest());
    }
    return message;
  }

  void _ensureSocketConnected() {
    if (_socket?.connected != true) {
      throw ChatSocketException(code: ChatSocketErrorCode.notConnected);
    }
  }

  /// Socket.IO polling handshake phải bắt đầu bằng `0{` — HTML/404 = nginx hoặc URL sai.
  static Future<void> _preflightSocketHandshake(ApiSocketConfig config) async {
    final uri = Uri.parse('${config.origin}${config.path}/')
        .replace(queryParameters: const {'EIO': '4', 'transport': 'polling'});
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatSocketException(
          code: ChatSocketErrorCode.badHandshake,
          statusCode: response.statusCode,
          socketUrl: '${config.origin}${config.path}',
        );
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));
      if (!body.startsWith('0{')) {
        throw ChatSocketException(
          code: ChatSocketErrorCode.badHandshake,
          socketUrl: '${config.origin}${config.path}',
        );
      }
    } on ChatSocketException {
      rethrow;
    } catch (_) {
      throw ChatSocketException(
        code: ChatSocketErrorCode.badHandshake,
        socketUrl: '${config.origin}${config.path}',
      );
    } finally {
      client.close(force: true);
    }
  }
}

enum ChatSocketErrorCode {
  timeout,
  ackTimeout,
  notConnected,
  badHandshake,
}

class ChatSocketException implements Exception {
  final ChatSocketErrorCode code;
  final String? socketUrl;
  final int? statusCode;

  const ChatSocketException({
    required this.code,
    this.socketUrl,
    this.statusCode,
  });

  @override
  String toString() => 'ChatSocketException($code, url=$socketUrl)';
}
