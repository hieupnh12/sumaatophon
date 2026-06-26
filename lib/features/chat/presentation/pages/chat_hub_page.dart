import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../chatbot/presentation/pages/chatbot_page.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/chat_bloc.dart';
import 'admin_inbox_page.dart';
import 'chat_conversation_page.dart';

/// Concierge — 2 tab: Bot tư vấn | Chat nhân viên realtime.
class ChatHubPage extends StatefulWidget {
  const ChatHubPage({super.key});

  @override
  State<ChatHubPage> createState() => _ChatHubPageState();
}

class _ChatHubPageState extends State<ChatHubPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChatIfNeeded());
  }

  void _initChatIfNeeded() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState && authState.user.canUseStaffChat) {
      context.read<ChatBloc>().add(InitChatEvent(authState.user));
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) {
        if (curr is AuthenticatedState && prev is! AuthenticatedState) return true;
        if (curr is! AuthenticatedState && prev is AuthenticatedState) return true;
        if (curr is AuthenticatedState && prev is AuthenticatedState) {
          return curr.user.id != prev.user.id;
        }
        return false;
      },
      listener: (context, authState) {
        final chatBloc = context.read<ChatBloc>();
        if (authState is AuthenticatedState && authState.user.canUseStaffChat) {
          chatBloc.add(InitChatEvent(authState.user));
        } else {
          chatBloc.add(const DisconnectChatEvent());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('chat_support')),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.smart_toy_outlined),
                text: context.tr('chat_bot_tab'),
              ),
              Tab(
                icon: const Icon(Icons.support_agent_outlined),
                text: context.tr('chat_staff_tab'),
              ),
            ],
          ),
        ),
        // IndexedStack giữ state cả 2 tab (TabBarView hay dispose tab ẩn → mất tin bot).
        body: IndexedStack(
          index: _tabController.index,
          children: [
            ChatbotPage(
              key: const PageStorageKey('chatbot_tab'),
              onTransferToStaff: () => _tabController.animateTo(1),
            ),
            const _StaffChatTab(),
          ],
        ),
      ),
    );
  }
}

class _StaffChatTab extends StatelessWidget {
  const _StaffChatTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthenticatedState ||
            !authState.user.canUseStaffChat) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('chat_login_required'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(context.tr('login_btn')),
                  ),
                ],
              ),
            ),
          );
        }

        return BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.isLoading && state.messages.isEmpty && state.threads.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null && state.activeThread == null && !state.showInbox) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          context.read<ChatBloc>().add(InitChatEvent(authState.user));
                        },
                        child: Text(context.tr('chat_retry')),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.user?.canSupportChat == true && state.showInbox) {
              return const AdminInboxPage(embedded: true);
            }

            return const ChatConversationPage(embedded: true);
          },
        );
      },
    );
  }
}
