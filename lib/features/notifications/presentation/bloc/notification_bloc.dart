import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {
  final int? customerId;
  final bool silent;

  const LoadNotificationsEvent({this.customerId, this.silent = false});

  @override
  List<Object?> get props => [customerId, silent];
}

class MarkNotificationReadEvent extends NotificationEvent {
  final String notificationId;
  final int customerId;
  const MarkNotificationReadEvent(this.notificationId, this.customerId);
  @override
  List<Object?> get props => [notificationId, customerId];
}

class MarkAllNotificationsReadEvent extends NotificationEvent {
  final int customerId;
  const MarkAllNotificationsReadEvent(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

class ClearNotificationsEvent extends NotificationEvent {}

class NotificationState extends Equatable {
  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool requiresLogin;

  const NotificationState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.requiresLogin = false,
  });

  NotificationState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? requiresLogin,
    bool clearError = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      requiresLogin: requiresLogin ?? this.requiresLogin,
    );
  }

  @override
  List<Object?> get props => [items, unreadCount, isLoading, error, requiresLogin];
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc({required this.repository}) : super(const NotificationState()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllRead);
    on<ClearNotificationsEvent>(_onClear);
  }

  Future<void> _onLoad(LoadNotificationsEvent event, Emitter<NotificationState> emit) async {
    final customerId = event.customerId;
    if (customerId == null) {
      emit(const NotificationState(requiresLogin: true, items: [], unreadCount: 0));
      return;
    }

    emit(state.copyWith(
      isLoading: !event.silent || state.items.isEmpty,
      clearError: true,
      requiresLogin: false,
    ));
    try {
      final result = await repository.getNotifications(customerId);
      emit(NotificationState(
        items: result.items,
        unreadCount: result.unreadCount,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onMarkRead(MarkNotificationReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await repository.markRead(event.notificationId, event.customerId);
      final items = state.items.map((n) {
        if (n.id == event.notificationId) {
          return AppNotification(
            id: n.id,
            customerId: n.customerId,
            type: n.type,
            title: n.title,
            body: n.body,
            payload: n.payload,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      final unread = items.where((n) => !n.isRead).length;
      emit(state.copyWith(items: items, unreadCount: unread));
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(MarkAllNotificationsReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await repository.markAllRead(event.customerId);
      final items = state.items
          .map((n) => AppNotification(
                id: n.id,
                customerId: n.customerId,
                type: n.type,
                title: n.title,
                body: n.body,
                payload: n.payload,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      emit(state.copyWith(items: items, unreadCount: 0));
    } catch (_) {}
  }

  void _onClear(ClearNotificationsEvent event, Emitter<NotificationState> emit) {
    emit(const NotificationState(requiresLogin: true));
  }
}
