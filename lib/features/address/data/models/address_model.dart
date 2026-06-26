import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.province,
    required super.ward,
    required super.street,
    required super.type,
    required super.isDefault,
    super.receiverName,
    super.receiverPhone,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      province: json['province'] as String,
      ward: json['ward'] as String,
      street: json['street'] as String,
      type: json['type'] as String,
      isDefault: json['isDefault'] as bool,
      receiverName: json['receiverName'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'province': province,
      'ward': ward,
      'street': street,
      'type': type,
      'isDefault': isDefault,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
    };
  }

  factory AddressModel.fromEntity(Address entity) {
    return AddressModel(
      id: entity.id,
      province: entity.province,
      ward: entity.ward,
      street: entity.street,
      type: entity.type,
      isDefault: entity.isDefault,
      receiverName: entity.receiverName,
      receiverPhone: entity.receiverPhone,
    );
  }
}
