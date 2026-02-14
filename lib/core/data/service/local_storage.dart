import 'package:mp3_player_v2/core/data/model/audio_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalStorageService {
  static const String _databaseName = 'audio_library.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'audios';
  static const String _defaultImagePath = 'assets/images/podcast.png';

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
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            image_path TEXT NOT NULL,
            duration TEXT NOT NULL,
            file_path TEXT NOT NULL UNIQUE,
            is_favorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> storeAudiosFromLocalFiles(List<AudioModel> audios) async {
    final db = await database;
    final batch = db.batch();

    for (final audio in audios) {
      final normalizedImagePath = audio.imagePath.trim().isEmpty
          ? _defaultImagePath
          : audio.imagePath;

      batch.insert(_tableName, {
        'title': audio.title,
        'artist': audio.artist,
        'image_path': normalizedImagePath,
        'duration': audio.duration,
        'file_path': audio.filePath,
        'is_favorite': audio.isFavorite ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<AudioModel>> getAllSongs() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return rows.map(_mapToAudioModel).toList();
  }

  Future<List<AudioModel>> getFavoriteSongs() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return rows.map(_mapToAudioModel).toList();
  }

  Future<void> setSongFavorite({
    required String songId,
    required bool isFavorite,
  }) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [int.tryParse(songId) ?? -1],
    );
  }

  AudioModel _mapToAudioModel(Map<String, Object?> row) {
    final rowImagePath = (row['image_path'] as String?)?.trim() ?? '';
    final normalizedImagePath =
        rowImagePath.isEmpty || rowImagePath == 'assets/images/default.jpg'
        ? _defaultImagePath
        : rowImagePath;

    return AudioModel(
      id: row['id'].toString(),
      title: row['title'] as String,
      artist: row['artist'] as String,
      imagePath: normalizedImagePath,
      duration: row['duration'] as String,
      filePath: row['file_path'] as String,
      isFavorite: (row['is_favorite'] as int) == 1,
    );
  }
}
