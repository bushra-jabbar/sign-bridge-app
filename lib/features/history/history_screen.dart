import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/db/sqlite_history_repository.dart';
import '../../core/interfaces/avatar_player.dart';
import '../../core/interfaces/gloss_engine.dart';
import '../avatar/avatar_player_factory.dart';
import '../avatar/glb_player.dart';
import '../avatar/mock_player.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.database,
    this.historyRepository,
    this.avatarPlayer,
  });

  final AppDatabase database;
  final HistoryRepository? historyRepository;
  final AvatarPlayer? avatarPlayer;

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  late final HistoryRepository _history;
  late Future<List<HistoryEntry>> _entries;
  AvatarPlayer? _player;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _history =
        widget.historyRepository ?? SqliteHistoryRepository(widget.database);
    _entries = _history.recent(limit: 50);
  }

  void reload() {
    setState(() => _entries = _history.recent(limit: 50));
  }

  Future<void> _replay(HistoryEntry entry) async {
    if (_playing) return;
    setState(() => _playing = true);
    try {
      _player ??= widget.avatarPlayer ?? await createAvatarPlayer();
      try {
        await _player!.load();
        await _player!.play(entry.clips);
      } on StateError catch (error) {
        if (_player is! GlbPlayer) rethrow;
        await _replacePlayerWithMock();
        _showMessage(
          'A 3D animation was unavailable; replaying with labels instead. '
          '${error.message}',
        );
        await _player!.play(entry.clips);
      } on Exception catch (error) {
        if (_player is! GlbPlayer) rethrow;
        await _replacePlayerWithMock();
        _showMessage(
          'The 3D avatar could not play; replaying with labels instead. $error',
        );
        await _player!.play(entry.clips);
      }
    } on StateError catch (error) {
      _showMessage('Could not replay this translation: ${error.message}');
    } on Exception catch (error) {
      _showMessage('Could not replay this translation: $error');
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _replacePlayerWithMock() async {
    final oldPlayer = _player;
    _player = null;
    if (oldPlayer != null) await oldPlayer.dispose();
    final fallback = MockPlayer();
    await fallback.load();
    _player = fallback;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryEntry>>(
      future: _entries,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load history: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return const Center(
            child: Text('Your translations will appear here.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final localTime = entry.createdAt.toLocal();
            final gloss = entry.clips.map((clip) => clip.clip).join(' · ');
            final date = MaterialLocalizations.of(context)
                .formatShortDate(localTime);
            final time = TimeOfDay.fromDateTime(localTime).format(context);

            return Card(
              child: ListTile(
                title: Text(entry.inputText),
                subtitle: Text(
                  '$gloss\n$date at $time · ${entry.mode.replaceAll('_', ' ')}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Replay translation',
                  onPressed: _playing ? null : () => _replay(entry),
                  icon: const Icon(Icons.replay_rounded),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
