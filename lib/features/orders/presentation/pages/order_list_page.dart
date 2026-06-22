import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.tr('profile_orders_title')),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          tabs: [
            Tab(text: context.tr('order_tab_all')),
            Tab(text: context.tr('order_tab_pending')),
            Tab(text: context.tr('order_tab_shipping')),
            Tab(text: context.tr('order_tab_completed')),
            Tab(text: context.tr('order_tab_cancelled')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(isDark, context, 'all'),
          _buildOrderList(isDark, context, 'pending'),
          _buildOrderList(isDark, context, 'shipping'),
          _buildOrderList(isDark, context, 'completed'),
          _buildOrderList(isDark, context, 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildOrderList(bool isDark, BuildContext context, String filter) {
    // Dummy Data
    final orders = [
      {
        'id': 'ORD-123456',
        'status': 'pending',
        'statusText': context.tr('order_tab_pending'),
        'items': 2,
        'total': '24,990,000 đ',
        'date': '19/06/2026',
        'product': 'iPhone 15 Pro Max 256GB'
      },
      {
        'id': 'ORD-123457',
        'status': 'shipping',
        'statusText': context.tr('order_tab_shipping'),
        'items': 1,
        'total': '15,490,000 đ',
        'date': '15/06/2026',
        'product': 'Samsung Galaxy S24'
      },
      {
        'id': 'ORD-123458',
        'status': 'completed',
        'statusText': context.tr('order_tab_completed'),
        'items': 3,
        'total': '1,290,000 đ',
        'date': '10/06/2026',
        'product': 'AirPods Pro 2'
      },
    ];

    final filteredOrders = filter == 'all' ? orders : orders.where((o) => o['status'] == filter).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            const SizedBox(height: 16),
            Text(context.tr('order_empty'), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    order['statusText'] as String,
                    style: TextStyle(
                      color: _getStatusColor(order['status'] as String),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 24),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_iphone_rounded, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['product'] as String, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(order['date'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order['items']} ${context.tr('order_item_count')}', style: const TextStyle(color: Colors.grey)),
                  Row(
                    children: [
                      Text('${context.tr('order_total_amount')}: ', style: const TextStyle(color: Colors.grey)),
                      Text(order['total'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'shipping':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}
