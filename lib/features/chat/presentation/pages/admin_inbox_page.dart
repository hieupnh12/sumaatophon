import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../bloc/chat_bloc.dart';

class AdminInboxPage extends StatelessWidget {
  final bool embedded;

  const AdminInboxPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state.threads.isEmpty) {
          return Center(
            child: Text(
              context.tr('chat_no_conversations'),
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.threads.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 72,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          itemBuilder: (context, index) {
            final thread = state.threads[index];
            return _ThreadTile(thread: thread);
          },
        );
      },
    );
    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('chat_admin_inbox'))),
      body: body,
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThreadEntity thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = thread.lastMessageAt != null
        ? DateTimeUtils.formatHm(thread.lastMessageAt!)
        : '';

    return ListTile(
      onTap: () => context.read<ChatBloc>().add(SelectThreadEvent(thread)),
      leading: CircleAvatar(
        backgroundImage:
            thread.userAvatar != null ? NetworkImage(thread.userAvatar!) : null,
        child: thread.userAvatar == null
            ? Text(thread.userName.isNotEmpty ? thread.userName[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(
        thread.userName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thread.userEmail.isNotEmpty || (thread.userPhone?.isNotEmpty ?? false))
            Text(
              [
                if (thread.userEmail.isNotEmpty) thread.userEmail,
                if (thread.userPhone?.isNotEmpty ?? false) thread.userPhone!,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          Text(
            thread.lastMessage ?? context.tr('chat_start_conversation'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          if (thread.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${thread.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
