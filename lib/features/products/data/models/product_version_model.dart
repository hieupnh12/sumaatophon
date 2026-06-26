import '../../domain/entities/product_version.dart';

class ProductVersionModel {
  final String id;
  final String color;
  final String ram;
  final String rom;
  final double price;
  final int stockQuantity;
  final String imageUrl;
  final List<String> galleryImages;

  const ProductVersionModel({
    required this.id,
    required this.color,
    required this.ram,
    required this.rom,
    required this.price,
    required this.stockQuantity,
    this.imageUrl = '',
    this.galleryImages = const [],
  });

  factory ProductVersionModel.fromJson(Map<String, dynamic> json) {
    final ram = json['ram']?.toString() ?? '';
    final rom = json['rom']?.toString() ?? '';
    final ramRom = json['ramRom']?.toString() ?? '';

    String parsedRam = ram;
    String parsedRom = rom;
    if (parsedRam.isEmpty && parsedRom.isEmpty && ramRom.contains('/')) {
      final parts = ramRom.split('/');
      parsedRam = parts.isNotEmpty ? parts.first.trim() : '';
      parsedRom = parts.length > 1 ? parts.sublist(1).join('/').trim() : '';
    }

    return ProductVersionModel(
      id: json['id'].toString(),
      color: json['color']?.toString() ?? '',
      ram: parsedRam,
      rom: parsedRom,
      price: _toDouble(json['price']),
      stockQuantity: _toInt(json['stockQuantity']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      galleryImages: _toStringList(json['galleryImages']),
    );
  }

  ProductVersion toEntity() {
    return ProductVersion(
      id: id,
      color: color,
      ram: ram,
      rom: rom,
      price: price,
      stockQuantity: stockQuantity,
      imageUrl: imageUrl,
      galleryImages: galleryImages,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

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
}
