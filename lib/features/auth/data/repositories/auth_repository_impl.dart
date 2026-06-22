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
  Future<UserEntity> loginWithGoogle(String idToken) {
    return dataSource.loginWithGoogle(idToken);
  }
}
