import '../entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';

abstract class CartRepository {
  Future<List<CartItem>> getItems(String customerId);
  Future<bool> addItem(String customerId, Product product, ProductVersion version);
  Future<void> removeItem(String customerId, String productVersionId);
  Future<void> updateQuantity(String customerId, String productVersionId, int quantity);
  Future<void> clearCart(String customerId);
}
