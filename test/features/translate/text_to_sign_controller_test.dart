import 'package:flutter_test/flutter_test.dart';
import 'package:sign_bridge_app/core/interfaces/gloss_engine.dart';
import 'package:sign_bridge_app/features/translate/text_to_sign_controller.dart';

void main() {
  test('translates trimmed input and saves the gloss for history', () async {
    final glossEngine = _FakeGlossEngine([
      const Clip(clip: 'HELLO', label: 'Hello', kind: ClipKind.sign),
    ]);
    final history = _FakeHistoryRepository();
    final controller = TextToSignController(
      glossEngine: glossEngine,
      historyRepository: history,
    );

    final entry = await controller.translate('  hello  ');

    expect(glossEngine.lastText, 'hello');
    expect(entry.inputText, 'hello');
    expect(entry.clips.single.clip, 'HELLO');
    expect(history.entries, [entry]);
  });

  test('does not save a translation with no sign clips', () async {
    final history = _FakeHistoryRepository();
    final controller = TextToSignController(
      glossEngine: _FakeGlossEngine([]),
      historyRepository: history,
    );

    final entry = await controller.translate('the');

    expect(entry.clips, isEmpty);
    expect(history.entries, isEmpty);
  });

  test('rejects blank input without writing history', () async {
    final history = _FakeHistoryRepository();
    final controller = TextToSignController(
      glossEngine: _FakeGlossEngine([]),
      historyRepository: history,
    );

    await expectLater(controller.translate('  '), throwsArgumentError);
    expect(history.entries, isEmpty);
  });
}

class _FakeGlossEngine implements GlossEngine {
  _FakeGlossEngine(this.clips);

  final List<Clip> clips;
  String? lastText;

  @override
  Future<List<Clip>> translate(String text, {String language = 'asl'}) async {
    lastText = text;
    return clips;
  }
}

class _FakeHistoryRepository implements HistoryRepository {
  final entries = <HistoryEntry>[];

  @override
  Future<void> add(HistoryEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<List<HistoryEntry>> recent({int limit = 50}) async =>
      entries.take(limit).toList();
}
