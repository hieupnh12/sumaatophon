import 'package:equatable/equatable.dart';

class WarrantyItem extends Equatable {
  final int orderId;
  final String productVersionId;
  final String name;
  final String image;
  final String warrantyUntil;
  final int warrantyPeriod;

  const WarrantyItem({
    required this.orderId,
    required this.productVersionId,
    required this.name,
    required this.image,
    required this.warrantyUntil,
    required this.warrantyPeriod,
  });

  @override
  List<Object?> get props => [
        orderId,
        productVersionId,
        name,
        image,
        warrantyUntil,
        warrantyPeriod,
      ];
}
