import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Database dùng chung cho toàn app.
// Mỗi feature thêm bảng mới vào đây (trong _onCreate hoặc _onUpgrade).
class AppDatabase {
  static Database? _database;

  static const String _dbName = 'phoneshop.db';
  static const int _dbVersion = 1;

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
    );
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
        quantity INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }
}
