import 'package:sqflite/sqflite.dart';

import '../interfaces/gloss_engine.dart';
import 'database.dart';

class SqliteSignLexicon implements SignLexicon {
  SqliteSignLexicon(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  @override
  Future<SignEntry?> findWord(String lemma, String lang) async {
    final rows = await (await _db).query(
      'signs',
      where: 'language = ? AND (lower(display_text) = ? OR upper(gloss) = ?)',
      whereArgs: [lang, lemma.toLowerCase(), lemma.toUpperCase()],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return SignEntry(
      gloss: row['gloss']! as String,
      displayText: row['display_text']! as String,
      category: row['category']! as String,
      clipName: row['clip_name']! as String,
    );
  }

  @override
  Future<PhraseEntry?> findPhrase(String normalised, String lang) async {
    final rows = await (await _db).query(
      'phrases',
      columns: const ['phrase_norm', 'gloss_sequence'],
      where: 'language = ? AND phrase_norm = ?',
      whereArgs: [lang, normalised],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return PhraseEntry(
      phraseNorm: rows.first['phrase_norm']! as String,
      glossSequence: rows.first['gloss_sequence']! as String,
    );
  }

  @override
  Future<String?> findSynonym(String variant, String lang) async {
    final rows = await (await _db).query(
      'synonyms',
      columns: const ['target'],
      where: 'language = ? AND variant = ?',
      whereArgs: [lang, variant.toLowerCase()],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first['target']! as String;
  }

  @override
  Future<String?> findIrregularVerb(String form, String lang) async {
    final rows = await (await _db).query(
      'irregular_verbs',
      columns: const ['lemma'],
      where: 'language = ? AND form = ?',
      whereArgs: [lang, form.toLowerCase()],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first['lemma']! as String;
  }

  @override
  Future<String?> findAlphabetClip(String letter, String lang) async {
    final rows = await (await _db).query(
      'alphabet',
      columns: const ['clip_name'],
      where: 'language = ? AND letter = ?',
      whereArgs: [lang, letter.toUpperCase()],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first['clip_name']! as String;
  }

  @override
  Future<List<SignEntry>> browse({String? category, String? query}) async {
    final rows = await _appDatabase.fetchSigns(
      category: category,
      query: query,
    );
    return [
      for (final row in rows)
        SignEntry(
          gloss: row['gloss']! as String,
          displayText: row['display_text']! as String,
          category: row['category']! as String,
          clipName: row['clip_name']! as String,
        ),
    ];
  }
}
