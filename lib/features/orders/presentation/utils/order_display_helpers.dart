import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

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
