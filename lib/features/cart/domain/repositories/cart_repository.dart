import '../entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';

abstract class CartRepository {
  Future<List<CartItem>> getItems();
  Future<bool> addItem(Product product, ProductVersion version);
  Future<void> removeItem(String productVersionId);
  Future<void> updateQuantity(String productVersionId, int quantity);
  Future<void> clearCart();
}
