import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_mock_datasource.dart';

/// DataSource gọi các API xác thực từ xa (qua Backend Node.js).
class AuthRemoteDataSource {
  final ApiClient apiClient;
  final AuthMockDataSource mockDataSource;

  AuthRemoteDataSource(this.apiClient, this.mockDataSource);

  Future<UserEntity> loginWithGoogle(String idToken) async {
    final response = await apiClient.post(
      ApiEndpoints.googleLogin,
      body: {'idToken': idToken},
    );
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw const FormatException('Expected JSON response from Google login');
  }

  // Giữ lại luồng Mock cho đăng nhập/đăng ký bằng email/password thông thường
  Future<UserEntity> login(String email, String password) {
    return mockDataSource.login(email, password);
  }

  Future<UserEntity> register(String name, String email, String password) {
    return mockDataSource.register(name, email, password);
  }
}
