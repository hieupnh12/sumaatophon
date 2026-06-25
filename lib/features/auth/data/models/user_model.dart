import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String role;
  final String accountType;
  final List<String> employeeRoles;
  final int? gender;
  final String? dob;
  final String? address;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    required this.accountType,
    this.employeeRoles = const [],
    this.gender,
    this.dob,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['employeeRoles'];
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      phoneNumber: (json['phoneNumber'] ?? json['phone']) as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'user',
      accountType: json['accountType'] as String? ?? 'customer',
      employeeRoles: rawRoles is List
          ? rawRoles.map((e) => e.toString()).toList()
          : const [],
      gender: _parseGender(json['gender']),
      dob: json['dob'] as String?,
      address: json['address'] as String?,
    );
  }

  UserEntity toEntity() {
    final isStaff = accountType == 'employee' || role == 'staff' || role == 'admin';
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      role: isStaff ? UserRole.staff : UserRole.user,
      accountType: accountType == 'employee' ? AccountType.employee : AccountType.customer,
      employeeRoles: employeeRoles,
      gender: gender,
      dob: dob,
      address: address,
    );
  }

  static int? _parseGender(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
