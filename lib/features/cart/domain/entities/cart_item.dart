import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';

class CartItem extends Equatable {
  final Product product;
  final ProductVersion version;
  final int quantity;

  const CartItem({
    required this.product,
    required this.version,
    this.quantity = 1,
  });

  double get unitPrice => version.price > 0 ? version.price : product.price;

  int get maxQuantity => version.stockQuantity;

  CartItem copyWith({Product? product, ProductVersion? version, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      version: version ?? this.version,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, version, quantity];
}
