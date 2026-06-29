import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/vietnamese_ime_text_field.dart';
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
    final text = readComposedText(_messageController);
    if (text == null) return;

    context.read<ChatBloc>().add(SendMessageEvent(text: text));
    clearComposedText(_messageController);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final caption = readComposedText(_messageController);
      if (caption != null) clearComposedText(_messageController);

      context.read<ChatBloc>().add(
            SendImageMessageEvent(
              filePath: picked.path,
              caption: caption,
            ),
          );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('chat_image_picker_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, curr) =>
          prev.messages.length != curr.messages.length ||
          (prev.error != curr.error && curr.error != null),
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      },
      child: Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                leading: BlocSelector<ChatBloc, ChatState, bool>(
                  selector: (s) => s.user?.canSupportChat ?? false,
                  builder: (context, isSupportStaff) {
                    if (!isSupportStaff) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.read<ChatBloc>().add(const BackToInboxEvent()),
                    );
                  },
                ),
                title: BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (p, c) => p.user != c.user || p.activeThread != c.activeThread,
                  builder: (context, state) {
                    final user = state.user;
                    final thread = state.activeThread;
                    final isSupportStaff = user?.canSupportChat ?? false;
                    final title = isSupportStaff
                        ? (thread?.userName ?? context.tr('chat_support'))
                        : context.tr('chat_support');
                    final subtitle =
                        isSupportStaff ? thread?.userEmail : context.tr('chat_online');

                    return Row(
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
                                  : Icon(Icons.support_agent_rounded,
                                      color: theme.colorScheme.primary),
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
                                      color: isDark
                                          ? AppColors.darkBackground
                                          : AppColors.lightBackground,
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
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                subtitle ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSupportStaff
                                      ? (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary)
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
        body: Column(
          children: [
            if (widget.embedded)
              BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (p, c) => p.user != c.user || p.activeThread != c.activeThread,
                builder: (context, state) {
                  final user = state.user;
                  final isSupportStaff = user?.canSupportChat ?? false;
                  final title = isSupportStaff
                      ? (state.activeThread?.userName ?? context.tr('chat_support'))
                      : context.tr('chat_support');
                  final subtitle =
                      isSupportStaff ? state.activeThread?.userEmail : context.tr('chat_online');
                  return _EmbeddedChatHeader(
                    isSupportStaff: isSupportStaff,
                    title: title,
                    subtitle: subtitle ?? '',
                    isDark: isDark,
                  );
                },
              ),
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (p, c) => p.isLoading != c.isLoading,
              builder: (context, state) {
                return state.isLoading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : const SizedBox.shrink();
              },
            ),
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (p, c) => p.messages != c.messages,
                builder: (context, state) {
                  final user = state.user;
                  final isSupportStaff = user?.canSupportChat ?? false;

                  if (state.messages.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr('chat_empty'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
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
                  );
                },
              ),
            ),
            _ChatComposerBar(
              key: const ValueKey('staff_chat_composer'),
              controller: _messageController,
              isDark: isDark,
              onSend: _sendMessage,
              onAttachImage: _pickAndSendImage,
            ),
          ],
        ),
      ),
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
                    margin: EdgeInsets.only(bottom: message.hasVisibleText ? 4 : 0),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    child: Image.network(
                      message.imageUrl!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 200,
                        height: 120,
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                if (message.hasVisibleText)
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

class _ChatComposerBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onAttachImage;

  const _ChatComposerBar({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onSend,
    required this.onAttachImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          BlocSelector<ChatBloc, ChatState, bool>(
            selector: (state) => state.isSending,
            builder: (context, isSending) {
              return Material(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isSending ? null : onAttachImage,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: isSending
                          ? (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                          : theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: VietnameseImeTextField(
              fieldKey: 'staff_chat_input',
              controller: controller,
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
            ),
          ),
          const SizedBox(width: 8),
          BlocSelector<ChatBloc, ChatState, bool>(
            selector: (state) => state.isSending,
            builder: (context, isSending) {
              return Material(
                color: isSending
                    ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    : theme.colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isSending ? null : onSend,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: isSending
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
              );
            },
          ),
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
