import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSource(this.secureStorage);

  static const String _sessionKey = 'USER_SESSION';

  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await secureStorage.write(key: _sessionKey, value: userJson);
  }

  Future<UserModel?> getUser() async {
    final userJson = await secureStorage.read(key: _sessionKey);
    if (userJson != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(userJson);
        return UserModel.fromJson(jsonMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearUser() async {
    await secureStorage.delete(key: _sessionKey);
  }
}
