import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';
import '../repositories/cart_repository.dart';

class AddToCart {
  final CartRepository repository;

  AddToCart(this.repository);

  Future<bool> call(Product product, ProductVersion version) {
    return repository.addItem(product, version);
  }
}
