import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_bridge_app/core/db/csv_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads CSV headers, quoted commas, and a UTF-8 byte-order mark', () {
    final rows = parseCsvRows(
      '\uFEFFlanguage,display_text\n'
      'asl,"hello, friend"\n',
    );

    expect(rows, [
      {'language': 'asl', 'display_text': 'hello, friend'},
    ]);
  });

  test('starter lexicon asset contains 50 ASL signs', () async {
    final csv = await rootBundle.loadString(
      'assets/packs/asl/lexicon_seed.csv',
    );

    expect(parseCsvRows(csv), hasLength(50));
  });
}
