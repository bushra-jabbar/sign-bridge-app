import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/interfaces/avatar_player.dart';
import '../../core/interfaces/gloss_engine.dart';
import 'avatar_manifest.dart';
import 'clip_queue.dart';

class GlbPlayer implements AvatarPlayer {
  GlbPlayer();

  static const _assetDirectory = 'assets/avatar/';
  final WebViewController _controller = WebViewController();
  final StreamController<AvatarEvent> _events =
      StreamController<AvatarEvent>.broadcast(sync: true);
  final Completer<void> _pageLoaded = Completer<void>();
  final Completer<void> _modelReady = Completer<void>();
  AvatarManifest? _manifest;
  Completer<void>? _activeClip;
  Completer<void>? _stopSignal;
  String? _activeClipName;
  int? _activeIndex;
  StateError? _modelError;
  bool _ready = false;
  int _playId = 0;

  @override
  Stream<AvatarEvent> get events => _events.stream;

  @override
  Set<String> get availableClips => _manifest?.clipNames ?? const {};

  Widget buildView() => WebViewWidget(controller: _controller);

  @override
  Future<void> load() async {
    if (_manifest != null) return;
    final manifest = await AvatarManifest.load();
    final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
    final modelPath = '$_assetDirectory${manifest.file}';
    if (!assets.listAssets().contains(modelPath)) {
      throw StateError('Avatar model is missing: $modelPath');
    }

    _manifest = manifest;
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.addJavaScriptChannel(
      'SignBridge',
      onMessageReceived: _handleMessage,
    );
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (!_pageLoaded.isCompleted) _pageLoaded.complete();
        },
      ),
    );
    await _controller.loadFlutterAsset('${_assetDirectory}viewer.html');
    await _pageLoaded.future;
    await _controller.runJavaScript(
      'setCrossfadeDuration(${manifest.crossfadeMs})',
    );
    await _controller.runJavaScript(
      'setModelFile(${jsonEncode(manifest.file)})',
    );
    await _modelReady.future.timeout(const Duration(seconds: 30));
    final modelError = _modelError;
    if (modelError != null) throw modelError;
  }

  void _handleMessage(JavaScriptMessage message) {
    final decoded = jsonDecode(message.message);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Avatar viewer sent an invalid event.');
    }
    final type = decoded['type'];
    final clip = decoded['clip'];
    final error = decoded['message'];

    switch (type) {
      case 'ready':
        _ready = true;
        if (!_modelReady.isCompleted) _modelReady.complete();
        _events.add(const AvatarEvent(type: AvatarEventType.ready));
      case 'clipEnded':
        if (clip == _activeClipName) {
          final activeClip = _activeClip;
          if (activeClip != null && !activeClip.isCompleted) {
            activeClip.complete();
          }
          _events.add(
            AvatarEvent(
              type: AvatarEventType.clipEnded,
              index: _activeIndex,
              clip: _activeClipName,
            ),
          );
        }
      case 'error':
        final messageText = error is String ? error : 'Avatar viewer error.';
        final stateError = StateError(messageText);
        if (!_modelReady.isCompleted) {
          _modelError = stateError;
          _modelReady.complete();
        }
        final activeClip = _activeClip;
        if (activeClip != null && !activeClip.isCompleted) {
          activeClip.completeError(stateError);
        }
        _events.add(
          AvatarEvent(type: AvatarEventType.error, message: messageText),
        );
      default:
        throw FormatException('Unknown avatar viewer event: $type');
    }
  }

  @override
  Future<void> play(List<Clip> queue) async {
    final manifest = _manifest;
    if (!_ready || manifest == null) {
      throw StateError('Load the GLB avatar player before playing clips.');
    }
    late final List<Clip> checkedQueue;
    try {
      checkedQueue = ClipQueue.validate(queue, manifest.clipNames);
    } on StateError catch (error) {
      _events.add(
        AvatarEvent(type: AvatarEventType.error, message: error.message),
      );
      rethrow;
    }
    await stop();
    final playId = ++_playId;
    final stopSignal = _stopSignal = Completer<void>();

    for (var index = 0; index < checkedQueue.length; index++) {
      if (playId != _playId) return;
      final clip = checkedQueue[index];
      final clipEnded = _activeClip = Completer<void>();
      _activeClipName = clip.clip;
      _activeIndex = index;
      _events.add(
        AvatarEvent(
          type: AvatarEventType.clipStarted,
          index: index,
          clip: clip.clip,
        ),
      );
      final completion = Future.any<bool>([
        clipEnded.future.then((_) => true),
        stopSignal.future.then((_) => false),
      ]);
      await _controller.runJavaScript('playClip(${jsonEncode(clip.clip)})');
      late final bool completed;
      try {
        completed = await completion;
      } finally {
        _activeClip = null;
        _activeClipName = null;
        _activeIndex = null;
      }
      if (!completed || playId != _playId) return;
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
    _activeClipName = null;
    _activeIndex = null;
    if (_ready) await _controller.runJavaScript('stopPlayback()');
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}
