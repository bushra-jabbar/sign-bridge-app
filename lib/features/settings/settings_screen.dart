import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../core/db/database.dart';
import '../../core/interfaces/gloss_engine.dart';
import '../auth/local_auth_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.database});

  final AppDatabase database;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<String> _speedValues = ['Slow', 'Normal', 'Fast'];

  String _speed = 'Normal';
  String _theme = 'Light';
  String _language = 'ASL';
  AppUser? _user;
  final AuthRepository _auth = LocalAuthRepository();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _auth.user.listen((user) {
      if (!mounted) return;
      setState(() => _user = user);
    });
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.user.first;
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _speed = prefs.getString('avatar_speed') ?? 'Normal';
      _theme = prefs.getString('theme_mode') ?? 'Light';
      _language = prefs.getString('language') ?? 'ASL';
    });
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (!mounted) return;
    setState(() {
      switch (key) {
        case 'avatar_speed':
          _speed = value;
          break;
        case 'theme_mode':
          _theme = value;
          final appState = context.findAncestorStateOfType<SignBridgeAppState>();
          appState?.setThemeMode(value == 'Dark' ? ThemeMode.dark : ThemeMode.light);
          break;
        case 'language':
          _language = value;
          break;
      }
    });
  }

  void _cycleTheme() {
    final next = _theme == 'Light' ? 'Dark' : 'Light';
    _saveString('theme_mode', next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.speed_rounded),
            title: const Text('Avatar speed'),
            subtitle: Text(_speed),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down_rounded),
              onSelected: (value) => _saveString('avatar_speed', value),
              itemBuilder: (context) => _speedValues
                  .map((value) => PopupMenuItem(value: value, child: Text(value)))
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Theme'),
            subtitle: Text(_theme),
            onTap: _cycleTheme,
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Language'),
            subtitle: Text(_language),
            onTap: () => _saveString('language', 'ASL'),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Account'),
            subtitle: Text(
              _user == null ? 'Guest mode' : 'Signed in as ${_user!.displayName}',
            ),
            onTap: () => context.push(_user == null ? '/login' : '/account'),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_rounded),
            title: const Text('Onboarding'),
            subtitle: const Text('Review the welcome flow'),
            onTap: () => context.push('/onboarding'),
          ),
          ListTile(
            leading: const Icon(Icons.shield_rounded),
            title: const Text('Privacy'),
            subtitle: const Text('Offline-first'),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            subtitle: const Text('Offline-first ASL prototype'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sign Bridge',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    'Built for local-first ASL translation, avatar playback, and privacy-conscious use on Android devices.',
              );
            },
          ),
        ],
      ),
    );
  }
}
