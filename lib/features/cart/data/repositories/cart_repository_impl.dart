import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDatasource remoteDatasource;

  CartRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<CartItem>> getItems(String customerId) async {
    final models = await remoteDatasource.getItems(customerId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> addItem(String customerId, Product product, ProductVersion version) async {
    try {
      await remoteDatasource.addItem(customerId, version.id);
      return true;
    } on CartStockException {
      return false;
    }
  }

  @override
  Future<void> removeItem(String customerId, String productVersionId) async {
    await remoteDatasource.removeItem(customerId, productVersionId);
  }

  @override
  Future<void> updateQuantity(String customerId, String productVersionId, int quantity) async {
    await remoteDatasource.updateQuantity(customerId, productVersionId, quantity);
  }

  @override
  Future<void> clearCart(String customerId) async {
    await remoteDatasource.clearCart(customerId);
  }
}
