import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../domain/entities/app_notification.dart';
import 'bloc/notification_bloc.dart';

int? notificationCustomerId(BuildContext context) {
  final auth = context.read<AuthBloc>().state;
  if (auth is AuthenticatedState && auth.user.canUseStaffChat) {
    return int.tryParse(auth.user.id);
  }
  return null;
}

void reloadNotifications(BuildContext context, {bool silent = false}) {
  final customerId = notificationCustomerId(context);
  context.read<NotificationBloc>().add(
        LoadNotificationsEvent(customerId: customerId, silent: silent),
      );
}

Future<void> registerPushNotifications(BuildContext context) async {
  final customerId = notificationCustomerId(context);
  if (customerId == null) {
    debugPrint('[FCM] skip register: no customerId');
    return;
  }
  try {
    final token = await PushNotificationService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[FCM] skip register: getToken returned null (check Google Play on emulator)');
      return;
    }
    await PushNotificationService.registerWithBackend(
      GetIt.I<ApiClient>(),
      customerId,
    );
    debugPrint('[FCM] registered for customer $customerId');
  } catch (e) {
    debugPrint('[FCM] register failed: $e');
  }
}

Future<void> unregisterPushNotifications(BuildContext context) async {
  final customerId = notificationCustomerId(context);
  try {
    await PushNotificationService.unregisterWithBackend(
      GetIt.I<ApiClient>(),
      customerId: customerId,
    );
  } catch (e) {
    debugPrint('[FCM] unregister failed: $e');
  }
}

void showFreshNotificationsAsBanner(
  NotificationState? previous,
  NotificationState current,
) {
  if (previous == null || current.isLoading || current.requiresLogin) return;
  final prevIds = previous.items.map((e) => e.id).toSet();
  final fresh = current.items
      .where((n) => !prevIds.contains(n.id) && !n.isRead && n.type != NotificationType.orderStatus)
      .toList();
  if (fresh.isEmpty) return;
  final n = fresh.first;
  PushNotificationService.showLocal(
    title: n.title,
    body: n.body,
    id: n.id.hashCode,
  );
}
