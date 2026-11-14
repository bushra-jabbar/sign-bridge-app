import 'package:flutter_test/flutter_test.dart';

import 'package:sign_bridge_app/app.dart';
import 'package:sign_bridge_app/core/db/database.dart';

void main() {
  testWidgets('app loads with Sign Bridge home screen', (tester) async {
    await tester.pumpWidget(SignBridgeApp(database: AppDatabase()));

    expect(find.text('Sign Bridge'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
  });
}
