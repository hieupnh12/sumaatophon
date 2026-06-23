import 'dart:convert';

import '../../domain/entities/product.dart';

/// Chuyển JSON từ backend → [Product] entity.
/// Backend đã JOIN products + brands + product_versions + ram/rom/color.
class ProductModel {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final List<String> galleryImages;
  final double rating;
  final int reviewCount;
  final List<String> ramRomOptions;
  final List<String> colors;
  final Map<String, String> specifications;
  final bool isNew;
  final int stockQuantity;

  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      brand: entity.brand,
      price: entity.price,
      originalPrice: entity.originalPrice,
      imageUrl: entity.imageUrl,
      galleryImages: entity.galleryImages,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      ramRomOptions: entity.ramRomOptions,
      colors: entity.colors,
      specifications: entity.specifications,
      isNew: entity.isNew,
      stockQuantity: entity.stockQuantity,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? 'Unknown',
      price: _toDouble(map['price']),
      originalPrice: _toDouble(map['original_price']),
      imageUrl: map['image_url'] as String? ?? '',
      galleryImages: _decodeStringList(map['gallery_images']),
      rating: _toDouble(map['rating']),
      reviewCount: _toInt(map['review_count']),
      ramRomOptions: _decodeStringList(map['ram_rom_options']),
      colors: _decodeStringList(map['colors']),
      specifications: _decodeStringMap(map['specifications']),
      isNew: (map['is_new'] as int? ?? 0) == 1,
      stockQuantity: _toInt(map['stock_quantity']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'original_price': originalPrice,
      'image_url': imageUrl,
      'gallery_images': jsonEncode(galleryImages),
      'rating': rating,
      'review_count': reviewCount,
      'ram_rom_options': jsonEncode(ramRomOptions),
      'colors': jsonEncode(colors),
      'specifications': jsonEncode(specifications),
      'is_new': isNew ? 1 : 0,
      'stock_quantity': stockQuantity,
      'cached_at': DateTime.now().toIso8601String(),
    };
  }

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    this.galleryImages = const [],
    required this.rating,
    required this.reviewCount,
    this.ramRomOptions = const [],
    this.colors = const [],
    this.specifications = const {},
    this.isNew = false,
    this.stockQuantity = 0,
  });

 // từ json (dữ liệu database nhận từ backend) → ProductModel
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? 'Unknown',
      price: _toDouble(json['price']),
      originalPrice: _toDouble(json['originalPrice']),   //dòng này là chỉ importprice của product
      imageUrl: json['imageUrl'] as String? ?? '',
      galleryImages: _toStringList(json['galleryImages']),
      rating: _toDouble(json['rating']),                  // này lấy từ bảng feedbacks
      reviewCount: _toInt(json['reviewCount']),
      ramRomOptions: _toStringList(json['ramRomOptions']),
      colors: _toStringList(json['colors']),
      specifications: _toStringMap(json['specifications']),
      isNew: json['isNew'] as bool? ?? false,
      // API cũ chưa có field → cho phép thêm tạm; API mới trả 0 = hết hàng thật.
      stockQuantity: json['stockQuantity'] != null ? _toInt(json['stockQuantity']) : 99,
    );
  }

 
  // từ ProductModel → Product entity
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      brand: brand,
      price: price,
      originalPrice: originalPrice,
      imageUrl: imageUrl,
      galleryImages: galleryImages,
      rating: rating,
      reviewCount: reviewCount,
      ramRomOptions: ramRomOptions,
      colors: colors.isNotEmpty ? colors : const ['#000000', '#FFFFFF'],
      specifications: specifications,
      isNew: isNew,
      stockQuantity: stockQuantity,
    );
  }
  
  // hàm helper để chuyển đổi dữ liệu từ json sang double, int, list, map trong dart tránh bị lỗi null , lệch kiểu 
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  static Map<String, String> _toStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }

  static List<String> _decodeStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  static Map<String, String> _decodeStringMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map((key, val) => MapEntry(key.toString(), val.toString()));
        }
      } catch (_) {}
    }
    return const {};
  }
}
