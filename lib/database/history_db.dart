import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_result.dart';

class HistoryDb {
  static Database? _database;
  static const String _tableName = 'scan_history';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_travel.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            extractedText TEXT NOT NULL,
            detectedLanguage TEXT NOT NULL,
            translatedText TEXT NOT NULL,
            targetLanguage TEXT NOT NULL,
            entities TEXT DEFAULT '{}',
            convertedCurrency TEXT DEFAULT '{}',
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Insère un scan dans l'historique
  Future<int> insertScan(ScanResult scan) async {
    final db = await database;
    return db.insert(_tableName, scan.toMap()..remove('id'));
  }

  /// Récupère tous les scans (du plus récent au plus ancien)
  Future<List<ScanResult>> getAllScans() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'timestamp DESC');
    return maps.map((map) => ScanResult.fromMap(map)).toList();
  }

  /// Récupère un scan par son ID
  Future<ScanResult?> getScanById(int id) async {
    final db = await database;
    final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ScanResult.fromMap(maps.first);
  }

  /// Supprime un scan
  Future<int> deleteScan(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Supprime tout l'historique
  Future<int> clearHistory() async {
    final db = await database;
    return db.delete(_tableName);
  }

  /// Compte le nombre de scans
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return result.first['count'] as int;
  }

  /// Recherche dans l'historique
  Future<List<ScanResult>> searchScans(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'extractedText LIKE ? OR translatedText LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => ScanResult.fromMap(map)).toList();
  }
}
