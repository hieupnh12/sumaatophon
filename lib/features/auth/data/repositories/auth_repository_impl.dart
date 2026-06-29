import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);



  @override
  Future<UserEntity> syncAuth(String idToken) async {
    final userModel = await remoteDataSource.syncAuth(idToken);
    await saveSession(userModel.toEntity());
    return userModel.toEntity();
  }

  @override
  Future<String?> requestOtp(String phone) {
    return remoteDataSource.requestOtp(phone);
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    final userModel = await remoteDataSource.verifyOtp(phone, otp);
    await saveSession(userModel.toEntity());
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> linkPhone(String phone, String otp, {bool force = false}) async {
    final userModel = await remoteDataSource.linkPhone(phone, otp, force: force);
    await saveSession(userModel.toEntity());
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
    final userModel = await remoteDataSource.updateProfile(
      customerId: customerId,
      name: name,
      gender: gender,
      dob: dob,
      address: address,
    );
    await saveSession(userModel.toEntity());
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    await clearSession();
  }

  @override
  Future<void> saveSession(UserEntity user) async {
    final model = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      phoneNumber: user.phoneNumber,
      gender: user.gender,
      dob: user.dob,
      address: user.address,
      role: user.role == UserRole.staff ? 'staff' : 'user',
      accountType: user.accountType == AccountType.employee ? 'employee' : 'customer',
      employeeRoles: user.employeeRoles,
    );
    await localDataSource.saveUser(model);
  }

  @override
  Future<UserEntity?> getSession() async {
    final model = await localDataSource.getUser();
    return model?.toEntity();
  }

  @override
  Future<void> clearSession() async {
    await localDataSource.clearUser();
  }
}
