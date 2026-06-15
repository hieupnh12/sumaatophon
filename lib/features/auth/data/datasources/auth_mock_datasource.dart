import '../../domain/entities/user_entity.dart';

class AuthMockDataSource {
  // Mock Database
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'u1',
      'name': 'John Doe',
      'email': 'admin@phoneshop.com',
      'password': 'password123',
      'avatarUrl': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'id': 'u2',
      'name': 'Jane Smith',
      'email': 'user@phoneshop.com',
      'password': 'password123',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
    }
  ];

  Future<UserEntity> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final userMap = _mockUsers.cast<Map<String, dynamic>?>().firstWhere(
          (user) => user!['email'] == email && user['password'] == password,
          orElse: () => null,
        );

    if (userMap != null) {
      return UserEntity(
        id: userMap['id'],
        name: userMap['name'],
        email: userMap['email'],
        avatarUrl: userMap['avatarUrl'],
      );
    } else {
      throw Exception('Tài khoản hoặc mật khẩu không chính xác.');
    }
  }

  Future<UserEntity> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    final userExists = _mockUsers.any((user) => user['email'] == email);
    if (userExists) {
      throw Exception('Email này đã được đăng ký.');
    }

    final newUser = {
      'id': 'u\${_mockUsers.length + 1}',
      'name': name,
      'email': email,
      'password': password,
      'avatarUrl': null,
    };
    
    _mockUsers.add(newUser);

    return UserEntity(
      id: newUser['id'] as String,
      name: newUser['name'] as String,
      email: newUser['email'] as String,
    );
  }
}
