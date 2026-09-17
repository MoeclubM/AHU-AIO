import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/miuix/miuix_floating_bar.dart';
import 'package:ahu_aio/miuix/miuix_theme.dart';

/// 悬浮底栏的交互回归测试。
///
/// 这里刻意复刻生产结构（底栏作为 Stack 的上一层、悬浮在 PageView 之上），
/// 因为手势冲突只在真实层级下才会暴露：
/// - 旧实现用「外层横滑 GestureDetector + 条目各自点按 GestureDetector」，
///   两个识别器在手势竞技场里互相等待，实机上表现为**按住拖动完全没反应**；
/// - 现实现由单个 Listener 处理原始指针，同时判定点按与拖动（对齐 Compose
///   的 inspectDragGestures）。
///
/// 断言「手指位移多少，页面就位移多少」，防止再次回归为不动或不跟手。
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
    final dark = miuixColorsFromSeed(seed: const Color(0xFF3482FF), dark: true);
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
            // 与生产一致：页面在下、悬浮底栏作为上层。
            body: Stack(
              children: [
                PageView(
                  controller: controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (int i = 0; i < count; i++) Center(child: Text('页$i')),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MiuixFloatingTabBar(
                    controller: controller,
                    items: items,
                  ),
                ),
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

  testWidgets('拖动有效且跟手：位移等于手指位移，逐段单调推进', (tester) async {
    final controller = await pumpBar(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double tabWidth = tabWidthOf(tester, 4);
    final double left =
        barRect.left + MiuixFloatingBarDefaults.horizontalMargin;

    // 从第一个条目按下，保证右侧有足够行程（避免撞到末页被正确钳制）。
    final gesture = await tester.startGesture(
      Offset(left + tabWidth * 0.5, barRect.center.dy),
    );
    await tester.pump(const Duration(milliseconds: 16));
    // 越过触摸阈值，让手势进入拖动状态。
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final double start = controller.page!;
    expect(start, greaterThan(0.0), reason: '越过阈值后应立即产生位移（旧实现这里完全没有反应）');

    // 分成 4 段连续推进，每段位移都应真实生效且单调递增。
    double previous = start;
    for (int i = 0; i < 4; i++) {
      await gesture.moveBy(Offset(tabWidth / 4, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final double current = controller.page!;
      expect(
        current,
        greaterThan(previous + 0.1),
        reason: '每一段拖动都必须带动页面，不能出现"拖着不动"',
      );
      previous = current;
    }

    // 累计约一个条目宽度 → 累计位移约一页。
    expect(
      previous - start,
      closeTo(1.0, 0.25),
      reason: '拖动一个条目宽度后页面位移应约为一页（不得落后）',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.page!, closeTo(1.0, 0.2), reason: '松手后应停在最近的一页');
  });

  testWidgets('拖动中途指示器与页面同步（同源）', (tester) async {
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
    expect(controller.page!, greaterThan(0.2), reason: '半页拖动后页面应有可见位移');

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('轻点条目切换到对应页面（点按与拖动共存）', (tester) async {
    final controller = await pumpBar(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double tabWidth = tabWidthOf(tester, 4);
    final double left =
        barRect.left + MiuixFloatingBarDefaults.horizontalMargin;

    // 点击第 3 个条目（索引 2）。
    await tester.tapAt(Offset(left + tabWidth * 2.5, barRect.center.dy));
    await tester.pumpAndSettle();
    expect(controller.page!, closeTo(2.0, 0.05));
  });

  testWidgets('按住不动再松手视为点击（不误判为拖动）', (tester) async {
    final controller = await pumpBar(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double tabWidth = tabWidthOf(tester, 4);
    final double left =
        barRect.left + MiuixFloatingBarDefaults.horizontalMargin;

    final gesture = await tester.startGesture(
      Offset(left + tabWidth * 2.5, barRect.center.dy),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.page!, closeTo(2.0, 0.05), reason: '长按应视为点击该条目');
  });
}
