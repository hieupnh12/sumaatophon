import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  final String? phone;
  final int? gender;
  final String? dob;
  final String? address;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.gender,
    this.dob,
    this.address,
  });

  @override
  List<Object?> get props => [id, name, email, avatarUrl, phone, gender, dob, address];
}
