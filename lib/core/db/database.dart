import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'seeder.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._internal();

  factory AppDatabase() => _instance ??= AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'sign_bridge_app.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );

    return _database!;
  }

  Future<void> initialize() async {
    final db = await database;
    await createInitialSchema(db);
    await seedDefaultSigns(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await createInitialSchema(db);
  }

  Future<void> createInitialSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS signs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL DEFAULT 'asl',
        gloss TEXT NOT NULL,
        display_text TEXT NOT NULL,
        category TEXT NOT NULL,
        tier TEXT NOT NULL,
        frequency INTEGER NOT NULL,
        clip_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL DEFAULT 'asl',
        mode TEXT NOT NULL,
        input_text TEXT,
        gloss_json TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS phrases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL DEFAULT 'asl',
        phrase_norm TEXT NOT NULL,
        gloss_sequence TEXT NOT NULL,
        UNIQUE(language, phrase_norm)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS synonyms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL DEFAULT 'asl',
        variant TEXT NOT NULL,
        target TEXT NOT NULL,
        UNIQUE(language, variant)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS alphabet (
        language TEXT NOT NULL DEFAULT 'asl',
        letter TEXT NOT NULL,
        clip_name TEXT NOT NULL,
        PRIMARY KEY(language, letter)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS irregular_verbs (
        language TEXT NOT NULL DEFAULT 'asl',
        form TEXT NOT NULL,
        lemma TEXT NOT NULL,
        PRIMARY KEY(language, form)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS signs_language_gloss ON signs(language, gloss)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS signs_language_display ON signs(language, display_text)',
    );
  }

  Future<List<Map<String, Object?>>> fetchSigns({
    String? category,
    String? query,
  }) async {
    final db = await database;
    String sql = 'SELECT * FROM signs WHERE language = ?';
    final args = ['asl'];

    if (category != null && category.isNotEmpty) {
      sql += ' AND category = ?';
      args.add(category);
    }

    if (query != null && query.isNotEmpty) {
      sql += ' AND (gloss LIKE ? OR display_text LIKE ?)';
      args.add('%$query%');
      args.add('%$query%');
    }

    sql += ' ORDER BY frequency DESC, gloss ASC';

    return db.rawQuery(sql, args);
  }
}
