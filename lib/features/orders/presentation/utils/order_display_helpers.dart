import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/design_system/app_colors.dart';

String orderProductLabel(BuildContext context, String product) {
  if (product.isEmpty || product == 'Sản phẩm') {
    return context.tr('order_default_product');
  }
  return product;
}

String orderCustomerName(BuildContext context, String name) {
  if (name.isEmpty || name == 'Khách hàng') {
    return context.tr('order_default_customer');
  }
  return name;
}

String orderShippingFeeLabel(BuildContext context, String fee) {
  if (fee == 'free' || fee == 'Miễn phí') {
    return context.tr('order_shipping_free');
  }
  return fee;
}

String orderTimelineLabel(BuildContext context, {String? step, String title = ''}) {
  switch (step) {
    case 'placed':
      return context.tr('order_timeline_placed');
    case 'ready':
      return context.tr('order_timeline_ready');
    case 'delivered':
      return context.tr('order_timeline_delivered');
    default:
      switch (title) {
        case 'Đặt hàng thành công':
          return context.tr('order_timeline_placed');
        case 'Sẵn sàng':
          return context.tr('order_timeline_ready');
        case 'Đã nhận hàng':
          return context.tr('order_timeline_delivered');
        default:
          return title;
      }
  }
}

String orderCustomerNote(String rawNote) {
  if (rawNote.isEmpty || rawNote == '-') return '-';

  final parts = rawNote
      .split('|')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty && !p.toLowerCase().startsWith('receiptemail:'))
      .toList();

  if (parts.length >= 4 &&
      (parts[2] == 'storePickup' || parts[2] == 'homeDelivery')) {
    if (parts.length > 4) {
      return parts.sublist(4).join(' | ');
    }
    return '-';
  }

  return rawNote;
}

String orderStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'pending':
      return context.tr('order_status_pending');
    case 'paid':
      return context.tr('order_status_paid');
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

Color orderStatusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.warning;
    case 'paid':
      return Colors.blueAccent; // Choose a color for paid, perhaps distinct from shipping
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
