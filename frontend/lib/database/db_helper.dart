import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  /// ================= GET DATABASE =================
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  /// ================= INIT DATABASE =================
  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'draft_pesanan.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pesanan_servis (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kode_transaksi TEXT UNIQUE,
            tanggal TEXT,
            biaya REAL,
            nama_teknisi TEXT,
            nama_pelanggan TEXT,
            nomor_telp TEXT,
            foto_1 TEXT,
            foto_2 TEXT,
            foto_3 TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  /// ================= INSERT DRAFT =================
  static Future<int> insertDraft(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      'pesanan_servis',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ================= GET ALL DRAFT =================
  static Future<List<Map<String, dynamic>>> getDrafts() async {
    final db = await database;
    return await db.query('pesanan_servis', orderBy: 'updated_at DESC');
  }

  /// ================= COUNT DRAFT =================
  static Future<int> countDraft() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM pesanan_servis',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// ================= DELETE DRAFT =================
  static Future<int> deleteDraft(int id) async {
    final db = await database;
    return await db.delete('pesanan_servis', where: 'id = ?', whereArgs: [id]);
  }
}
