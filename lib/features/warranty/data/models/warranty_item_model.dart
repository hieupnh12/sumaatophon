import '../../domain/entities/warranty_item.dart';

class WarrantyItemModel extends WarrantyItem {
  const WarrantyItemModel({
    required super.orderId,
    required super.productVersionId,
    required super.name,
    required super.image,
    required super.warrantyUntil,
    required super.warrantyPeriod,
  });

  factory WarrantyItemModel.fromJson(Map<String, dynamic> json) {
    return WarrantyItemModel(
      orderId: json['orderId'] ?? 0,
      productVersionId: json['productVersionId'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      warrantyUntil: json['warrantyUntil'] ?? '',
      warrantyPeriod: json['warrantyPeriod'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'productVersionId': productVersionId,
      'name': name,
      'image': image,
      'warrantyUntil': warrantyUntil,
      'warrantyPeriod': warrantyPeriod,
    };
  }
}
