import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';
import '../models/cart_item_model.dart';

// Datasource thao tác trực tiếp với bảng cart_items trong SQLite.
class CartLocalDatasource {
  final AppDatabase appDatabase;

  CartLocalDatasource(this.appDatabase);

  static const String _table = 'cart_items';

  Future<Database> get _db async => appDatabase.database;

  // Lấy toàn bộ giỏ hàng
  Future<List<CartItem>> getItems() async {
    final db = await _db;
    final maps = await db.query(_table);
    return maps.map((m) => CartItemModel.fromMap(m).toEntity()).toList();
  }

  // Thêm sản phẩm: nếu đã có thì tăng quantity (không vượt tồn kho IMEI)
  Future<bool> addItem(Product product) async {
    if (product.stockQuantity <= 0) return false;

    final db = await _db;
    final existing = await db.query(
      _table,
      where: 'product_id = ?',
      whereArgs: [product.id],
    );

    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int;
      final maxStock = existing.first['product_stock_quantity'] as int? ?? product.stockQuantity;
      if (currentQty >= maxStock) return false;

      await db.update(
        _table,
        {
          'quantity': currentQty + 1,
          'product_stock_quantity': product.stockQuantity,
        },
        where: 'product_id = ?',
        whereArgs: [product.id],
      );
    } else {
      final model = CartItemModel.fromEntity(CartItem(product: product));
      await db.insert(_table, model.toMap());
    }
    return true;
  }

  // Xóa sản phẩm khỏi giỏ
  Future<void> removeItem(Product product) async {
    final db = await _db;
    await db.delete(_table, where: 'product_id = ?', whereArgs: [product.id]);
  }

  // Cập nhật số lượng trong khoảng [1, stockQuantity]
  Future<void> updateQuantity(Product product, int quantity) async {
    final db = await _db;
    final existing = await db.query(
      _table,
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
    if (existing.isEmpty) return;

    final maxStock = existing.first['product_stock_quantity'] as int? ?? product.stockQuantity;
    final clampedQty = quantity.clamp(1, maxStock);

    await db.update(
      _table,
      {'quantity': clampedQty},
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
  }

  // Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    final db = await _db;
    await db.delete(_table);
  }
}
