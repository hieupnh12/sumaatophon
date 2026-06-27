import '../../domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.realId,
    required super.status,
    required super.statusText,
    required super.items,
    required super.total,
    required super.date,
    required super.product,
    required super.productPrice,
    required super.hasVat,
    required super.otherItemsCount,
    required super.productImage,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      realId: json['realId'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      statusText: json['statusText'] as String? ?? '',
      items: json['items'] as int? ?? 0,
      total: json['total'] as String? ?? '0đ',
      date: json['date'] as String? ?? '',
      product: json['product'] as String? ?? '',
      productPrice: json['productPrice'] as String? ?? '0đ',
      hasVat: json['hasVat'] as bool? ?? false,
      otherItemsCount: json['otherItemsCount'] as int? ?? 0,
      productImage: json['productImage'] as String? ?? '',
    );
  }
}
