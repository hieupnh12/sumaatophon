import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  final CartLocalDatasource datasource;

  CartRepositoryImpl(this.datasource);

  @override
  Future<List<CartItem>> getItems() => datasource.getItems();

  @override
  Future<bool> addItem(Product product, ProductVersion version) =>
      datasource.addItem(product, version);

  @override
  Future<void> removeItem(String productVersionId) =>
      datasource.removeItem(productVersionId);

  @override
  Future<void> updateQuantity(String productVersionId, int quantity) =>
      datasource.updateQuantity(productVersionId, quantity);

  @override
  Future<void> clearCart() => datasource.clearCart();
}
