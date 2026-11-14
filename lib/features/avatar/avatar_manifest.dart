import 'dart:convert';

import 'package:flutter/services.dart';

class AvatarClipInfo {
  const AvatarClipInfo({required this.name, required this.durationMs});

  final String name;
  final int durationMs;
}

class AvatarManifest {
  const AvatarManifest({
    required this.file,
    required this.crossfadeMs,
    required this.clips,
  });

  final String file;
  final int crossfadeMs;
  final List<AvatarClipInfo> clips;

  Set<String> get clipNames => clips.map((clip) => clip.name).toSet();

  AvatarClipInfo? clip(String name) {
    for (final item in clips) {
      if (item.name == name) return item;
    }
    return null;
  }

  static Future<AvatarManifest> load({
    AssetBundle? bundle,
    String assetPath = 'assets/avatar/manifest.json',
  }) async {
    return AvatarManifest.parse(
      await (bundle ?? rootBundle).loadString(assetPath),
    );
  }

  static AvatarManifest parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException('Avatar manifest must use version 1.');
    }

    final file = decoded['file'];
    final crossfadeMs = decoded['crossfadeMs'];
    final rawClips = decoded['clips'];
    if (file is! String || file.isEmpty) {
      throw const FormatException(
        'Avatar manifest file must be a non-empty path.',
      );
    }
    if (crossfadeMs is! int || crossfadeMs < 0) {
      throw const FormatException(
        'Avatar manifest crossfadeMs must be non-negative.',
      );
    }
    if (rawClips is! List) {
      throw const FormatException('Avatar manifest clips must be a list.');
    }

    final clips = <AvatarClipInfo>[];
    final names = <String>{};
    for (final rawClip in rawClips) {
      if (rawClip is! Map<String, dynamic>) {
        throw const FormatException('Each avatar clip must be an object.');
      }
      final name = rawClip['name'];
      final durationMs = rawClip['durationMs'];
      if (name is! String || name.isEmpty || name != name.toUpperCase()) {
        throw const FormatException(
          'Avatar clip names must be non-empty uppercase strings.',
        );
      }
      if (durationMs is! int || durationMs <= 0) {
        throw const FormatException('Avatar clip durationMs must be positive.');
      }
      if (!names.add(name)) {
        throw FormatException('Avatar clip "$name" is listed more than once.');
      }
      clips.add(AvatarClipInfo(name: name, durationMs: durationMs));
    }

    return AvatarManifest(
      file: file,
      crossfadeMs: crossfadeMs,
      clips: List.unmodifiable(clips),
    );
  }
}
