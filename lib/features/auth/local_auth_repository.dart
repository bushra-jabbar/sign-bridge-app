import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/interfaces/gloss_engine.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({this.prefs});

  SharedPreferences? prefs;
  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();

  static const String _usersKey = 'local_auth_users';
  static const String _currentUserKey = 'local_auth_current_user';

  Future<SharedPreferences> get _store async =>
      prefs ??= await SharedPreferences.getInstance();

  @override
  Stream<AppUser?> get user async* {
    yield await _loadCurrentUser();
    yield* _userController.stream;
  }

  Future<AppUser?> _loadCurrentUser() async {
    final prefs = await _store;
    final raw = prefs.getString(_currentUserKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return AppUser.fromMap(decoded);
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final prefs = await _store;
    final rawUsers = prefs.getStringList(_usersKey) ?? const <String>[];
    return rawUsers
        .map((entry) => jsonDecode(entry))
        .whereType<Map<String, dynamic>>()
        .toList(growable: true);
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await _store;
    await prefs.setStringList(
      _usersKey,
      users.map((user) => jsonEncode(user)).toList(growable: false),
    );
  }

  Future<void> _setCurrentUser(AppUser? user) async {
    final prefs = await _store;
    if (user == null) {
      await prefs.remove(_currentUserKey);
      return;
    }
    await prefs.setString(_currentUserKey, jsonEncode(user.toMap()));
  }

  @override
  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim();
    final users = await _loadUsers();
    final match = users.firstWhere(
      (user) => (user['email'] as String? ?? '').toLowerCase() ==
          normalizedEmail.toLowerCase(),
      orElse: () => const <String, dynamic>{},
    );

    if (match.isEmpty) {
      throw StateError('No account found with that email.');
    }

    final storedPassword = match['password'] as String? ?? '';
    if (storedPassword != password) {
      throw StateError('Incorrect password.');
    }

    final user = AppUser.fromMap(match);
    await _setCurrentUser(user);
    _userController.add(user);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    String displayName = 'User',
  }) async {
    final normalizedEmail = email.trim();
    final cleanDisplayName = displayName.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw StateError('Email and password are required.');
    }
    if (password.length < 6) {
      throw StateError('Password must be at least 6 characters long.');
    }

    final users = await _loadUsers();
    final exists = users.any(
      (user) =>
          (user['email'] as String? ?? '').toLowerCase() ==
          normalizedEmail.toLowerCase(),
    );
    if (exists) {
      throw StateError('An account with that email already exists.');
    }

    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      email: normalizedEmail,
      displayName: cleanDisplayName.isEmpty ? 'User' : cleanDisplayName,
      password: password,
    );
    users.add(user.toMap());
    await _saveUsers(users);
    await _setCurrentUser(user);
    _userController.add(user);
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw StateError('Email is required.');
    }
    if (newPassword.length < 6) {
      throw StateError('Password must be at least 6 characters long.');
    }

    final users = await _loadUsers();
    var updated = false;
    for (var index = 0; index < users.length; index++) {
      final user = users[index];
      if ((user['email'] as String? ?? '').toLowerCase() ==
          normalizedEmail.toLowerCase()) {
        user['password'] = newPassword;
        users[index] = user;
        updated = true;
        break;
      }
    }

    if (!updated) {
      throw StateError('No account found with that email.');
    }

    await _saveUsers(users);
    final current = await _loadCurrentUser();
    if (current != null &&
        current.email.toLowerCase() == normalizedEmail.toLowerCase()) {
      final refreshed = AppUser.fromMap(users.firstWhere(
        (user) =>
            (user['email'] as String? ?? '').toLowerCase() ==
            normalizedEmail.toLowerCase(),
      ));
      await _setCurrentUser(refreshed);
      _userController.add(refreshed);
    }
  }

  @override
  Future<void> signOut() async {
    await _setCurrentUser(null);
    _userController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final current = await _loadCurrentUser();
    if (current == null) {
      return;
    }

    final users = await _loadUsers();
    final filtered = users
        .where(
          (user) =>
              (user['email'] as String? ?? '').toLowerCase() !=
              current.email.toLowerCase(),
        )
        .toList(growable: true);

    await _saveUsers(filtered);
    await _setCurrentUser(null);
    _userController.add(null);
  }

  @override
  Future<void> updateProfile({String? displayName, String? email}) async {
    final current = await _loadCurrentUser();
    if (current == null) {
      throw StateError('Sign in to update your profile.');
    }

    final users = await _loadUsers();
    var found = false;
    for (var index = 0; index < users.length; index++) {
      final user = users[index];
      if ((user['email'] as String? ?? '').toLowerCase() ==
          current.email.toLowerCase()) {
        final nextDisplayName = displayName?.trim() ?? current.displayName;
        final nextEmail = email?.trim() ?? current.email;
        final updatedUser = AppUser(
          id: current.id,
          email: nextEmail,
          displayName: nextDisplayName.isEmpty ? current.displayName : nextDisplayName,
          password: user['password'] as String? ?? current.password,
        );
        users[index] = updatedUser.toMap();
        await _saveUsers(users);
        await _setCurrentUser(updatedUser);
        _userController.add(updatedUser);
        found = true;
        break;
      }
    }

    if (!found) {
      throw StateError('Profile could not be updated.');
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final current = await _loadCurrentUser();
    if (current == null) {
      throw StateError('Sign in to change your password.');
    }
    if (oldPassword != current.password) {
      throw StateError('Current password is incorrect.');
    }
    if (newPassword.length < 6) {
      throw StateError('Password must be at least 6 characters long.');
    }

    final users = await _loadUsers();
    final matchIndex = users.indexWhere(
      (user) =>
          (user['email'] as String? ?? '').toLowerCase() ==
          current.email.toLowerCase(),
    );

    if (matchIndex == -1) {
      throw StateError('Account not found.');
    }

    final updatedUser = AppUser(
      id: current.id,
      email: current.email,
      displayName: current.displayName,
      password: newPassword,
    );
    users[matchIndex] = updatedUser.toMap();
    await _saveUsers(users);
    await _setCurrentUser(updatedUser);
    _userController.add(updatedUser);
  }
}
