import '../../../products/domain/entities/product.dart';
import '../repositories/cart_repository.dart';

class AddToCart {
  final CartRepository repository;

  AddToCart(this.repository);

  void call(Product product) {
    repository.addItem(product);
  }
}
