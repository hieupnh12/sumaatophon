import 'package:sumaatophon/features/cart/domain/entities/cart_item.dart';
import 'package:sumaatophon/features/cart/domain/repositories/cart_repository.dart';
import 'package:sumaatophon/features/products/domain/entities/product.dart';
import 'package:sumaatophon/features/products/domain/entities/product_version.dart';

class FakeCartRepository implements CartRepository {
  final Map<String, List<CartItem>> _cartsByCustomer = {};

  List<CartItem> itemsFor(String customerId) =>
      List.unmodifiable(_cartsByCustomer[customerId] ?? const []);

  @override
  Future<List<CartItem>> getItems(String customerId) async {
    return itemsFor(customerId);
  }

  @override
  Future<bool> addItem(
    String customerId,
    Product product,
    ProductVersion version,
  ) async {
    final items = List<CartItem>.from(_cartsByCustomer[customerId] ?? const []);
    final index = items.indexWhere((item) => item.version.id == version.id);

    if (index >= 0) {
      final existing = items[index];
      if (existing.quantity >= version.stockQuantity) return false;
      items[index] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      if (version.stockQuantity <= 0) return false;
      items.add(CartItem(product: product, version: version));
    }

    _cartsByCustomer[customerId] = items;
    return true;
  }

  @override
  Future<void> removeItem(String customerId, String productVersionId) async {
    final items = List<CartItem>.from(_cartsByCustomer[customerId] ?? const []);
    items.removeWhere((item) => item.version.id == productVersionId);
    _cartsByCustomer[customerId] = items;
  }

  @override
  Future<void> updateQuantity(
    String customerId,
    String productVersionId,
    int quantity,
  ) async {
    final items = List<CartItem>.from(_cartsByCustomer[customerId] ?? const []);
    final index = items.indexWhere((item) => item.version.id == productVersionId);
    if (index < 0) return;

    items[index] = items[index].copyWith(quantity: quantity);
    _cartsByCustomer[customerId] = items;
  }

  @override
  Future<void> clearCart(String customerId) async {
    _cartsByCustomer[customerId] = [];
  }
}
