import 'package:flutter/services.dart';

import '../../core/interfaces/avatar_player.dart';
import 'glb_player.dart';
import 'mock_player.dart';

Future<AvatarPlayer> createAvatarPlayer({AssetBundle? bundle}) async {
  final assetBundle = bundle ?? rootBundle;
  final assets = await AssetManifest.loadFromAssetBundle(assetBundle);
  if (assets.listAssets().contains('assets/avatar/avatar.glb')) {
    return GlbPlayer();
  }
  return MockPlayer();
}
