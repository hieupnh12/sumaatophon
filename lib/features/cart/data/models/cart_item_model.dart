import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';

class CartItemModel {
  final String productVersionId;
  final String productId;
  final String productName;
  final String productBrand;
  final double productPrice;
  final double productOriginalPrice;
  final String productImageUrl;
  final double productRating;
  final int productReviewCount;
  final bool productIsNew;
  final String versionColor;
  final String versionRam;
  final String versionRom;
  final double versionPrice;
  final int versionStockQuantity;
  final int quantity;

  const CartItemModel({
    required this.productVersionId,
    required this.productId,
    required this.productName,
    required this.productBrand,
    required this.productPrice,
    required this.productOriginalPrice,
    required this.productImageUrl,
    required this.productRating,
    required this.productReviewCount,
    required this.productIsNew,
    required this.versionColor,
    required this.versionRam,
    required this.versionRom,
    required this.versionPrice,
    required this.versionStockQuantity,
    required this.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productVersionId: json['productVersionId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productBrand: json['productBrand'] as String? ?? 'Unknown',
      productPrice: (json['productPrice'] as num).toDouble(),
      productOriginalPrice: (json['productOriginalPrice'] as num).toDouble(),
      productImageUrl: json['productImageUrl'] as String? ?? json['versionImageUrl'] as String? ?? '',
      productRating: (json['productRating'] as num?)?.toDouble() ?? 0,
      productReviewCount: json['productReviewCount'] as int? ?? 0,
      productIsNew: json['productIsNew'] as bool? ?? false,
      versionColor: json['versionColor'] as String? ?? '',
      versionRam: json['versionRam'] as String? ?? '',
      versionRom: json['versionRom'] as String? ?? '',
      versionPrice: (json['versionPrice'] as num).toDouble(),
      versionStockQuantity: json['versionStockQuantity'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productVersionId: map['product_version_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      productBrand: map['product_brand'] as String,
      productPrice: (map['product_price'] as num).toDouble(),
      productOriginalPrice: (map['product_original_price'] as num).toDouble(),
      productImageUrl: map['product_image_url'] as String,
      productRating: (map['product_rating'] as num).toDouble(),
      productReviewCount: map['product_review_count'] as int,
      productIsNew: (map['product_is_new'] as int) == 1,
      versionColor: map['version_color'] as String? ?? '',
      versionRam: map['version_ram'] as String? ?? '',
      versionRom: map['version_rom'] as String? ?? '',
      versionPrice: (map['version_price'] as num).toDouble(),
      versionStockQuantity: map['version_stock_quantity'] as int? ?? 0,
      quantity: map['quantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_version_id': productVersionId,
      'product_id': productId,
      'product_name': productName,
      'product_brand': productBrand,
      'product_price': productPrice,
      'product_original_price': productOriginalPrice,
      'product_image_url': productImageUrl,
      'product_rating': productRating,
      'product_review_count': productReviewCount,
      'product_is_new': productIsNew ? 1 : 0,
      'version_color': versionColor,
      'version_ram': versionRam,
      'version_rom': versionRom,
      'version_price': versionPrice,
      'version_stock_quantity': versionStockQuantity,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromEntity(CartItem cartItem) {
    return CartItemModel(
      productVersionId: cartItem.version.id,
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      productBrand: cartItem.product.brand,
      productPrice: cartItem.product.price,
      productOriginalPrice: cartItem.product.originalPrice,
      productImageUrl: cartItem.product.imageUrl,
      productRating: cartItem.product.rating,
      productReviewCount: cartItem.product.reviewCount,
      productIsNew: cartItem.product.isNew,
      versionColor: cartItem.version.color,
      versionRam: cartItem.version.ram,
      versionRom: cartItem.version.rom,
      versionPrice: cartItem.version.price,
      versionStockQuantity: cartItem.version.stockQuantity,
      quantity: cartItem.quantity,
    );
  }

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
        stockQuantity: versionStockQuantity,
      ),
      version: ProductVersion(
        id: productVersionId,
        color: versionColor,
        ram: versionRam,
        rom: versionRom,
        price: versionPrice,
        stockQuantity: versionStockQuantity,
      ),
      quantity: quantity,
    );
  }
}
