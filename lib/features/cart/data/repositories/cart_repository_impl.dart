import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  final CartLocalDatasource datasource;

  CartRepositoryImpl(this.datasource);

  @override
  Future<List<CartItem>> getItems() => datasource.getItems();

  @override
  Future<bool> addItem(Product product) => datasource.addItem(product);

  @override
  Future<void> removeItem(Product product) => datasource.removeItem(product);

  @override
  Future<void> updateQuantity(Product product, int quantity) =>
      datasource.updateQuantity(product, quantity);

  @override
  Future<void> clearCart() => datasource.clearCart();
}
