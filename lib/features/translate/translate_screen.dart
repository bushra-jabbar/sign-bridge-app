import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/db/sqlite_history_repository.dart';
import '../../core/db/sqlite_sign_lexicon.dart';
import '../../core/interfaces/avatar_player.dart';
import '../../core/interfaces/gloss_engine.dart';
import '../../features/avatar/avatar_player_factory.dart';
import '../../features/avatar/glb_player.dart';
import '../../features/avatar/mock_player.dart';
import '../gloss/rule_gloss_engine.dart';
import '../sign_to_text/sign_to_text_screen.dart';
import '../voice/speech_to_text_input.dart';
import 'quick_phrases.dart';
import 'text_to_sign_controller.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({
    super.key,
    required this.database,
    this.glossEngine,
    this.historyRepository,
    this.avatarPlayer,
    this.speechInput,
  });

  final AppDatabase database;
  final GlossEngine? glossEngine;
  final HistoryRepository? historyRepository;
  final AvatarPlayer? avatarPlayer;
  final SpeechInput? speechInput;

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

enum _TranslateMode { textToSign, signToText }

class _TranslateScreenState extends State<TranslateScreen> {
  late final TextEditingController _textController;
  late final TextToSignController _translation;
  late final SpeechInput _speechInput;
  AvatarPlayer? _player;
  StreamSubscription<AvatarEvent>? _playerEvents;
  StreamSubscription<String>? _voiceSubscription;
  List<Clip> _clips = [];
  int? _activeIndex;
  String _avatarLabel = 'Your sign will appear here';
  String? _message;
  bool _playerLoading = true;
  bool _working = false;
  bool _listening = false;
  _TranslateMode _mode = _TranslateMode.textToSign;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    final glossEngine =
        widget.glossEngine ??
        RuleGlossEngine(SqliteSignLexicon(widget.database));
    final historyRepository =
        widget.historyRepository ?? SqliteHistoryRepository(widget.database);
    _translation = TextToSignController(
      glossEngine: glossEngine,
      historyRepository: historyRepository,
    );
    _speechInput = widget.speechInput ?? SpeechToTextInput();
    unawaited(_initialisePlayer());
  }

  Future<void> _initialisePlayer() async {
    AvatarPlayer? player;
    try {
      player = widget.avatarPlayer ?? await createAvatarPlayer();
      try {
        await player.load();
      } on StateError catch (error) {
        if (player is! GlbPlayer) rethrow;
        await player.dispose();
        player = await _createLabelFallback(error.message);
      } on Exception catch (error) {
        if (player is! GlbPlayer) rethrow;
        await player.dispose();
        player = await _createLabelFallback(error.toString());
      }

      if (!mounted) {
        await player.dispose();
        return;
      }
      _attachPlayer(player);
      setState(() => _playerLoading = false);
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _playerLoading = false;
          _message = 'Avatar player failed to load: ${error.message}';
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _playerLoading = false;
          _message = 'Avatar player failed to load: $error';
        });
      }
    }
  }

  Future<AvatarPlayer> _createLabelFallback(String reason) async {
    final fallback = MockPlayer();
    await fallback.load();
    _message = '3D avatar unavailable; showing labels instead. $reason';
    return fallback;
  }

  void _attachPlayer(AvatarPlayer player) {
    _player = player;
    _playerEvents = player.events.listen((event) {
      if (!mounted) return;
      setState(() {
        switch (event.type) {
          case AvatarEventType.ready:
            break;
          case AvatarEventType.clipStarted:
            _activeIndex = event.index;
            if (event.index != null && event.index! < _clips.length) {
              _avatarLabel = _clips[event.index!].label;
            }
          case AvatarEventType.clipEnded:
            break;
          case AvatarEventType.done:
            _activeIndex = null;
            _working = false;
          case AvatarEventType.error:
            _message = event.message ?? 'Avatar playback failed.';
            _working = false;
        }
      });
    });
  }

  Future<void> _translateAndPlay(String text) async {
    if (_working || _playerLoading) return;
    if (text.trim().isEmpty) {
      setState(() => _message = 'Type a message to translate.');
      return;
    }
    if (_player == null) {
      setState(() => _message ??= 'Avatar player is unavailable.');
      return;
    }

    setState(() {
      _working = true;
      _activeIndex = null;
      _message = null;
    });
    try {
      final entry = await _translation.translate(text);
      if (!mounted) return;
      if (entry.clips.isEmpty) {
        setState(() {
          _clips = [];
          _working = false;
          _message =
              'No signs were found for that message. Try another phrase.';
        });
        return;
      }
      setState(() {
        _clips = entry.clips;
        _avatarLabel = entry.clips.first.label;
      });
      await _playClips(entry.clips);
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _working = false;
          _message = error.message;
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _working = false;
          _message = 'Could not translate this message: $error';
        });
      }
    } finally {
      if (mounted && _working) setState(() => _working = false);
    }
  }

  Future<void> _playClips(List<Clip> clips) async {
    final player = _player;
    if (player == null) throw StateError('Avatar player is unavailable.');
    try {
      await player.play(clips);
    } on StateError catch (error) {
      if (player is! GlbPlayer) rethrow;
      await _replaceWithLabelFallback(error.message);
      await _player!.play(clips);
    } on Exception catch (error) {
      if (player is! GlbPlayer) rethrow;
      await _replaceWithLabelFallback(error.toString());
      await _player!.play(clips);
    }
  }

  Future<void> _replaceWithLabelFallback(String reason) async {
    await _playerEvents?.cancel();
    final oldPlayer = _player;
    _player = null;
    if (oldPlayer != null) await oldPlayer.dispose();

    final fallback = await _createLabelFallback(reason);
    if (!mounted) {
      await fallback.dispose();
      return;
    }
    _attachPlayer(fallback);
    setState(() {});
  }

  Future<void> _replay() async {
    if (_clips.isEmpty || _working || _playerLoading) return;
    setState(() {
      _working = true;
      _activeIndex = null;
      _message = null;
    });
    try {
      await _playClips(_clips);
    } on StateError catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Exception catch (error) {
      if (mounted) setState(() => _message = 'Could not replay signs: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_working || _playerLoading) return;

    if (_listening) {
      await _voiceSubscription?.cancel();
      await _speechInput.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }

    final available = await _speechInput.isAvailable();
    if (!available) {
      if (mounted) {
        setState(() => _message = 'Voice input is unavailable. Type instead.');
      }
      return;
    }

    final stream = _speechInput.listen();
    _voiceSubscription?.cancel();
    _voiceSubscription = stream.listen(
      (value) {
        if (!mounted) return;
        final nextText = value.trim();
        if (nextText.isEmpty) return;

        setState(() {
          _textController.text = nextText;
          _textController.selection = TextSelection.collapsed(
            offset: nextText.length,
          );
          _message = 'Voice input captured.';
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _message = 'Voice input failed: $error';
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _listening = false);
      },
    );

    if (mounted) {
      setState(() {
        _listening = true;
        _message = 'Listening…';
      });
    }
  }

  Future<void> _stop() async {
    try {
      await _player?.stop();
      if (mounted) setState(() => _working = false);
    } on StateError catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Exception catch (error) {
      if (mounted) setState(() => _message = 'Could not stop playback: $error');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    unawaited(_voiceSubscription?.cancel());
    unawaited(_speechInput.stop());
    unawaited(_playerEvents?.cancel());
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    final avatar = player is GlbPlayer
        ? player.buildView()
        : _MockAvatar(label: _avatarLabel, loading: _playerLoading);

    final modeBody = _mode == _TranslateMode.textToSign
        ? _buildTextToSignBody(avatar, player)
        : const SignToTextScreen();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SegmentedButton<_TranslateMode>(
              segments: const [
                ButtonSegment(
                  value: _TranslateMode.textToSign,
                  label: Text('Text to Sign'),
                ),
                ButtonSegment(
                  value: _TranslateMode.signToText,
                  label: Text('Sign to Text'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
              },
            ),
          ),
          Expanded(child: modeBody),
        ],
      ),
    );
  }

  Widget _buildTextToSignBody(Widget avatar, AvatarPlayer? player) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  avatar,
                  if (player is GlbPlayer)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _avatarLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  if (_working)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            children: [
              TextField(
                controller: _textController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                onSubmitted: _translateAndPlay,
                decoration: InputDecoration(
                  labelText: 'Text to sign',
                  hintText: 'Type a message',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _listening ? 'Stop voice input' : 'Use voice input',
                    onPressed: _working || _playerLoading ? null : _toggleVoiceInput,
                    icon: Icon(
                      _listening ? Icons.mic_off_rounded : Icons.mic_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _working || _playerLoading
                          ? null
                          : () => _translateAndPlay(_textController.text),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Translate and play'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _working ? 'Stop playback' : 'Replay signs',
                    onPressed: _working
                        ? _stop
                        : _clips.isEmpty
                        ? null
                        : _replay,
                    icon: Icon(
                      _working ? Icons.stop_rounded : Icons.replay_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Quick phrases',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: quickPhrases.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final phrase = quickPhrases[index];
                    return ActionChip(
                      label: Text(phrase),
                      onPressed: _working || _playerLoading
                          ? null
                          : () {
                              _textController.text = phrase;
                              _translateAndPlay(phrase);
                            },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gloss sequence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              if (_clips.isEmpty)
                const Text('Your sign sequence will appear here.')
              else
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _clips.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) => Chip(
                      backgroundColor: index == _activeIndex
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      label: Text(_clips[index].label),
                    ),
                  ),
                ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  semanticsLabel: _message,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MockAvatar extends StatelessWidget {
  const _MockAvatar({required this.label, required this.loading});

  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.accessibility_new_rounded,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          if (loading) const CircularProgressIndicator(),
          if (!loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
        ],
      ),
    );
  }
}
