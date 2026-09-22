import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahu_aio/update/github_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHubUpdateService dismiss tracking', () {
    test('dismissUpdate persists ignored tag', () async {
      SharedPreferences.setMockInitialValues({});
      final service = GitHubUpdateService();

      await service.dismissUpdate('v9.9.9');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('update_dismissed_tag'), 'v9.9.9');

      service.dispose();
    });
  });
}
