import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/auth/auth_guard.dart';
import '../bloc/warranty_bloc.dart';
import '../bloc/warranty_event.dart';
import '../bloc/warranty_state.dart';
import '../widgets/warranty_item_card.dart';
import '../widgets/warranty_request_card.dart';
import '../../../../main.dart';

class WarrantyPage extends StatefulWidget {
  const WarrantyPage({super.key});

  @override
  State<WarrantyPage> createState() => _WarrantyPageState();
}

class _WarrantyPageState extends State<WarrantyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? _getCustomerId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState && isRealAuthenticatedUser(authState.user)) {
      return int.tryParse(authState.user.id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customerId = _getCustomerId(context);

    if (customerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('warranty_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Text(context.tr('warranty_empty_devices')),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<WarrantyBloc>()..add(LoadWarrantyData(customerId)),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(context.tr('warranty_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          bottom: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            tabs: [
              Tab(text: context.tr('warranty_my_devices')),
              Tab(text: context.tr('warranty_requests')),
            ],
          ),
        ),
        body: BlocConsumer<WarrantyBloc, WarrantyState>(
          listener: (context, state) {
            if (state is WarrantySubmitSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('warranty_submit_success')),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WarrantyLoading || state is WarrantyInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WarrantyError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.message,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<WarrantyBloc>().add(LoadWarrantyData(customerId)),
                      child: Text(context.tr('chat_retry')),
                    ),
                  ],
                ),
              );
            }

            if (state is WarrantyLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildMyDevicesTab(context, state, isDark, customerId),
                  _buildRequestsTab(context, state, isDark, customerId),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildMyDevicesTab(BuildContext context, WarrantyLoaded state, bool isDark, int customerId) {
    if (state.eligibleItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              context.tr('warranty_empty_devices'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<WarrantyBloc>().add(LoadWarrantyData(customerId)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.eligibleItems.length,
        itemBuilder: (context, index) {
          final item = state.eligibleItems[index];
          return WarrantyItemCard(item: item, customerId: customerId);
        },
      ),
    );
  }

  Widget _buildRequestsTab(BuildContext context, WarrantyLoaded state, bool isDark, int customerId) {
    if (state.warrantyRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              context.tr('warranty_empty_requests'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<WarrantyBloc>().add(LoadWarrantyData(customerId)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.warrantyRequests.length,
        itemBuilder: (context, index) {
          final request = state.warrantyRequests[index];
          return WarrantyRequestCard(request: request);
        },
      ),
    );
  }
}
