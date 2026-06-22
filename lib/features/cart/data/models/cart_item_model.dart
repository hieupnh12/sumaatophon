import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';

// Model chịu trách nhiệm chuyển đổi giữa CartItem và SQLite Map.
class CartItemModel {
  final String productId;
  final String productName;
  final String productBrand;
  final double productPrice;
  final double productOriginalPrice;
  final String productImageUrl;
  final double productRating;
  final int productReviewCount;
  final bool productIsNew;
  final int productStockQuantity;
  final int quantity;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.productBrand,
    required this.productPrice,
    required this.productOriginalPrice,
    required this.productImageUrl,
    required this.productRating,
    required this.productReviewCount,
    required this.productIsNew,
    required this.productStockQuantity,
    required this.quantity,
  });

  // Đọc từ SQLite (Map → Model)
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      productBrand: map['product_brand'] as String,
      productPrice: map['product_price'] as double,
      productOriginalPrice: map['product_original_price'] as double,
      productImageUrl: map['product_image_url'] as String,
      productRating: map['product_rating'] as double,
      productReviewCount: map['product_review_count'] as int,
      productIsNew: (map['product_is_new'] as int) == 1,
      productStockQuantity: map['product_stock_quantity'] as int? ?? 0,
      quantity: map['quantity'] as int,
    );
  }

  // Ghi vào SQLite (Model → Map)
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_brand': productBrand,
      'product_price': productPrice,
      'product_original_price': productOriginalPrice,
      'product_image_url': productImageUrl,
      'product_rating': productRating,
      'product_review_count': productReviewCount,
      'product_is_new': productIsNew ? 1 : 0,
      'product_stock_quantity': productStockQuantity,
      'quantity': quantity,
    };
  }

  // Chuyển từ domain entity → model (để lưu DB)
  factory CartItemModel.fromEntity(CartItem cartItem) {
    return CartItemModel(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      productBrand: cartItem.product.brand,
      productPrice: cartItem.product.price,
      productOriginalPrice: cartItem.product.originalPrice,
      productImageUrl: cartItem.product.imageUrl,
      productRating: cartItem.product.rating,
      productReviewCount: cartItem.product.reviewCount,
      productIsNew: cartItem.product.isNew,
      productStockQuantity: cartItem.product.stockQuantity,
      quantity: cartItem.quantity,
    );
  }

  // Chuyển từ model → domain entity (để BLoC dùng)
  CartItem toEntity() {
    return CartItem(
      product: Product(
        id: productId,
        name: productName,
        brand: productBrand,
        price: productPrice,
        originalPrice: productOriginalPrice,
        imageUrl: productImageUrl,
        rating: productRating,
        reviewCount: productReviewCount,
        isNew: productIsNew,
        stockQuantity: productStockQuantity,
      ),
      quantity: quantity,
    );
  }
}
