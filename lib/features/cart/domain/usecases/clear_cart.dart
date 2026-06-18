import '../repositories/cart_repository.dart';

class ClearCart {
  final CartRepository repository;

  ClearCart(this.repository);

  void call() {
    repository.clearCart();
  }
}
