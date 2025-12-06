import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class FilterStore {
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'filters.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE filters(stream_id TEXT PRIMARY KEY, unread_only INTEGER NOT NULL)',
        );
      },
    );
    return _db!;
  }

  Future<bool?> getUnreadOnly(String streamId) async {
    final db = await _database;
    final rows = await db.query(
      'filters',
      columns: ['unread_only'],
      where: 'stream_id = ?',
      whereArgs: [streamId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['unread_only'] as int) == 1;
  }

  Future<void> setUnreadOnly(String streamId, bool value) async {
    final db = await _database;
    await db.insert(
      'filters',
      {'stream_id': streamId, 'unread_only': value ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
