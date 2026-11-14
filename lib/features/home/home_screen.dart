import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../history/history_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../translate/translate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.database});

  final AppDatabase database;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<HistoryScreenState> _historyKey =
      GlobalKey<HistoryScreenState>();
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TranslateScreen(database: widget.database),
      LibraryScreen(database: widget.database),
      HistoryScreen(key: _historyKey, database: widget.database),
      SettingsScreen(database: widget.database),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Bridge')),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) _historyKey.currentState?.reload();
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.translate_rounded),
            label: 'Translate',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
