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
  Future<UserEntity> login(String email, String password) async {
    final user = await remoteDataSource.login(email, password);
    await saveSession(user);
    return user;
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    final user = await remoteDataSource.register(name, email, password);
    await saveSession(user);
    return user;
  }

  @override
  Future<UserEntity> syncAuth(String idToken) async {
    final user = await remoteDataSource.syncAuth(idToken);
    await saveSession(user);
    return user;
  }

  @override
  Future<String?> requestOtp(String phone) {
    return remoteDataSource.requestOtp(phone);
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    final user = await remoteDataSource.verifyOtp(phone, otp);
    await saveSession(user);
    return user;
  }

  @override
  Future<UserEntity> linkPhone(String phone, String otp, {bool force = false}) async {
    final userModel = await remoteDataSource.linkPhone(phone, otp, force: force);
    await saveSession(userModel);
    return userModel;
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
    await saveSession(userModel);
    return userModel;
  }

  @override
  Future<void> logout() async {
    await clearSession();
  }

  @override
  Future<void> saveSession(UserEntity user) async {
    UserModel model;
    if (user is UserModel) {
      model = user;
    } else {
      model = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        avatarUrl: user.avatarUrl,
        phone: user.phone,
        gender: user.gender,
        dob: user.dob,
        address: user.address,
      );
    }
    await localDataSource.saveUser(model);
  }

  @override
  Future<UserEntity?> getSession() async {
    return await localDataSource.getUser();
  }

  @override
  Future<void> clearSession() async {
    await localDataSource.clearUser();
  }
}

