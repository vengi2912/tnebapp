import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/bill_record.dart';

/// Thin wrapper around sqflite for persisting monthly bill snapshots.
class DbService {
  DbService._internal();
  static final DbService instance = DbService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tneb_bill_splitter.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bill_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            monthLabel TEXT NOT NULL,
            savedAt TEXT NOT NULL,
            grandTotalUnits REAL NOT NULL,
            grandTotalAmount REAL NOT NULL,
            inputsJson TEXT NOT NULL,
            resultJson TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertRecord(BillRecord record) async {
    final db = await database;
    final map = record.toMap()..remove('id');
    return db.insert('bill_records', map);
  }

  Future<List<BillRecord>> fetchAllRecords() async {
    final db = await database;
    final rows = await db.query('bill_records', orderBy: 'savedAt DESC');
    return rows.map((r) => BillRecord.fromMap(r)).toList();
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('bill_records', where: 'id = ?', whereArgs: [id]);
  }
}
