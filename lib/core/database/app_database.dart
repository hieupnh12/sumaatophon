import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Database dùng chung cho toàn app.
// Mỗi feature thêm bảng mới vào đây (trong _onCreate hoặc _onUpgrade).
class AppDatabase {
  static Database? _database;

  static const String _dbName = 'phoneshop.db';
  static const int _dbVersion = 3;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE cart_items ADD COLUMN product_stock_quantity INTEGER NOT NULL DEFAULT 99',
        );
      } catch (_) {
        // Column may already exist after partial migration.
      }
    }
    if (oldVersion < 3) {
      await _createProductsCacheTable(db);
    }
  }

  Future<void> _createProductsCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products_cache (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        price REAL NOT NULL,
        original_price REAL NOT NULL,
        image_url TEXT NOT NULL,
        gallery_images TEXT NOT NULL DEFAULT '[]',
        rating REAL NOT NULL,
        review_count INTEGER NOT NULL,
        ram_rom_options TEXT NOT NULL DEFAULT '[]',
        colors TEXT NOT NULL DEFAULT '[]',
        specifications TEXT NOT NULL DEFAULT '{}',
        is_new INTEGER NOT NULL DEFAULT 0,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL UNIQUE,
        product_name TEXT NOT NULL,
        product_brand TEXT NOT NULL,
        product_price REAL NOT NULL,
        product_original_price REAL NOT NULL,
        product_image_url TEXT NOT NULL,
        product_rating REAL NOT NULL,
        product_review_count INTEGER NOT NULL,
        product_is_new INTEGER NOT NULL DEFAULT 0,
        product_stock_quantity INTEGER NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await _createProductsCacheTable(db);
  }
}
