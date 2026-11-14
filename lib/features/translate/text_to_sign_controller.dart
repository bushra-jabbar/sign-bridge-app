import '../../core/interfaces/gloss_engine.dart';

class TextToSignController {
  TextToSignController({
    required this._glossEngine,
    required this._historyRepository,
  });

  final GlossEngine _glossEngine;
  final HistoryRepository _historyRepository;

  Future<HistoryEntry> translate(String text) async {
    final input = text.trim();
    if (input.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Enter a message to translate.');
    }

    final clips = await _glossEngine.translate(input);
    final entry = HistoryEntry(
      inputText: input,
      clips: List.unmodifiable(clips),
      createdAt: DateTime.now(),
    );
    if (clips.isNotEmpty) {
      await _historyRepository.add(entry);
    }
    return entry;
  }
}
