import 'gloss_engine.dart';

enum AvatarEventType { ready, clipStarted, clipEnded, done, error }

class AvatarEvent {
  const AvatarEvent({required this.type, this.index, this.clip, this.message});

  final AvatarEventType type;
  final int? index;
  final String? clip;
  final String? message;
}

abstract class AvatarPlayer {
  Future<void> load();
  Future<void> play(List<Clip> queue);
  Future<void> stop();
  Future<void> dispose();
  Stream<AvatarEvent> get events;
  Set<String> get availableClips;
}
