import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_bridge_app/core/db/database.dart';
import 'package:sign_bridge_app/core/interfaces/avatar_player.dart';
import 'package:sign_bridge_app/core/interfaces/gloss_engine.dart';
import 'package:sign_bridge_app/features/translate/translate_screen.dart';

void main() {
  testWidgets('quick phrase translates, plays, and saves a history entry', (
    tester,
  ) async {
    final glossEngine = _FakeGlossEngine([
      const Clip(clip: 'HELLO', label: 'Hello', kind: ClipKind.sign),
    ]);
    final history = _FakeHistoryRepository();
    final player = _FakeAvatarPlayer();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranslateScreen(
            database: AppDatabase(),
            glossEngine: glossEngine,
            historyRepository: history,
            avatarPlayer: player,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(ActionChip, 'hello'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(glossEngine.lastText, 'hello');
    expect(player.played.single.single.clip, 'HELLO');
    expect(history.entries.single.inputText, 'hello');
    expect(find.text('Hello'), findsWidgets);
  });

  testWidgets('voice input transfers recognized text into the field', (
    tester,
  ) async {
    final speechInput = _FakeSpeechInput(
      available: true,
      results: ['hello there'],
    );
    final glossEngine = _FakeGlossEngine([
      const Clip(clip: 'HELLO', label: 'Hello', kind: ClipKind.sign),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranslateScreen(
            database: AppDatabase(),
            glossEngine: glossEngine,
            speechInput: speechInput,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Use voice input'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'hello there');
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
  Future<void> add(HistoryEntry entry) async => entries.add(entry);

  @override
  Future<List<HistoryEntry>> recent({int limit = 50}) async =>
      entries.take(limit).toList();
}

class _FakeSpeechInput implements SpeechInput {
  _FakeSpeechInput({required this.available, required this.results});

  final bool available;
  final List<String> results;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<String> listen() => Stream.fromIterable(results);

  @override
  Future<void> stop() async {}
}

class _FakeAvatarPlayer implements AvatarPlayer {
  final StreamController<AvatarEvent> _events =
      StreamController<AvatarEvent>.broadcast(sync: true);
  final played = <List<Clip>>[];

  @override
  Stream<AvatarEvent> get events => _events.stream;

  @override
  Set<String> get availableClips => const {'HELLO'};

  @override
  Future<void> load() async {
    _events.add(const AvatarEvent(type: AvatarEventType.ready));
  }

  @override
  Future<void> play(List<Clip> queue) async {
    played.add(queue);
    for (var index = 0; index < queue.length; index++) {
      _events.add(
        AvatarEvent(
          type: AvatarEventType.clipStarted,
          index: index,
          clip: queue[index].clip,
        ),
      );
      _events.add(
        AvatarEvent(
          type: AvatarEventType.clipEnded,
          index: index,
          clip: queue[index].clip,
        ),
      );
    }
    _events.add(const AvatarEvent(type: AvatarEventType.done));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _events.close();
}
