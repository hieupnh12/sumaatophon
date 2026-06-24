import 'package:equatable/equatable.dart';
import 'product_feedback.dart';
import 'product_version.dart';

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
  final int stockQuantity;
  final List<ProductVersion> versions;
  final List<ProductFeedback> feedbacks;

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
    this.colors = const  ['#000000', '#FFFFFF'], // Default to Black/White hex
    this.specifications = const {},
    this.isNew = false,
    this.stockQuantity = 0,
    this.versions = const [],
    this.feedbacks = const [],
  });

  ProductVersion? findVersion({required String color, required String ramRom}) {
    for (final version in versions) {
      if (version.color == color && version.ramRom == ramRom) {
        return version;
      }
    }
    return null;
  }

  ProductVersion? findVersionForColor(String color) {
    for (final version in versions) {
      if (version.color == color) return version;
    }
    return null;
  }

  ProductVersion? resolveVersion({required String color, required String ramRom}) {
    return findVersion(color: color, ramRom: ramRom) ??
        findVersionForColor(color);
  }

  List<String> get distinctColors {
    if (versions.isEmpty) return colors;

    final seen = <String>{};
    final result = <String>[];
    for (final version in versions) {
      if (version.color.isNotEmpty && seen.add(version.color)) {
        result.add(version.color);
      }
    }
    return result.isNotEmpty ? result : colors;
  }

  ProductVersion? versionFor({required String color, required String ramRom}) {
    return resolveVersion(color: color, ramRom: ramRom);
  }

  String thumbnailForColor({required String color, required String ramRom}) {
    final version = resolveVersion(color: color, ramRom: ramRom);
    if (version != null) {
      if (version.imageUrl.isNotEmpty) return version.imageUrl;
      if (version.galleryImages.isNotEmpty) return version.galleryImages.first;
    }
    if (imageUrl.isNotEmpty) return imageUrl;
    if (galleryImages.isNotEmpty) return galleryImages.first;
    return '';
  }

  List<String> get allGalleryImages {
    final images = <String>[];
    void addImage(String url) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && !images.contains(trimmed)) {
        images.add(trimmed);
      }
    }

    addImage(imageUrl);
    for (final url in galleryImages) {
      addImage(url);
    }
    for (final version in versions) {
      for (final url in version.galleryImages) {
        addImage(url);
      }
      addImage(version.imageUrl);
    }
    return images;
  }

  int galleryIndexForColor({required String color, required String ramRom}) {
    final thumb = thumbnailForColor(color: color, ramRom: ramRom);
    if (thumb.isEmpty) return 0;

    final index = allGalleryImages.indexOf(thumb);
    return index >= 0 ? index : 0;
  }

  double priceForVersion({required String color, required String ramRom}) {
    final version = resolveVersion(color: color, ramRom: ramRom);
    if (version != null) return version.price;
    return price;
  }

  bool get hasDiscount => originalPrice > price;
  int get discountPercentage => hasDiscount ? ((originalPrice - price) / originalPrice * 100).round() : 0;

  Product copyWith({
    List<ProductFeedback>? feedbacks,
    List<ProductVersion>? versions,
  }) {
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
      colors: colors,
      specifications: specifications,
      isNew: isNew,
      stockQuantity: stockQuantity,
      versions: versions ?? this.versions,
      feedbacks: feedbacks ?? this.feedbacks,
    );
  }

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
        stockQuantity,
        versions,
        feedbacks,
      ];
}
