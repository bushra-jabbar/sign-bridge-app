import 'dart:convert';

import '../interfaces/gloss_engine.dart';
import 'database.dart';

class SqliteHistoryRepository implements HistoryRepository {
  SqliteHistoryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<void> add(HistoryEntry entry) async {
    final db = await _appDatabase.database;
    await db.insert('sessions', {
      'language': entry.language,
      'mode': entry.mode,
      'input_text': entry.inputText,
      'gloss_json': jsonEncode([
        for (final clip in entry.clips)
          {'clip': clip.clip, 'label': clip.label, 'kind': clip.kind.name},
      ]),
      'created_at': entry.createdAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<HistoryEntry>> recent({int limit = 50}) async {
    if (limit < 1 || limit > 50) {
      throw RangeError.range(limit, 1, 50, 'limit');
    }

    final db = await _appDatabase.database;
    final rows = await db.query(
      'sessions',
      columns: ['language', 'mode', 'input_text', 'gloss_json', 'created_at'],
      where: 'mode = ?',
      whereArgs: ['text_to_sign'],
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );

    return [for (final row in rows) _entryFromRow(row)];
  }

  HistoryEntry _entryFromRow(Map<String, Object?> row) {
    final language = row['language'];
    final mode = row['mode'];
    final inputText = row['input_text'];
    final rawClips = row['gloss_json'];
    final createdAt = row['created_at'];
    if (language is! String ||
        mode is! String ||
        inputText is! String ||
        rawClips is! String ||
        createdAt is! String) {
      throw const FormatException('History entry has invalid database fields.');
    }

    final decoded = jsonDecode(rawClips);
    if (decoded is! List) {
      throw const FormatException('History clips must be stored as a list.');
    }
    final clips = <Clip>[];
    for (final value in decoded) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Each saved clip must be an object.');
      }
      final name = value['clip'];
      final label = value['label'];
      final kind = value['kind'];
      if (name is! String || label is! String || kind is! String) {
        throw const FormatException('Saved clip fields must be strings.');
      }
      final clipKind = switch (kind) {
        'sign' => ClipKind.sign,
        'fingerspell' => ClipKind.fingerspell,
        _ => throw FormatException('Unknown saved clip kind: $kind'),
      };
      clips.add(Clip(clip: name, label: label, kind: clipKind));
    }

    return HistoryEntry(
      inputText: inputText,
      clips: List.unmodifiable(clips),
      createdAt: DateTime.parse(createdAt),
      language: language,
      mode: mode,
    );
  }
}
