import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Stores only favorite song IDs (from MediaStore).
/// All song data comes from on_audio_query — nothing is cached.
class LocalStorageService {
  static const String _databaseName = 'audio_library.db';
  static const int _databaseVersion = 2;
  static const String _favoritesTable = 'favorites';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, _databaseName);

    return openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_favoritesTable(
            song_id TEXT PRIMARY KEY
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop old table from v1 and create new favorites-only table
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS audios');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_favoritesTable(
              song_id TEXT PRIMARY KEY
            )
          ''');
        }
      },
    );
  }

  Future<Set<String>> getFavoriteIds() async {
    final db = await database;
    final rows = await db.query(_favoritesTable);
    return rows.map((row) => row['song_id'] as String).toSet();
  }

  Future<void> setFavorite(String songId, bool isFavorite) async {
    final db = await database;
    if (isFavorite) {
      await db.insert(_favoritesTable, {
        'song_id': songId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete(
        _favoritesTable,
        where: 'song_id = ?',
        whereArgs: [songId],
      );
    }
  }
}
