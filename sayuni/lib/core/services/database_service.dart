import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sayuni_church.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Members Table
    await db.execute('''
      CREATE TABLE members(
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        email TEXT,
        jumuiya TEXT,
        department TEXT,
        is_baptized INTEGER,
        role TEXT,
        last_updated TEXT
      )
    ''');

    // 2. Jumuiya Table
    await db.execute('''
      CREATE TABLE jumuiya(
        id TEXT PRIMARY KEY,
        name TEXT,
        leader TEXT,
        location TEXT,
        meeting_day TEXT
      )
    ''');

    // 3. Prayer Requests Table
    await db.execute('''
      CREATE TABLE prayer_requests(
        id TEXT PRIMARY KEY,
        member_id TEXT,
        request TEXT,
        status TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 4. Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        payload TEXT,
        table_name TEXT,
        created_at TEXT
      )
    ''');
  }

  // Generic helper methods
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
