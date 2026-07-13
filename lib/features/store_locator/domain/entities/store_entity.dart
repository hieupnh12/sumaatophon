import 'package:equatable/equatable.dart';

class StoreEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String openTime;
  final double? distanceKm;

  const StoreEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        latitude,
        longitude,
        openTime,
        distanceKm,
      ];
}
