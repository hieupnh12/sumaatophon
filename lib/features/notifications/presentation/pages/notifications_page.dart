import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../chat/presentation/pages/chat_hub_page.dart';
import '../../../orders/presentation/bloc/order_bloc.dart';
import '../../../orders/presentation/pages/order_detail_page.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../domain/entities/app_notification.dart';
import '../notification_helpers.dart';
import '../bloc/notification_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() => reloadNotifications(context);

  int? _customerId(BuildContext context) => notificationCustomerId(context);

  void _onTapNotification(BuildContext context, AppNotification item) {
    final customerId = _customerId(context);
    if (customerId != null && !item.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationReadEvent(item.id, customerId));
    }

    switch (item.type) {
      case NotificationType.productNew:
        final productId = item.productId;
        if (productId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailPage(productId: productId)),
          );
        }
        break;
      case NotificationType.orderStatus:
        final orderId = item.orderId;
        if (orderId != null && customerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => GetIt.I<OrderBloc>(),
                child: OrderDetailPage(orderId: orderId),
              ),
            ),
          );
        }
        break;
      case NotificationType.chatMessage:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatHubPage(openStaffTab: true)),
        );
        break;
    }
  }

  int _unreadCount(List<AppNotification> items) => items.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) {
        if (curr is AuthenticatedState && prev is! AuthenticatedState) return true;
        if (curr is! AuthenticatedState && prev is AuthenticatedState) return true;
        if (curr is AuthenticatedState && prev is AuthenticatedState) {
          return curr.user.id != prev.user.id;
        }
        return false;
      },
      listener: (context, state) {
        if (state is! AuthenticatedState) {
          context.read<NotificationBloc>().add(ClearNotificationsEvent());
        } else {
          _reload();
        }
      },
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          final productItems = state.items.where((n) => n.type == NotificationType.productNew).toList();
          final orderItems = state.items
              .where((n) => n.type == NotificationType.orderStatus || n.type == NotificationType.chatMessage)
              .toList();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w700)),
              centerTitle: true,
              actions: [
                if (!state.requiresLogin && state.items.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      final customerId = _customerId(context);
                      if (customerId != null) {
                        context.read<NotificationBloc>().add(MarkAllNotificationsReadEvent(customerId));
                      }
                    },
                    child: const Text('Đọc tất cả'),
                  ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                tabs: [
                  Tab(
                    child: _TabLabel(
                      label: 'Sản phẩm mới',
                      unreadCount: _unreadCount(productItems),
                    ),
                  ),
                  Tab(
                    child: _TabLabel(
                      label: 'Đơn hàng',
                      unreadCount: _unreadCount(orderItems),
                    ),
                  ),
                ],
              ),
            ),
            body: state.requiresLogin
                ? _LoginRequired(onLogin: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  })
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _NotificationList(
                        items: productItems,
                        isLoading: state.isLoading,
                        error: state.error,
                        emptyIcon: Icons.phone_iphone_rounded,
                        emptyTitle: 'Chưa có sản phẩm mới',
                        emptySubtitle: 'Khi có sản phẩm được duyệt lên kệ, bạn sẽ thấy thông báo ở đây.',
                        showTypeChip: false,
                        onReload: _reload,
                        onTap: (item) => _onTapNotification(context, item),
                      ),
                      _NotificationList(
                        items: orderItems,
                        isLoading: state.isLoading,
                        error: state.error,
                        emptyIcon: Icons.local_shipping_outlined,
                        emptyTitle: 'Chưa có thông báo đơn hàng',
                        emptySubtitle: 'Cập nhật trạng thái đơn, thanh toán và tin nhắn nhân viên sẽ hiện ở đây.',
                        showTypeChip: true,
                        onReload: _reload,
                        onTap: (item) => _onTapNotification(context, item),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final int unreadCount;

  const _TabLabel({required this.label, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            unreadCount > 99 ? '99+' : '$unreadCount',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> items;
  final bool isLoading;
  final String? error;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showTypeChip;
  final VoidCallback onReload;
  final void Function(AppNotification item) onTap;

  const _NotificationList({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.showTypeChip,
    required this.onReload,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onReload, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(emptyTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _NotificationTile(
            item: items[index],
            showTypeChip: showTypeChip,
            onTap: () => onTap(items[index]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final bool showTypeChip;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.showTypeChip,
    required this.onTap,
  });

  String get _typeLabel {
    switch (item.type) {
      case NotificationType.productNew:
        return 'Sản phẩm mới';
      case NotificationType.orderStatus:
        return 'Đơn hàng';
      case NotificationType.chatMessage:
        return 'Hỗ trợ';
    }
  }

  IconData get _icon {
    switch (item.type) {
      case NotificationType.productNew:
        return Icons.phone_iphone_rounded;
      case NotificationType.orderStatus:
        return Icons.local_shipping_outlined;
      case NotificationType.chatMessage:
        return Icons.support_agent_outlined;
    }
  }

  Color _iconColor() {
    switch (item.type) {
      case NotificationType.productNew:
        return AppColors.primary;
      case NotificationType.orderStatus:
        return Colors.orange;
      case NotificationType.chatMessage:
        return Colors.blue;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (now.difference(local).inDays == 0) {
      return DateFormat('HH:mm').format(local);
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat('EEE, HH:mm', 'vi').format(local);
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _iconColor();

    return Material(
      color: item.isRead
          ? null
          : (isDark ? AppColors.primary.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.06)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (showTypeChip)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _typeLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                            ),
                          ),
                        if (showTypeChip) const Spacer(),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    if (showTypeChip) const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (item.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginRequired({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_outlined, size: 56, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'Đăng nhập để xem thông báo sản phẩm mới và đơn hàng',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onLogin, child: Text(context.tr('login_btn'))),
          ],
        ),
      ),
    );
  }
}
