import '../repositories/cart_repository.dart';

class UpdateCartQuantity {
  final CartRepository repository;

  UpdateCartQuantity(this.repository);

  Future<void> call(String productVersionId, int quantity) {
    return repository.updateQuantity(productVersionId, quantity);
  }
}
