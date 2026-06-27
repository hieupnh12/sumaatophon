import '../repositories/cart_repository.dart';

class RemoveFromCart {
  final CartRepository repository;

  RemoveFromCart(this.repository);

  Future<void> call(String customerId, String productVersionId) {
    return repository.removeItem(customerId, productVersionId);
  }
}
