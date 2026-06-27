import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final int realId;
  final String status;
  final String statusText;
  final int items;
  final String total;
  final String date;
  final String product;
  final String productPrice;
  final bool hasVat;
  final int otherItemsCount;
  final String productImage;

  const Order({
    required this.id,
    required this.realId,
    required this.status,
    required this.statusText,
    required this.items,
    required this.total,
    required this.date,
    required this.product,
    required this.productPrice,
    required this.hasVat,
    required this.otherItemsCount,
    required this.productImage,
  });

  @override
  List<Object?> get props => [
        id,
        realId,
        status,
        statusText,
        items,
        total,
        date,
        product,
        productPrice,
        hasVat,
        otherItemsCount,
        productImage,
      ];
}
