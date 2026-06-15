import 'package:equatable/equatable.dart';

class Product extends Equatable {
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

  const Product({
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
    this.colors = const ['#000000', '#FFFFFF'], // Default to Black/White hex
    this.specifications = const {},
    this.isNew = false,
  });

  bool get hasDiscount => originalPrice > price;
  int get discountPercentage => hasDiscount ? ((originalPrice - price) / originalPrice * 100).round() : 0;

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        price,
        originalPrice,
        imageUrl,
        galleryImages,
        rating,
        reviewCount,
        ramRomOptions,
        colors,
        specifications,
        isNew,
      ];
}
