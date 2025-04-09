import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_sync.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age REAL NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        gender TEXT
      )
    ''');

    await db.execute('''
    CREATE TABLE consumed_food (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      category TEXT,
      unit TEXT,
      count INTEGER,
      calories REAL,
      protein REAL,
      fat REAL,
      added_at TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS health_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      heart_rate INTEGER,
      steps INTEGER,
      systolic INTEGER,
      diastolic INTEGER,
      temperature REAL,
      respiratory_rate REAL,
      oxygen_saturation REAL,
      recorded_at TEXT
    )
  ''');
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('user', user);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final db = await instance.database;
    final result = await db.query('user', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db
        .update('user', user, where: 'id = ?', whereArgs: [user['id']]);
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'health_sync.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS consumed_food (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          category TEXT,
          unit TEXT,
          count INTEGER,
          calories REAL,
          protein REAL,
          fat REAL,
          added_at TEXT
        )
      ''');
      },
    );
  }

  Future<void> insertConsumedFood(Map<String, dynamic> food) async {
    final db = await database;
    await db.insert(
      'consumed_food',
      food,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertHealthData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'health_data',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
