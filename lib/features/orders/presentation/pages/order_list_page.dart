import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/order.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // TODO: get real customer id from AuthBloc. Using 33 for testing.
    context.read<OrderBloc>().add(const LoadOrdersEvent(33));
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
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          tabs: [
            Tab(text: context.tr('order_tab_all')),
            Tab(text: context.tr('order_tab_pending')),
            Tab(text: context.tr('order_tab_shipping')),
            Tab(text: context.tr('order_tab_completed')),
            Tab(text: context.tr('order_tab_cancelled')),
            Tab(text: context.tr('order_tab_return')),
          ],
        ),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OrderError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is OrdersLoaded) {
            final orders = state.orders;
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(isDark, context, 'all', orders),
                _buildOrderList(isDark, context, 'pending', orders),
                _buildOrderList(isDark, context, 'shipping', orders),
                _buildOrderList(isDark, context, 'completed', orders),
                _buildOrderList(isDark, context, 'cancelled', orders),
                _buildOrderList(isDark, context, 'return', orders),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderList(bool isDark, BuildContext context, String filter, List<Order> allOrders) {
    var filteredOrders = filter == 'all' ? allOrders : allOrders.where((o) => o.status == filter).toList();

    if (_startDate != null && _endDate != null) {
      final formatter = DateFormat('dd/MM/yyyy');
      filteredOrders = filteredOrders.where((o) {
        try {
          final orderDate = formatter.parse(o.date);
          return orderDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                 orderDate.isBefore(_endDate!.add(const Duration(days: 1)));
        } catch (_) {
          return true;
        }
      }).toList();
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDateRange: _startDate != null && _endDate != null
                  ? DateTimeRange(start: _startDate!, end: _endDate!)
                  : null,
            );
            if (picked != null) {
              setState(() {
                _startDate = picked.start;
                _endDate = picked.end;
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(_startDate), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                Icon(Icons.arrow_forward_rounded, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                Text(_formatDate(_endDate), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                Icon(Icons.calendar_today_outlined, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ],
            ),
          ),
        ),
        // Order List
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/empty_orders.png', width: 150, height: 150),
                      const SizedBox(height: 16),
                      Text(context.tr('order_empty'), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final statusColor = _getStatusColor(order.status);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => GetIt.I<OrderBloc>(),
                              child: OrderDetailPage(orderId: order.realId),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
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
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          text: 'Đơn hàng: ',
                                          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                                          children: [
                                            TextSpan(
                                              text: order.id,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          text: '${context.tr('order_date')} ',
                                          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                                          children: [
                                            TextSpan(
                                              text: order.date,
                                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    order.statusText,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Product Body
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: order.productImage.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(order.productImage, fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.product,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.productPrice,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      if (order.hasVat)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.cyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            context.tr('order_vat_issued'),
                                            style: const TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      if (order.otherItemsCount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            context.tr('order_other_products').replaceAll('%s', order.otherItemsCount.toString()),
                                            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('${context.tr('order_total_payment')} ', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
                                Text(order.total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.error)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                context.tr('order_view_detail'),
                                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'shipping':
        return Colors.blue;
      case 'completed':
        return const Color(0xFF229E54); // Green matches mockup
      case 'cancelled':
        return const Color(0xFFD32F2F); // Red matches mockup
      default:
        return Colors.grey;
    }
  }
}
