import '../repositories/cart_repository.dart';

class ClearCart {
  final CartRepository repository;

  ClearCart(this.repository);

  Future<void> call(String customerId) {
    return repository.clearCart(customerId);
  }
}
