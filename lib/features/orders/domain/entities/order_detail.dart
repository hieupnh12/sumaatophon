import 'package:equatable/equatable.dart';

class OrderCustomerInfo extends Equatable {
  final String name;
  final String phone;
  final String address;
  final String note;

  const OrderCustomerInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
  });

  @override
  List<Object?> get props => [name, phone, address, note];
}

class OrderPaymentInfo extends Equatable {
  final int totalItems;
  final String subtotal;
  final String discount;
  final String shippingFee;
  final String totalVat;
  final String amountPaid;
  final String amountRemaining;

  const OrderPaymentInfo({
    required this.totalItems,
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.totalVat,
    required this.amountPaid,
    required this.amountRemaining,
  });

  @override
  List<Object?> get props => [
        totalItems,
        subtotal,
        discount,
        shippingFee,
        totalVat,
        amountPaid,
        amountRemaining,
      ];
}

class OrderProductItem extends Equatable {
  final int id;
  final String name;
  final String price;
  final String warrantyUntil;
  final int quantity;
  final String image;

  const OrderProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.warrantyUntil,
    required this.quantity,
    required this.image,
  });

  @override
  List<Object?> get props => [id, name, price, warrantyUntil, quantity, image];
}

class OrderTimelineItem extends Equatable {
  final String title;
  final String? date;
  final bool isDone;

  const OrderTimelineItem({
    required this.title,
    this.date,
    required this.isDone,
  });

  @override
  List<Object?> get props => [title, date, isDone];
}

class OrderDetail extends Equatable {
  final String id;
  final String status;
  final String statusText;
  final String date;
  final String totalAmount;
  final bool isPaid;
  final OrderCustomerInfo customer;
  final OrderPaymentInfo paymentInfo;
  final List<OrderProductItem> items;
  final List<OrderTimelineItem> timeline;

  const OrderDetail({
    required this.id,
    required this.status,
    required this.statusText,
    required this.date,
    required this.totalAmount,
    required this.isPaid,
    required this.customer,
    required this.paymentInfo,
    required this.items,
    required this.timeline,
  });

  @override
  List<Object?> get props => [
        id,
        status,
        statusText,
        date,
        totalAmount,
        isPaid,
        customer,
        paymentInfo,
        items,
        timeline,
      ];
}
