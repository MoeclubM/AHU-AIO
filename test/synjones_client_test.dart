import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/finance/api/synjones_client.dart';

void main() {
  group('SynjonesClient', () {
    test('Instantiation and basic state', () {
      final client = SynjonesClient();
      expect(client, isNotNull);
      expect(client.loggedIn, isFalse);
    });

    test('extractWebLoginTicket only accepts Synjones encrypted ticket', () {
      final ticket = SynjonesClient.extractWebLoginTicket(
        'https://ycard.ahu.edu.cn/plat/?ticket=iFKYpYOO4abc',
      );
      expect(ticket, 'iFKYpYOO4abc');
      expect(
        SynjonesClient.extractWebLoginTicket(
          'https://jw.ahu.edu.cn/student/sso/login?ticket=ST-1-demo',
        ),
        isNull,
      );
    });
  });
}
