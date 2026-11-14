import '../../core/interfaces/gloss_engine.dart';

class ClipQueue {
  const ClipQueue._();

  static List<Clip> validate(List<Clip> queue, Set<String> availableClips) {
    for (final clip in queue) {
      if (!availableClips.contains(clip.clip)) {
        throw StateError('Avatar clip "${clip.clip}" is not in the manifest.');
      }
    }
    return List.unmodifiable(queue);
  }
}
