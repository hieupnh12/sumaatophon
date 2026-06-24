import '../repositories/cart_repository.dart';

class RemoveFromCart {
  final CartRepository repository;

  RemoveFromCart(this.repository);

  Future<void> call(String productVersionId) {
    return repository.removeItem(productVersionId);
  }
}
