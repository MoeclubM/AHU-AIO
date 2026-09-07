import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/main_layout_screen.dart';

void main() {
  group('MainLayoutScreen calculateSubTabVisibility', () {
    test(
      'sub-tab bar stays at 1.0 (continuous display, never hides) for pages 0 to 2',
      () {
        // 0: 微教务
        expect(MainLayoutScreen.calculateSubTabVisibility(0.0), 1.0);
        expect(MainLayoutScreen.calculateSubTabVisibility(0.25), 1.0);
        expect(
          MainLayoutScreen.calculateSubTabVisibility(0.5),
          1.0,
          reason: '微教务与安大教务正中间时不应收起',
        );
        expect(MainLayoutScreen.calculateSubTabVisibility(0.75), 1.0);

        // 1: 安大教务
        expect(MainLayoutScreen.calculateSubTabVisibility(1.0), 1.0);
        expect(MainLayoutScreen.calculateSubTabVisibility(1.25), 1.0);
        expect(
          MainLayoutScreen.calculateSubTabVisibility(1.5),
          1.0,
          reason: '安大教务与一卡通正中间时不应收起',
        );
        expect(MainLayoutScreen.calculateSubTabVisibility(1.75), 1.0);

        // 2: 一卡通
        expect(MainLayoutScreen.calculateSubTabVisibility(2.0), 1.0);
      },
    );

    test(
      'sub-tab bar smoothly retracts between page 2 (一卡通) and page 3 (设置)',
      () {
        // 从一卡通(2.0)滑动向设置(3.0)
        // t = 0.25 (page = 2.25) -> 1.0 - 2.0 * 0.25 = 0.5
        expect(
          MainLayoutScreen.calculateSubTabVisibility(2.25),
          closeTo(0.5, 0.001),
        );

        // t = 0.5 (page = 2.5) -> 完全收起隐藏到底栏后面
        expect(MainLayoutScreen.calculateSubTabVisibility(2.5), 0.0);

        // t = 0.75 (page = 2.75) -> 保持隐藏
        expect(MainLayoutScreen.calculateSubTabVisibility(2.75), 0.0);
      },
    );

    test('sub-tab bar stays hidden (0.0) on page 3 (设置) and beyond', () {
      // 3: 设置
      expect(MainLayoutScreen.calculateSubTabVisibility(3.0), 0.0);
      expect(
        MainLayoutScreen.calculateSubTabVisibility(3.5),
        0.0,
        reason: '过度滑动设置页时保持隐藏',
      );
    });

    test('sub-tab bar stays at 1.0 for negative overshoot at page 0', () {
      expect(
        MainLayoutScreen.calculateSubTabVisibility(-0.2),
        1.0,
        reason: '第0页向左弹性回弹时不应异常闪烁',
      );
    });
  });
}
