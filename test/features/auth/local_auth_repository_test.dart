import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_bridge_app/features/auth/local_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers, signs in, and signs out a local user', () async {
    SharedPreferences.setMockInitialValues({});

    final auth = LocalAuthRepository();
    await auth.register(
      email: 'demo@example.com',
      password: 'secret123',
      displayName: 'Demo User',
    );

    expect((await auth.user.first)!.email, 'demo@example.com');

    await auth.signOut();
    expect(await auth.user.first, isNull);

    await auth.signIn('demo@example.com', 'secret123');
    expect((await auth.user.first)!.displayName, 'Demo User');
  });
}
