import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';
import '../models/cart_item_model.dart';

class CartLocalDatasource {
  final AppDatabase appDatabase;

  CartLocalDatasource(this.appDatabase);

  static const String _table = 'cart_items';

  Future<Database> get _db async => appDatabase.database;

  Future<List<CartItem>> getItems() async {
    final db = await _db;
    final maps = await db.query(_table);
    return maps.map((m) => CartItemModel.fromMap(m).toEntity()).toList();
  }

  Future<bool> addItem(Product product, ProductVersion version) async {
    if (version.stockQuantity <= 0) return false;

    final db = await _db;
    final existing = await db.query(
      _table,
      where: 'product_version_id = ?',
      whereArgs: [version.id],
    );

    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int;
      final maxStock = existing.first['version_stock_quantity'] as int? ?? version.stockQuantity;
      if (currentQty >= maxStock) return false;

      await db.update(
        _table,
        {
          'quantity': currentQty + 1,
          'version_stock_quantity': version.stockQuantity,
          'version_price': version.price,
        },
        where: 'product_version_id = ?',
        whereArgs: [version.id],
      );
    } else {
      final model = CartItemModel.fromEntity(
        CartItem(product: product, version: version),
      );
      await db.insert(_table, model.toMap());
    }
    return true;
  }

  Future<void> removeItem(String productVersionId) async {
    final db = await _db;
    await db.delete(
      _table,
      where: 'product_version_id = ?',
      whereArgs: [productVersionId],
    );
  }

  Future<void> updateQuantity(String productVersionId, int quantity) async {
    final db = await _db;
    final existing = await db.query(
      _table,
      where: 'product_version_id = ?',
      whereArgs: [productVersionId],
    );
    if (existing.isEmpty) return;

    final maxStock = existing.first['version_stock_quantity'] as int? ?? 0;
    final clampedQty = quantity.clamp(1, maxStock);

    await db.update(
      _table,
      {'quantity': clampedQty},
      where: 'product_version_id = ?',
      whereArgs: [productVersionId],
    );
  }

  Future<void> clearCart() async {
    final db = await _db;
    await db.delete(_table);
  }
}
