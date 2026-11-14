import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/interfaces/gloss_engine.dart';
import 'local_auth_repository.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _displayNameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  AppUser? _user;

  AuthRepository get _auth => widget.authRepository ?? LocalAuthRepository();

  @override
  void initState() {
    super.initState();
    _auth.user.listen((user) {
      if (!mounted) return;
      setState(() {
        _user = user;
        _displayNameController.text = user?.displayName ?? '';
      });
    });
    _loadUser();
  }

  Future<void> _loadUser() async {
    final current = await _auth.user.first;
    if (!mounted) return;
    setState(() {
      _user = current;
      _displayNameController.text = current?.displayName ?? '';
    });
  }

  Future<void> _saveProfile() async {
    try {
      await _auth.updateProfile(displayName: _displayNameController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      await _auth.changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      if (!mounted) return;
      _oldPasswordController.clear();
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    context.go('/settings');
  }

  Future<void> _deleteAccount() async {
    try {
      await _auth.deleteAccount();
      if (!mounted) return;
      context.go('/settings');
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null)
            const Card(
              child: ListTile(
                leading: Icon(Icons.person_off_rounded),
                title: Text('Not signed in'),
                subtitle: Text('Use the sign-in screen to continue.'),
              ),
            )
          else ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(user.displayName),
                subtitle: Text(user.email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save profile'),
            ),
            const SizedBox(height: 20),
            Text(
              'Change password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Update password'),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete account'),
            ),
          ],
          if (user == null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push('/login'),
              child: const Text('Go to sign in'),
            ),
          ],
        ],
      ),
    );
  }
}
