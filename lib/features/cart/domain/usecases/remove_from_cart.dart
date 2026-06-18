import '../../../products/domain/entities/product.dart';
import '../repositories/cart_repository.dart';

class RemoveFromCart {
  final CartRepository repository;

  RemoveFromCart(this.repository);

  void call(Product product) {
    repository.removeItem(product);
  }
}
