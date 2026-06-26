import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String province;
  final String ward;
  final String street;
  final String type; // 'home' or 'office'
  final bool isDefault;
  final String? receiverName;
  final String? receiverPhone;

  const Address({
    required this.id,
    required this.province,
    required this.ward,
    required this.street,
    required this.type,
    required this.isDefault,
    this.receiverName,
    this.receiverPhone,
  });

  @override
  List<Object?> get props => [id, province, ward, street, type, isDefault, receiverName, receiverPhone];

  String get fullAddress => '$street, $ward, $province';
}
