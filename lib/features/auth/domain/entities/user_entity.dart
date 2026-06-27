import 'package:equatable/equatable.dart';

enum UserRole { staff, user }

enum AccountType { customer, employee }

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final UserRole role;
  final AccountType accountType;
  final List<String> employeeRoles;
  final int? gender;
  final String? dob;
  final String? address;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.role = UserRole.user,
    this.accountType = AccountType.customer,
    this.employeeRoles = const [],
    this.gender,
    this.dob,
    this.address,
  });

  /// Nhân viên / admin trong DB — đều có thể mở inbox và trả lời khách.
  bool get canSupportChat => accountType == AccountType.employee;

  bool get isCustomer => accountType == AccountType.customer;

  /// Tài khoản khách thật trong DB (customer_id số), không phải guest/biometric.
  bool get canUseStaffChat {
    if (id == 'guest' || id == 'bio_user' || id.isEmpty) return false;
    return int.tryParse(id) != null;
  }

  /// Alias cho feature address (merge main).
  String? get phone => phoneNumber;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phoneNumber,
        avatarUrl,
        role,
        accountType,
        employeeRoles,
        gender,
        dob,
        address,
      ];
}
