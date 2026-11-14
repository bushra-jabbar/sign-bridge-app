import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/interfaces/avatar_player.dart';
import '../../core/interfaces/gloss_engine.dart';
import 'avatar_manifest.dart';

class MockPlayer implements AvatarPlayer {
  MockPlayer({
    Future<String> Function()? loadManifest,
    Duration Function(int durationMs)? durationFor,
  }) : _loadManifest =
           loadManifest ??
           (() => rootBundle.loadString('assets/avatar/manifest.json')),
       _durationFor =
           durationFor ?? ((durationMs) => Duration(milliseconds: durationMs));

  final Future<String> Function() _loadManifest;
  final Duration Function(int durationMs) _durationFor;
  final StreamController<AvatarEvent> _events =
      StreamController<AvatarEvent>.broadcast(sync: true);
  AvatarManifest? _manifest;
  Completer<void>? _stopSignal;
  int _playId = 0;

  @override
  Stream<AvatarEvent> get events => _events.stream;

  @override
  Set<String> get availableClips => _manifest?.clipNames ?? const {};

  @override
  Future<void> load() async {
    if (_manifest != null) return;
    _manifest = AvatarManifest.parse(await _loadManifest());
    _events.add(const AvatarEvent(type: AvatarEventType.ready));
  }

  @override
  Future<void> play(List<Clip> queue) async {
    final manifest = _manifest;
    if (manifest == null) {
      throw StateError('Load the avatar player before playing clips.');
    }
    final checkedQueue = List<Clip>.unmodifiable(queue);
    await stop();
    final playId = ++_playId;
    final stopSignal = _stopSignal = Completer<void>();

    for (var index = 0; index < checkedQueue.length; index++) {
      if (playId != _playId) return;
      final clip = checkedQueue[index];
      _events.add(
        AvatarEvent(
          type: AvatarEventType.clipStarted,
          index: index,
          clip: clip.clip,
        ),
      );
      final duration = _durationFor(
        manifest.clip(clip.clip)?.durationMs ?? 600,
      );
      await Future.any<void>([
        Future<void>.delayed(duration),
        stopSignal.future,
      ]);
      if (playId != _playId || stopSignal.isCompleted) return;
      _events.add(
        AvatarEvent(
          type: AvatarEventType.clipEnded,
          index: index,
          clip: clip.clip,
        ),
      );
    }
    if (playId == _playId) {
      _events.add(const AvatarEvent(type: AvatarEventType.done));
    }
  }

  @override
  Future<void> stop() async {
    final stopSignal = _stopSignal;
    if (stopSignal != null && !stopSignal.isCompleted) {
      stopSignal.complete();
    }
    _playId++;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}
