import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../bloc/chat_bloc.dart';

class ChatConversationPage extends StatefulWidget {
  final bool embedded;

  const ChatConversationPage({super.key, this.embedded = false});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessageEvent(text: text));
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (prev, curr) => prev.messages.length != curr.messages.length,
      listener: (_, __) => Future.delayed(const Duration(milliseconds: 100), _scrollToBottom),
      builder: (context, state) {
        final user = state.user;
        final thread = state.activeThread;
        final isSupportStaff = user?.canSupportChat ?? false;
        final title = isSupportStaff
            ? (thread?.userName ?? context.tr('chat_support'))
            : context.tr('chat_support');
        final subtitle = isSupportStaff ? thread?.userEmail : context.tr('chat_online');

        return Scaffold(
          appBar: widget.embedded ? null : AppBar(
            leading: isSupportStaff
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.read<ChatBloc>().add(const BackToInboxEvent()),
                  )
                : null,
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: isSupportStaff && thread?.userAvatar != null
                          ? NetworkImage(thread!.userAvatar!)
                          : null,
                      child: isSupportStaff && thread?.userAvatar != null
                          ? null
                          : Icon(Icons.support_agent_rounded, color: theme.colorScheme.primary),
                    ),
                    if (!isSupportStaff)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        subtitle ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSupportStaff
                              ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              if (widget.embedded)
                _EmbeddedChatHeader(
                  isSupportStaff: isSupportStaff,
                  title: title,
                  subtitle: subtitle ?? '',
                  isDark: isDark,
                ),
              if (state.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: state.messages.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('chat_empty'),
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final isMine = message.isMine(
                            userId: user?.id ?? '',
                            isSupportStaff: isSupportStaff,
                          );
                          return _buildChatBubble(message, isMine, theme, isDark);
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 8
                      : 14,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('chat_input_hint'),
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: state.isSending
                          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                          : theme.colorScheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: state.isSending ? null : _sendMessage,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: Center(
                            child: state.isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(
    ChatMessageEntity message,
    bool isMine,
    ThemeData theme,
    bool isDark,
  ) {
    final timeString = DateTimeUtils.formatHm(message.createdAt);
    const avatarSize = 32.0;
    const avatarGap = 8.0;
    const sideInset = avatarSize + avatarGap;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMine) const SizedBox(width: sideInset),
          if (!isMine) ...[
            _ChatAvatar(isStaff: true, theme: theme),
            const SizedBox(width: avatarGap),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.imageUrl != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    child: Image.network(
                      message.imageUrl!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMine
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMine
                        ? null
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    border: isMine
                        ? null
                        : Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMine
                          ? Colors.white
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isSeen ? Icons.done_all_rounded : Icons.check_rounded,
                          size: 14,
                          color: message.isSeen
                              ? theme.colorScheme.primary
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isMine) const SizedBox(width: sideInset),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final bool isStaff;
  final ThemeData theme;

  const _ChatAvatar({
    required this.isStaff,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isStaff
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.9),
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isStaff ? null : theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Icon(
        isStaff ? Icons.support_agent_rounded : Icons.person_rounded,
        size: 17,
        color: isStaff ? Colors.white : theme.colorScheme.primary,
      ),
    );
  }
}

class _EmbeddedChatHeader extends StatelessWidget {
  final bool isSupportStaff;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmbeddedChatHeader({
    required this.isSupportStaff,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          if (isSupportStaff)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.read<ChatBloc>().add(const BackToInboxEvent()),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.support_agent_rounded, color: theme.colorScheme.primary, size: 22),
              ),
              if (!isSupportStaff)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSupportStaff
                          ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                          : AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
