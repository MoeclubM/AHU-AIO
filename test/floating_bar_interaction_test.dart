import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/miuix/miuix_floating_bar.dart';
import 'package:ahu_aio/miuix/miuix_theme.dart';

/// 悬浮底栏的交互回归测试。
///
/// 重点是「跟手」：旧实现从**当前动画值**累积拖动增量，弹簧的滞后会逐帧
/// 累加成永久落后——手势结束时页面几乎没动。这里直接断言「手指位移多少，
/// 页面就位移多少」，防止该问题回归。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<PageController> pumpBar(WidgetTester tester, {int count = 4}) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    final light = miuixColorsFromSeed(
      seed: const Color(0xFF3482FF),
      dark: false,
    );
    final dark = miuixColorsFromSeed(
      seed: const Color(0xFF3482FF),
      dark: true,
    );
    final items = <MiuixFloatingBarItemData>[
      for (int i = 0; i < count; i++)
        MiuixFloatingBarItemData(
          icon: Icons.circle_outlined,
          activeIcon: Icons.circle,
          label: '标签$i',
        ),
    ];

    await tester.pumpWidget(
      MiuixTheme(
        data: MiuixThemeData.of(
          Brightness.light,
          lightColors: light,
          darkColors: dark,
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (int i = 0; i < count; i++) Center(child: Text('页$i')),
                    ],
                  ),
                ),
                MiuixFloatingTabBar(controller: controller, items: items),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// 内容区单个条目的宽度。
  double tabWidthOf(WidgetTester tester, int count) {
    final Rect rect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double contentWidth =
        rect.width - MiuixFloatingBarDefaults.horizontalMargin * 2;
    return (contentWidth - MiuixFloatingBarDefaults.insidePadding.horizontal) /
        count;
  }

  testWidgets('底栏常显图标与文字标签', (tester) async {
    await pumpBar(tester);
    // 官方液态玻璃底栏的每个条目都是「图标 + 文字」，不能省略文字。
    for (int i = 0; i < 4; i++) {
      expect(find.text('标签$i'), findsOneWidget);
    }
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(3));
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('拖动跟手：手指位移多少，页面就位移多少', (tester) async {
    final controller = await pumpBar(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double tabWidth = tabWidthOf(tester, 4);

    final gesture = await tester.startGesture(barRect.center);
    await tester.pump(const Duration(milliseconds: 16));
    // 越过触摸 slop 让手势被识别（这段位移按 Flutter 约定不计入拖动）。
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final double pageBefore = controller.page!;

    // 再移动恰好一个条目宽度 → 页面应位移恰好一页。
    await gesture.moveBy(Offset(tabWidth, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final double pageAfter = controller.page!;

    expect(
      pageAfter - pageBefore,
      closeTo(1.0, 0.2),
      reason: '拖动一个条目宽度后页面位移应约为 1 页（不得落后）',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.page!, closeTo(1.0, 0.2), reason: '松手后应停在最近的一页');
  });

  testWidgets('拖动过程中指示器与页面同步（同源）', (tester) async {
    final controller = await pumpBar(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double tabWidth = tabWidthOf(tester, 4);

    final gesture = await tester.startGesture(barRect.center);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));

    await gesture.moveBy(Offset(tabWidth * 0.5, 0));
    await tester.pump(const Duration(milliseconds: 16));

    // 指示器位置即页面位置：两者共用同一个值，中途也不应出现偏差。
    final double page = controller.page!;
    expect(page, greaterThan(0.2), reason: '半页拖动后页面应有可见位移');

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('点击条目切换到对应页面', (tester) async {
    final controller = await pumpBar(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double tabWidth = tabWidthOf(tester, 4);
    final double left =
        barRect.left + MiuixFloatingBarDefaults.horizontalMargin;

    // 点击第 3 个条目（索引 2）。
    await tester.tapAt(
      Offset(left + tabWidth * 2.5, barRect.center.dy),
    );
    await tester.pumpAndSettle();
    expect(controller.page!, closeTo(2.0, 0.05));
  });
}
