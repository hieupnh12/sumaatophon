import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../bloc/notification_bloc.dart';

class NotificationBadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double iconSize;
  final VoidCallback? onPressed;

  const NotificationBadgeIcon({
    super.key,
    required this.icon,
    this.color,
    this.iconSize = 24,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final count = state.unreadCount;
        final child = Icon(icon, color: color, size: iconSize);

        if (onPressed != null) {
          return IconButton(
            onPressed: onPressed,
            icon: _badge(count, child),
          );
        }
        return _badge(count, child);
      },
    );
  }

  Widget _badge(int count, Widget child) {
    return badges.Badge(
      showBadge: count > 0,
      badgeContent: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: AppColors.error,
        padding: EdgeInsets.all(4),
      ),
      child: child,
    );
  }
}
