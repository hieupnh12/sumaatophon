import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String name, String email, String password);
  Future<UserEntity> syncAuth(String idToken);
  Future<String?> requestOtp(String phone);
  Future<UserEntity> verifyOtp(String phone, String otp);
  Future<UserEntity> linkPhone(String phone, String otp, {bool force = false});
  Future<UserEntity> updateProfile({
    required String customerId,
    required String name,
    String? gender,
    String? dob,
    String? address,
  });
  Future<void> logout();
}
