import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/finance/api/synjones_client.dart';

void main() {
  group('SynjonesClient strEnc (CAS des.js port)', () {
    test('Single 4-char block: abcd', () {
      const expected = 'A9CF2704230383D1';
      final result = SynjonesClient.strEncForTest('abcd', '1', '2', '3');
      expect(
        result,
        expected,
        reason: "'abcd' encrypted with keys (1,2,3) should match JS strEnc",
      );
    });

    test('Single 4-char block: 1234', () {
      const expected = 'C1BB5938DF9F2190';
      final result = SynjonesClient.strEncForTest('1234', '1', '2', '3');
      expect(result, expected);
    });

    test('Two blocks: abcd1234', () {
      const expected =
          'A9CF2704230383D1'
          'C1BB5938DF9F2190';
      final result = SynjonesClient.strEncForTest('abcd1234', '1', '2', '3');
      expect(result, expected);
    });

    test('Multi-block: full 48-char string', () {
      // Reference from JS des.js:
      // strEnc('abcd1234efgh5678ijkl90abmnop1234qrst5678uvwx90ABCDEFGH','1','2','3')
      const expected =
          'A9CF2704230383D1'
          'C1BB5938DF9F2190'
          'EEE0EB174D2B1826'
          'B89172CB54C8C33A'
          'F6887C6B63A53463'
          'BEB58204744CA7CF'
          '2214BB0E274E837C'
          'C1BB5938DF9F2190'
          'F47FCE659DE78CEC'
          'B89172CB54C8C33A'
          '423CFB3F30B5FAB1'
          'BA9FE5BED28FA9B3'
          '668D4DDA164E1F2E'
          '9B39B95707409BC8';

      final result = SynjonesClient.strEncForTest(
        'abcd1234efgh5678ijkl90abmnop1234qrst5678uvwx90ABCDEFGH',
        '1',
        '2',
        '3',
      );
      expect(result, expected);
    });

    test('strEnc validates hex output', () {
      final result = SynjonesClient.strEncForTest('hello', 'a', 'b', 'c');
      expect(result.length, greaterThan(0));
      expect(result, matches(RegExp(r'^[0-9A-F]+$')));
    });
  });
}
