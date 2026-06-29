import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/language_cubit.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/vietnamese_ime_text_field.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../data/datasources/chatbot_remote_datasource.dart';

class ChatbotMessage {
  final String text;
  final bool isUser;
  final bool suggestStaff;
  final List<ChatbotProductSuggestion> products;
  final DateTime createdAt;

  ChatbotMessage({
    required this.text,
    required this.isUser,
    this.suggestStaff = false,
    this.products = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ChatbotPage extends StatefulWidget {
  final VoidCallback? onTransferToStaff;

  const ChatbotPage({super.key, this.onTransferToStaff});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _messages = ValueNotifier<List<ChatbotMessage>>([]);
  final _isSending = ValueNotifier<bool>(false);
  bool _welcomeAdded = false;
  List<String> _suggestions = [];

  static const _fallbackSuggestions = [
    'Shop có những máy gì?',
    'Gợi ý điện thoại giá rẻ còn hàng',
    'Gợi ý máy chơi game pin trâu',
    'Điện thoại dưới 10 triệu còn hàng',
    'Giá iPhone 17 Pro Max bao nhiêu?',
    'iPhone 17 Pro Max còn hàng không?',
    'Giá Samsung Galaxy S24',
    'So sánh iPhone và Samsung',
    'Xiaomi nào đáng mua hiện nay?',
    'Máy nào pin tốt shop đang có?',
    'Shop có trả góp không?',
    'Chính sách bảo hành đổi trả',
    'Giao hàng mất bao lâu?',
  ];

  static const _stripSuggestionCount = 6;

  @override
  void initState() {
    super.initState();
    _suggestions = List<String>.from(_fallbackSuggestions);
    _loadSuggestions();
  }

  bool get _showSuggestionBar => !_messages.value.any((m) => m.isUser);

  List<String> get _stripSuggestions => _suggestions.take(_stripSuggestionCount).toList();

  Future<void> _loadSuggestions() async {
    try {
      final list = await GetIt.I<ChatbotRemoteDataSource>().fetchSuggestions();
      if (!mounted) return;
      setState(() => _suggestions = list.isNotEmpty ? list : _fallbackSuggestions);
    } catch (_) {
      if (!mounted) return;
      setState(() => _suggestions = _fallbackSuggestions);
    }
  }

  @override
  bool get wantKeepAlive => true;

  String _tr(String key) {
    final lang = context.read<LanguageCubit>().state;
    return AppLocalizations.translate(key, lang);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_welcomeAdded) {
      _welcomeAdded = true;
      _messages.value = [
        ChatbotMessage(
          text: _tr('chatbot_welcome'),
          isUser: false,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _messages.dispose();
    _isSending.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openAllSuggestions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.6;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.quiz_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ctx.tr('chatbot_suggestions_label'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final q = _suggestions[index];
                      return Material(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _send(q);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q,
                                    style: const TextStyle(fontSize: 15, height: 1.35),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionStrip(ThemeData theme, bool isDark, {required bool isSending}) {
    if (!_showSuggestionBar || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMore = _suggestions.length > _stripSuggestionCount;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('chatbot_suggestions_label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (hasMore)
                  InkWell(
                    onTap: isSending ? null : _openAllSuggestions,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        context.tr('chatbot_suggestions_more'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stripSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final q = _stripSuggestions[index];
                return _SuggestionChip(
                  label: q,
                  enabled: !isSending,
                  isDark: isDark,
                  onTap: () => _send(q),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending.value) return;

    final current = List<ChatbotMessage>.from(_messages.value);
    current.add(ChatbotMessage(text: trimmed, isUser: true));
    _messages.value = current;
    _isSending.value = true;
    Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);

    try {
      final ds = GetIt.I<ChatbotRemoteDataSource>();
      final history = current
          .where((m) => m != current.last)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'text': m.text,
              })
          .toList();
      final result = await ds.ask(trimmed, history: history);
      if (!mounted) return;
      final updated = List<ChatbotMessage>.from(_messages.value);
      updated.add(ChatbotMessage(
        text: result.reply,
        isUser: false,
        suggestStaff: result.suggestStaff,
        products: result.products,
      ));
      _messages.value = updated;
      _isSending.value = false;
      Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    } catch (e) {
      if (!mounted) return;
      final updated = List<ChatbotMessage>.from(_messages.value);
      updated.add(ChatbotMessage(
        text: _tr('chatbot_error'),
        isUser: false,
        suggestStaff: true,
      ));
      _messages.value = updated;
      _isSending.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatBg = isDark ? AppColors.darkBackground : AppColors.lightSurface;

    return ColoredBox(
      color: chatBg,
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isSending,
              builder: (context, isSending, _) {
                return ValueListenableBuilder<List<ChatbotMessage>>(
                  valueListenable: _messages,
                  builder: (context, messages, __) {
                    final itemCount = messages.length + (isSending ? 1 : 0);
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _TypingBubble(isDark: isDark);
                        }
                        return _Bubble(
                          message: messages[index],
                          isDark: isDark,
                          isFirstBotMessage: index == 0 && !messages[index].isUser,
                          onTransferToStaff: widget.onTransferToStaff,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          DecoratedBox(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<List<ChatbotMessage>>(
                  valueListenable: _messages,
                  builder: (context, messages, _) {
                    final showBar = !messages.any((m) => m.isUser);
                    if (!showBar || _suggestions.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ValueListenableBuilder<bool>(
                      valueListenable: _isSending,
                      builder: (context, isSending, _) {
                        return _buildSuggestionStrip(theme, isDark, isSending: isSending);
                      },
                    );
                  },
                ),
                _ChatbotComposer(
                  key: const ValueKey('chatbot_composer_stable'),
                  isDark: isDark,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxChipWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w500,
              color: enabled
                  ? (isDark ? AppColors.darkText : AppColors.lightText)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final bool isDark;

  const _TypingBubble({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _BotAvatar(theme: theme),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35 + i * 0.15),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  final ThemeData theme;

  const _BotAvatar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy_rounded, size: 17, color: Colors.white),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatbotMessage message;
  final bool isDark;
  final bool isFirstBotMessage;
  final VoidCallback? onTransferToStaff;

  const _Bubble({
    required this.message,
    required this.isDark,
    this.isFirstBotMessage = false,
    this.onTransferToStaff,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final timeString = DateTimeUtils.formatHm(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _BotAvatar(theme: theme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && isFirstBotMessage)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'phoneShop Bot',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? AppColors.darkText : AppColors.lightText),
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      if (!isUser && message.products.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ProductSuggestionsRow(products: message.products, isDark: isDark),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4, right: 4),
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (!isUser && message.suggestStaff && onTransferToStaff != null) ...[
                  const SizedBox(height: 6),
                  FilledButton.tonalIcon(
                    onPressed: onTransferToStaff,
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: Text(context.tr('chatbot_transfer_staff')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ProductSuggestionsRow extends StatelessWidget {
  final List<ChatbotProductSuggestion> products;
  final bool isDark;

  const _ProductSuggestionsRow({
    required this.products,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          final inStock = product.stockQuantity > 0;

          return Material(
            color: isDark ? AppColors.darkSurface : const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(
                      productId: product.id,
                      heroImageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : null,
                    ),
                  ),
                );
              },
              child: SizedBox(
                width: 132,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF0F0F2),
                        padding: const EdgeInsets.all(8),
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.smartphone_rounded,
                                  size: 36,
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              )
                            : Icon(
                                Icons.smartphone_rounded,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.25),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priceFormat.format(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inStock
                                ? context.tr('chatbot_product_in_stock')
                                : context.tr('chatbot_product_out_of_stock'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: inStock ? const Color(0xFF229E54) : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatbotComposer extends StatefulWidget {
  final bool isDark;
  final Future<void> Function(String text) onSend;

  const _ChatbotComposer({
    super.key,
    required this.isDark,
    required this.onSend,
  });

  @override
  State<_ChatbotComposer> createState() => _ChatbotComposerState();
}

class _ChatbotComposerState extends State<_ChatbotComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = readComposedText(_controller);
    if (text == null || _isSending) return;
    clearComposedText(_controller);
    setState(() => _isSending = true);
    try {
      await widget.onSend(text);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 8
            : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: VietnameseImeTextField(
              fieldKey: 'chatbot_ime_input',
              controller: _controller,
              style: TextStyle(
                fontSize: 15,
                color: widget.isDark ? AppColors.darkText : AppColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: context.tr('chatbot_input_hint'),
                hintStyle: TextStyle(
                  color: widget.isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                filled: true,
                fillColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                    color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isSending
                  ? null
                  : LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        AppColors.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isSending
                  ? (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  : null,
              boxShadow: _isSending
                  ? null
                  : [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSending ? null : _submit,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
