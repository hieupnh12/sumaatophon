import 'package:equatable/equatable.dart';

class ProductVersion extends Equatable {
  final String id;
  final String color;
  final String ram;
  final String rom;
  final double price;
  final int stockQuantity;

  const ProductVersion({
    required this.id,
    required this.color,
    required this.ram,
    required this.rom,
    required this.price,
    required this.stockQuantity,
  });

  String get ramRom {
    final parts = <String>[];
    if (ram.isNotEmpty) parts.add(ram);
    if (rom.isNotEmpty) parts.add(rom);
    return parts.join('/');
  }

  String get displayLabel => '$color · $ramRom';

  bool get inStock => stockQuantity > 0;

  @override
  List<Object?> get props => [id, color, ram, rom, price, stockQuantity];
}
