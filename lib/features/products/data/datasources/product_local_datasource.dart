import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

/// Cache sản phẩm vào SQLite để hiển thị offline sau khi đã load từ API.
class ProductLocalDataSource {
  final AppDatabase appDatabase;

  ProductLocalDataSource(this.appDatabase);

  static const String _table = 'products_cache';

  Future<Database> get _db async => appDatabase.database;

  Future<void> cacheProducts(List<Product> products) async {
    if (products.isEmpty) return;

    final db = await _db;
    final batch = db.batch();
    batch.delete(_table);

    for (final product in products) {
      batch.insert(
        _table,
        ProductModel.fromEntity(product).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> cacheProduct(Product product) async {
    final db = await _db;
    await db.insert(
      _table,
      ProductModel.fromEntity(product).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getCachedProducts() async {
    final db = await _db;
    final maps = await db.query(
      _table,
      orderBy: 'cached_at DESC',
    );

    return maps.map((map) => ProductModel.fromMap(map).toEntity()).toList();
  }

  Future<Product?> getCachedProductById(String id) async {
    final db = await _db;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first).toEntity();
  }
}
