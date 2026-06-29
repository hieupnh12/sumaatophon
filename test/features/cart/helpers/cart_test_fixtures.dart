import 'package:sumaatophon/features/auth/domain/entities/user_entity.dart';
import 'package:sumaatophon/features/auth/domain/repositories/auth_repository.dart';
import 'package:sumaatophon/features/cart/domain/entities/cart_item.dart';
import 'package:sumaatophon/features/products/domain/entities/product.dart';
import 'package:sumaatophon/features/products/domain/entities/product_version.dart';
import 'package:sumaatophon/features/products/domain/repositories/product_repository.dart';

const testCustomerId = '42';

UserEntity testCustomerUser() {
  return const UserEntity(
    id: testCustomerId,
    name: 'Test User',
    email: 'user@test.com',
    phoneNumber: '0900000000',
  );
}

Product testProduct({
  String id = '1',
  String name = 'iPhone 16 Pro',
  double price = 25000000,
  int stockQuantity = 5,
  List<ProductVersion>? versions,
}) {
  return Product(
    id: id,
    name: name,
    brand: 'Apple',
    price: price,
    originalPrice: price,
    imageUrl: '',
    rating: 4.8,
    reviewCount: 12,
    stockQuantity: stockQuantity,
    colors: const ['#000000'],
    ramRomOptions: const ['8GB/256GB'],
    versions: versions ??
        [
          testProductVersion(
            id: 'v1',
            price: price,
            stockQuantity: stockQuantity,
          ),
        ],
  );
}

ProductVersion testProductVersion({
  String id = 'v1',
  String color = '#000000',
  String ram = '8GB',
  String rom = '256GB',
  double price = 25000000,
  int stockQuantity = 5,
}) {
  return ProductVersion(
    id: id,
    color: color,
    ram: ram,
    rom: rom,
    price: price,
    stockQuantity: stockQuantity,
  );
}

CartItem testCartItem({
  String versionId = 'v1',
  String productId = '1',
  String name = 'iPhone 16 Pro',
  double unitPrice = 25000000,
  int quantity = 1,
  int stockQuantity = 5,
}) {
  return CartItem(
    product: testProduct(id: productId, name: name, price: unitPrice),
    version: testProductVersion(
      id: versionId,
      price: unitPrice,
      stockQuantity: stockQuantity,
    ),
    quantity: quantity,
  );
}

class FakeProductRepository implements ProductRepository {
  FakeProductRepository(this.product);

  final Product product;

  @override
  Future<List<Product>> getProducts() async => [product];

  @override
  Future<Product> getProductById(String id) async => product;
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.user);

  final UserEntity user;

  @override
  Future<UserEntity?> getSession() async => user;

  @override
  Future<void> clearSession() async {}

  @override
  Future<UserEntity> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> register(String name, String email, String password) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> syncAuth(String idToken) => throw UnimplementedError();

  @override
  Future<String?> requestOtp(String phone) => throw UnimplementedError();

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> linkPhone(String phone, String otp, {bool force = false}) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> updateProfile({
    required String customerId,
    required String name,
    String? gender,
    String? dob,
    String? address,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<void> saveSession(UserEntity user) async {}
}
