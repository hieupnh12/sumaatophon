import '../../../products/domain/entities/product.dart';
import '../repositories/cart_repository.dart';

class UpdateCartQuantity {
  final CartRepository repository;

  UpdateCartQuantity(this.repository);

  void call(Product product, int quantity) {
    repository.updateQuantity(product, quantity);
  }
}
