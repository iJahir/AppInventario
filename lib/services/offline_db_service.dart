import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineDbService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_transactions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            payload TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  static Future<int> insertOfflineTransaction(String type, Map<String, dynamic> payload) async {
    final db = await database;
    return await db.insert('transactions', {
      'type': type,
      'payload': jsonEncode(payload),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'id ASC');
  }

  static Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
