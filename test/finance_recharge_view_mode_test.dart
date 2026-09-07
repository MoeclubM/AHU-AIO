import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahu_aio/finance/pages/finance_recharge_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FinanceRechargePage view mode toggle and persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      financeRechargeIsListViewNotifier.value = false;
    });

    test('default view mode is grid (false)', () {
      expect(financeRechargeIsListViewNotifier.value, isFalse);
    });

    test('toggleViewMode toggles state and persists to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();

      // 切换为列表模式
      await FinanceRechargePage.toggleViewMode();
      expect(financeRechargeIsListViewNotifier.value, isTrue);
      expect(prefs.getBool('finance_recharge_is_list'), isTrue);

      // 切换回网格模式
      await FinanceRechargePage.toggleViewMode();
      expect(financeRechargeIsListViewNotifier.value, isFalse);
      expect(prefs.getBool('finance_recharge_is_list'), isFalse);
    });
  });
}
