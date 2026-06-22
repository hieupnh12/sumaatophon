import '../entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';

abstract class CartRepository {
  Future<List<CartItem>> getItems();
  Future<bool> addItem(Product product);
  Future<void> removeItem(Product product);
  Future<void> updateQuantity(Product product, int quantity);
  Future<void> clearCart();
}
