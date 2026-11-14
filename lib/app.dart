import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/db/database.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/account_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/privacy_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/translate/translate_screen.dart';

class SignBridgeApp extends StatefulWidget {
  const SignBridgeApp({
    super.key,
    required this.database,
    this.showOnboarding = false,
    this.themeMode = ThemeMode.light,
  });

  final AppDatabase database;
  final bool showOnboarding;
  final ThemeMode themeMode;

  @override
  State<SignBridgeApp> createState() => SignBridgeAppState();
}

class SignBridgeAppState extends State<SignBridgeApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
  }

  void setThemeMode(ThemeMode themeMode) {
    if (!mounted) return;
    setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: widget.showOnboarding ? '/onboarding' : '/',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(database: widget.database),
        ),
        GoRoute(
          path: '/translate',
          builder: (context, state) => TranslateScreen(database: widget.database),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => LibraryScreen(database: widget.database),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => HistoryScreen(database: widget.database),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsScreen(database: widget.database),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Sign Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      routerConfig: router,
    );
  }
}
