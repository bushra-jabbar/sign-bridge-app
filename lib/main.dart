import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/db/database.dart';

ThemeMode _themeModeFromPreference(String? preference) {
  switch (preference) {
    case 'Dark':
      return ThemeMode.dark;
    case 'Light':
      return ThemeMode.light;
    default:
      return ThemeMode.light;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  await database.initialize();

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);
  final themeMode = _themeModeFromPreference(prefs.getString('theme_mode'));

  runApp(
    SignBridgeApp(
      database: database,
      showOnboarding: showOnboarding,
      themeMode: themeMode,
    ),
  );
}
