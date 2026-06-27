import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/order_detail.dart';
import '../bloc/order_bloc.dart';
import '../utils/order_display_helpers.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return context.tr('order_status_pending');
      case 'shipping':
        return context.tr('order_status_shipping');
      case 'completed':
        return context.tr('order_status_completed');
      case 'cancelled':
        return context.tr('order_status_cancelled');
      case 'return':
        return context.tr('order_status_return');
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    // TODO: get real customer id from AuthBloc. Using 33 for testing.
    context.read<OrderBloc>().add(LoadOrderDetailEvent(widget.orderId, 33));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(context.tr('order_detail_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OrderError) {
            return Center(child: Text(context.tr('order_error_load'), style: const TextStyle(color: Colors.red)));
          } else if (state is OrderDetailLoaded) {
            final detail = state.orderDetail;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOverviewSection(context, isDark, detail),
                  const SizedBox(height: 16),
                  if (detail.status != 'cancelled') ...[
                    _buildTimelineSection(context, isDark, detail.timeline),
                    const SizedBox(height: 16),
                  ],
                  _buildCustomerInfoSection(context, isDark, detail.customer),
                  const SizedBox(height: 16),
                  _buildPaymentInfoSection(context, isDark, detail.paymentInfo),
                  const SizedBox(height: 16),
                  _buildSupportInfoSection(context, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, bool isDark, OrderDetail detail) {
    Color statusColor = Colors.blue;
    if (detail.status == 'pending') statusColor = AppColors.warning;
    if (detail.status == 'completed') statusColor = const Color(0xFF229E54);
    if (detail.status == 'cancelled') statusColor = const Color(0xFFD32F2F);

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context.tr('order_overview'), isDark),
          const SizedBox(height: 12),
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
                        text: '${context.tr('order_label')} ',
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: detail.id,
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
                            text: detail.date,
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
                  _statusLabel(context, detail.status),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...detail.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == detail.items.length - 1;
            return _buildProductItem(
              context: context,
              isDark: isDark,
              name: item.name,
              price: item.price,
              warranty: item.warrantyUntil,
              quantity: item.quantity,
              image: item.image,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductItem({
    required BuildContext context,
    required bool isDark,
    required String name,
    required String price,
    required String warranty,
    required int quantity,
    required String image,
    required bool showDivider,
  }) {
    return Column(
      children: [
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
              child: image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(image, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderProductLabel(context, name), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${context.tr('order_warranty_until')} $warranty', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('${context.tr('order_quantity')} $quantity', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(context.tr('order_buy_again'), style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        if (showDivider) Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 24),
      ],
    );
  }

  Widget _buildTimelineSection(BuildContext context, bool isDark, List<OrderTimelineItem> timeline) {
    if (timeline.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: timeline.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return _buildTimelineItem(
            orderTimelineLabel(context, step: item.step, title: item.title),
            isDark,
            isFirst: idx == 0,
            isLast: idx == timeline.length - 1,
            isDone: item.isDone,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineItem(String title, bool isDark, {required bool isFirst, required bool isLast, required bool isDone}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst) Container(width: 2, height: 16, color: isDone ? Colors.blue : Colors.grey.shade300),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? Colors.blue : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            if (!isLast) Container(width: 2, height: 24, color: isDone ? Colors.blue : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: isDone ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoSection(BuildContext context, bool isDark, OrderCustomerInfo customer) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context.tr('order_customer_info'), isDark),
          const SizedBox(height: 16),
          _buildInfoRow(context.tr('order_customer_name'), orderCustomerName(context, customer.name), isDark),
          _buildDivider(isDark),
          _buildInfoRow(context.tr('order_customer_phone'), customer.phone, isDark),
          _buildDivider(isDark),
          _buildInfoRow(context.tr('order_customer_address'), customer.address, isDark),
          _buildDivider(isDark),
          _buildInfoRow(context.tr('order_customer_note'), orderCustomerNote(customer.note), isDark),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoSection(BuildContext context, bool isDark, OrderPaymentInfo paymentInfo) {
    return _buildCard(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSectionTitle(context.tr('order_payment_info'), isDark),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9),
            width: double.infinity,
            child: Text(context.tr('order_product_info'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(context.tr('order_product_count_label'), paymentInfo.totalItems.toString(), isDark),
                _buildDivider(isDark),
                _buildInfoRow(context.tr('order_subtotal'), paymentInfo.subtotal, isDark),
                _buildDivider(isDark),
                _buildInfoRow(context.tr('order_discount'), paymentInfo.discount, isDark, valueColor: const Color(0xFF229E54)),
                _buildDivider(isDark),
                _buildInfoRow(context.tr('order_shipping_fee'), orderShippingFeeLabel(context, paymentInfo.shippingFee), isDark, valueColor: const Color(0xFF229E54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9),
            width: double.infinity,
            child: Text(context.tr('order_payment_section'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRowMultiLine(context.tr('order_total_amount_vat'), paymentInfo.totalVat, isDark, valueColor: AppColors.error, valueSize: 16, isBold: true),
                _buildDivider(isDark),
                _buildInfoRowMultiLine(context.tr('order_amount_paid'), paymentInfo.amountPaid, isDark),
                _buildDivider(isDark),
                _buildInfoRowMultiLine(context.tr('order_amount_remaining'), paymentInfo.amountRemaining, isDark, valueColor: AppColors.error, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportInfoSection(BuildContext context, bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context.tr('order_support_info'), isDark),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('order_store_address'), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(context.tr('order_store_address_value'), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          _buildDivider(isDark),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.phone_in_talk_outlined, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('order_contact_phone'), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('0982481094', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      const url = 'tel:0982481094';
                      if (await canLaunchUrlString(url)) {
                        await launchUrlString(url);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_in_talk_outlined, color: AppColors.error, size: 16),
                          const SizedBox(width: 4),
                          Text(context.tr('order_contact_btn'), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildDivider(isDark),
          GestureDetector(
            onTap: () async {
              const url = 'https://zalo.me/0982481094';
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: const Center(child: Text('Zalo', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 8),
                Text(context.tr('order_contact_zalo'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor ?? (isDark ? Colors.white : Colors.black), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowMultiLine(String label, String value, bool isDark, {Color? valueColor, double valueSize = 13, bool isBold = false}) {
    final parts = label.split('\n');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(parts[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (parts.length > 1)
                Text(parts[1], style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 11)),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isDark ? Colors.white : Colors.black),
            fontSize: valueSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
    );
  }
}
