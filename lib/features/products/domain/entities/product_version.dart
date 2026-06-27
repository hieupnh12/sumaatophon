import 'package:equatable/equatable.dart';

class ProductVersion extends Equatable {
  final String id;
  final String color;
  final String ram;
  final String rom;
  final String ramRomLabel;
  final double price;
  final int stockQuantity;
  final String imageUrl;
  final List<String> galleryImages;

  const ProductVersion({
    required this.id,
    required this.color,
    required this.ram,
    required this.rom,
    this.ramRomLabel = '',
    required this.price,
    required this.stockQuantity,
    this.imageUrl = '',
    this.galleryImages = const [],
  });

  String get ramRom {
    if (ramRomLabel.isNotEmpty) return ramRomLabel;
    final parts = <String>[];
    if (ram.isNotEmpty) parts.add(ram);
    if (rom.isNotEmpty) parts.add(rom);
    return parts.join('/');
  }

  String get displayLabel => '$color · $ramRom';

  bool get inStock => stockQuantity > 0;

  @override
  List<Object?> get props =>
      [id, color, ram, rom, ramRomLabel, price, stockQuantity, imageUrl, galleryImages];
}
