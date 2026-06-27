import '../repositories/cart_repository.dart';

class UpdateCartQuantity {
  final CartRepository repository;

  UpdateCartQuantity(this.repository);

  Future<void> call(String customerId, String productVersionId, int quantity) {
    return repository.updateQuantity(customerId, productVersionId, quantity);
  }
}
