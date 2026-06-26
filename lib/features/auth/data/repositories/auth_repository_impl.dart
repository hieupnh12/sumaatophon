import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<UserEntity> login(String email, String password) {
    return dataSource.login(email, password);
  }

  @override
  Future<UserEntity> register(String name, String email, String password) {
    return dataSource.register(name, email, password);
  }

  @override
  Future<UserEntity> syncAuth(String idToken) async {
    final userModel = await dataSource.syncAuth(idToken);
    return userModel.toEntity();
  }

  @override
  Future<String?> requestOtp(String phone) {
    return dataSource.requestOtp(phone);
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    final userModel = await dataSource.verifyOtp(phone, otp);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> linkPhone(String phone, String otp, {bool force = false}) async {
    final userModel = await dataSource.linkPhone(phone, otp, force: force);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> updateProfile({
    required String customerId,
    required String name,
    String? gender,
    String? dob,
    String? address,
  }) async {
    final userModel = await dataSource.updateProfile(
      customerId: customerId,
      name: name,
      gender: gender,
      dob: dob,
      address: address,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    // Không cần thực hiện logic nếu không có dataSource.logout()
  }
}
