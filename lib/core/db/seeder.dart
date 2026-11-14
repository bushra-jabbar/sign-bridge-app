import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'csv_reader.dart';

Future<void> seedDefaultSigns(Database db) async {
  final existingCount = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM signs'),
  );

  if (existingCount == null || existingCount == 0) {
    final signs = parseCsvRows(
      await rootBundle.loadString('assets/packs/asl/lexicon_seed.csv'),
    );

    await db.transaction((txn) async {
      for (final sign in signs) {
        await txn.insert('signs', {
          'language': sign['language'] ?? 'asl',
          'gloss': sign['gloss'],
          'display_text': sign['display_text'],
          'category': sign['category'],
          'tier': sign['tier'],
          'frequency': int.parse(sign['frequency']!),
          'clip_name': sign['clip_name'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  await _seedCsv(db, 'assets/packs/asl/phrases.csv', 'phrases', const [
    'language',
    'phrase_norm',
    'gloss_sequence',
  ]);
  await _seedCsv(db, 'assets/packs/asl/synonyms.csv', 'synonyms', const [
    'language',
    'variant',
    'target',
  ]);
  await _seedCsv(
    db,
    'assets/packs/asl/irregular_verbs.csv',
    'irregular_verbs',
    const ['language', 'form', 'lemma'],
  );

  await db.transaction((txn) async {
    for (var code = 65; code <= 90; code++) {
      final letter = String.fromCharCode(code);
      await txn.insert('alphabet', {
        'language': 'asl',
        'letter': letter,
        'clip_name': 'FS_$letter',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  });
}

Future<void> _seedCsv(
  Database db,
  String assetPath,
  String table,
  List<String> columns,
) async {
  final rows = parseCsvRows(await rootBundle.loadString(assetPath));

  await db.transaction((txn) async {
    for (final row in rows) {
      await txn.insert(table, {
        for (final column in columns) column: row[column],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  });
}
