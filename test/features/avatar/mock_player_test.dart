import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sign_bridge_app/core/interfaces/avatar_player.dart';
import 'package:sign_bridge_app/core/interfaces/gloss_engine.dart';
import 'package:sign_bridge_app/features/avatar/mock_player.dart';

const _manifest = {
  'version': 1,
  'file': 'avatar.glb',
  'crossfadeMs': 250,
  'clips': [
    {'name': 'HELLO', 'durationMs': 1200},
    {'name': 'THANK-YOU', 'durationMs': 1300},
  ],
};

void main() {
  test('loads manifest clips and plays them in order', () async {
    final player = MockPlayer(
      loadManifest: () async => jsonEncode(_manifest),
      durationFor: (_) => Duration.zero,
    );
    final events = <AvatarEvent>[];
    final subscription = player.events.listen(events.add);
    addTearDown(subscription.cancel);
    addTearDown(player.dispose);

    await player.load();
    expect(player.availableClips, {'HELLO', 'THANK-YOU'});

    await player.play(const [
      Clip(clip: 'HELLO', label: 'Hello', kind: ClipKind.sign),
      Clip(clip: 'THANK-YOU', label: 'Thank you', kind: ClipKind.sign),
    ]);

    expect(events.map((event) => event.type), [
      AvatarEventType.ready,
      AvatarEventType.clipStarted,
      AvatarEventType.clipEnded,
      AvatarEventType.clipStarted,
      AvatarEventType.clipEnded,
      AvatarEventType.done,
    ]);
  });

  test('plays absent clips as label-only fallback', () async {
    final player = MockPlayer(loadManifest: () async => jsonEncode(_manifest));
    final events = <AvatarEvent>[];
    final subscription = player.events.listen(events.add);
    addTearDown(subscription.cancel);
    addTearDown(player.dispose);

    await player.load();
    await player.play(const [
      Clip(clip: 'MISSING', label: 'Missing', kind: ClipKind.sign),
    ]);
    expect(player.availableClips, {'HELLO', 'THANK-YOU'});
    expect(events.map((event) => event.type), [
      AvatarEventType.ready,
      AvatarEventType.clipStarted,
      AvatarEventType.clipEnded,
      AvatarEventType.done,
    ]);
  });
}
