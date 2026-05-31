import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/finance/api/synjones_client.dart';

void main() {
  group('SynjonesClient', () {
    test('Instantiation and basic state', () {
      final client = SynjonesClient();
      expect(client, isNotNull);
      expect(client.loggedIn, isFalse);
    });

    test('strEncForTest produces valid hex output', () {
      final result = SynjonesClient.strEncForTest('hello', 'a', 'b', 'c');
      expect(result.length, greaterThan(0));
      expect(result, matches(RegExp(r'^[0-9A-F]+$')));
    });

    test('strEncForTest produces 16*n hex chars (64*n bits)', () {
      // 4 char block → 64 bits → 16 hex chars
      final r4 = SynjonesClient.strEncForTest('test', '1', '2', '3');
      expect(r4.length, 16);
      // 8 chars → 2 blocks → 32 hex chars
      final r8 = SynjonesClient.strEncForTest('abcd1234', '1', '2', '3');
      expect(r8.length, 32);
      // Short (<4) works too
      final r1 = SynjonesClient.strEncForTest('a', '1', '2', '3');
      expect(r1.length, 16);
    });
  });
}
