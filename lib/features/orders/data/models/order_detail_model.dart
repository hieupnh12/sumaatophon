import '../../domain/entities/order_detail.dart';

class OrderCustomerInfoModel extends OrderCustomerInfo {
  const OrderCustomerInfoModel({
    required super.name,
    required super.phone,
    required super.address,
    required super.note,
  });

  factory OrderCustomerInfoModel.fromJson(Map<String, dynamic> json) {
    return OrderCustomerInfoModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class OrderPaymentInfoModel extends OrderPaymentInfo {
  const OrderPaymentInfoModel({
    required super.totalItems,
    required super.subtotal,
    required super.discount,
    required super.shippingFee,
    required super.totalVat,
    required super.amountPaid,
    required super.amountRemaining,
  });

  factory OrderPaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return OrderPaymentInfoModel(
      totalItems: json['totalItems'] as int? ?? 0,
      subtotal: json['subtotal'] as String? ?? '0đ',
      discount: json['discount'] as String? ?? '0đ',
      shippingFee: json['shippingFee'] as String? ?? '0đ',
      totalVat: json['totalVat'] as String? ?? '0đ',
      amountPaid: json['amountPaid'] as String? ?? '0đ',
      amountRemaining: json['amountRemaining'] as String? ?? '0đ',
    );
  }
}

class OrderProductItemModel extends OrderProductItem {
  const OrderProductItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.warrantyUntil,
    required super.quantity,
    required super.image,
  });

  factory OrderProductItemModel.fromJson(Map<String, dynamic> json) {
    return OrderProductItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: json['price'] as String? ?? '0đ',
      warrantyUntil: json['warrantyUntil'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      image: json['image'] as String? ?? '',
    );
  }
}

class OrderTimelineItemModel extends OrderTimelineItem {
  const OrderTimelineItemModel({
    super.step,
    super.title,
    super.date,
    required super.isDone,
  });

  factory OrderTimelineItemModel.fromJson(Map<String, dynamic> json) {
    return OrderTimelineItemModel(
      step: json['step'] as String?,
      title: json['title'] as String? ?? '',
      date: json['date'] as String?,
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}

class OrderDetailModel extends OrderDetail {
  const OrderDetailModel({
    required super.id,
    required super.status,
    required super.statusText,
    required super.date,
    required super.totalAmount,
    required super.isPaid,
    required super.customer,
    required super.paymentInfo,
    required super.items,
    required super.timeline,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      statusText: json['statusText'] as String? ?? '',
      date: json['date'] as String? ?? '',
      totalAmount: json['totalAmount'] as String? ?? '0đ',
      isPaid: json['isPaid'] as bool? ?? false,
      customer: OrderCustomerInfoModel.fromJson(json['customer'] as Map<String, dynamic>? ?? {}),
      paymentInfo: OrderPaymentInfoModel.fromJson(json['paymentInfo'] as Map<String, dynamic>? ?? {}),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderProductItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => OrderTimelineItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
