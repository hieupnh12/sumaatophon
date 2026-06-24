import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_mock_datasource.dart';

class AuthException implements Exception {
  final String code;
  const AuthException(this.code);
  @override
  String toString() => 'AuthException: $code';
}

class PhoneConflictException implements Exception {
  final String message;
  const PhoneConflictException(this.message);
  @override
  String toString() => 'PhoneConflictException: $message';
}

/// DataSource gọi các API xác thực từ xa (qua Backend Node.js).
class AuthRemoteDataSource {
  final ApiClient apiClient;
  final AuthMockDataSource mockDataSource;

  AuthRemoteDataSource(this.apiClient, this.mockDataSource);

  Future<UserModel> syncAuth(String idToken) async {
    try {
      apiClient.firebaseToken = idToken;
      final response = await apiClient.post(ApiEndpoints.authSync);
      if (response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }
      throw const FormatException('Expected JSON response from authSync');
    } catch (e) {
      if (e is ApiException && e.body.contains('REQUIRE_PHONE_LINK')) {
        throw const AuthException('REQUIRE_PHONE_LINK');
      }
      throw Exception('Đồng bộ xác thực thất bại: $e');
    }
  }

  Future<String?> requestOtp(String phone) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.requestOtp,
        body: {'phone': phone},
      );
      if (response != null && response is Map && response.containsKey('devOtp')) {
        return response['devOtp'] as String;
      }
      return null;
    } catch (e) {
      throw Exception('Gửi mã OTP thất bại: $e');
    }
  }

  Future<UserModel> verifyOtp(String phone, String otp) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.verifyOtp,
        body: {'phone': phone, 'otp': otp},
      );
      if (response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }
      throw const FormatException('Expected JSON response from verifyOtp');
    } catch (e) {
      throw Exception('Xác thực OTP thất bại: $e');
    }
  }

  Future<UserModel> linkPhone(String phone, String otp, {bool force = false}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.linkPhone,
        body: {'phone': phone, 'otp': otp, 'force': force},
      );
      if (response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }
      throw const FormatException('Expected JSON response from linkPhone');
    } catch (e) {
      if (e is ApiException && e.body.contains('PHONE_CONFLICT')) {
        throw PhoneConflictException('PHONE_CONFLICT');
      }
      throw Exception('Liên kết SĐT thất bại: $e');
    }
  }

  Future<UserModel> updateProfile({
    required String customerId,
    required String name,
    String? gender,
    String? dob,
    String? address,
  }) async {
    try {
      final response = await apiClient.put(
        ApiEndpoints.profile,
        body: {
          'customerId': customerId,
          'name': name,
          'gender': gender,
          'dob': dob,
          'address': address,
        },
      );
      if (response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }
      throw const FormatException('Expected JSON response from updateProfile');
    } catch (e) {
      throw Exception('Cập nhật thông tin thất bại: $e');
    }
  }

  Future<UserEntity> login(String email, String password) {
    return mockDataSource.login(email, password);
  }

  Future<UserEntity> register(String name, String email, String password) {
    return mockDataSource.register(name, email, password);
  }
}
