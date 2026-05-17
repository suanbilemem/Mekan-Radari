import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('radar_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
  }

  Future<int> insertPlace(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('places', row);
  }

  Future<List<Map<String, dynamic>>> getPlaces() async {
    final db = await instance.database;
    return await db.query('places');
  }

  Future<int> deletePlace(int id) async {
    final db = await instance.database;
    return await db.delete('places', where: 'id = ?', whereArgs: [id]);
  }
}