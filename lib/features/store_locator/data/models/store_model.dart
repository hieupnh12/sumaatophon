import '../../domain/entities/store_entity.dart';

class StoreModel extends StoreEntity {
  const StoreModel({
    required super.id,
    required super.name,
    required super.address,
    required super.phone,
    required super.latitude,
    required super.longitude,
    required super.openTime,
    super.distanceKm,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      openTime: json['openTime'] as String? ?? '',
      distanceKm: json['distanceKm'] == null ? null : _toDouble(json['distanceKm']),
    );
  }

  StoreEntity toEntity() => StoreEntity(
        id: id,
        name: name,
        address: address,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
        openTime: openTime,
        distanceKm: distanceKm,
      );

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
