import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/miuix/miuix_theme.dart';
import 'package:ahu_aio/theme_manager.dart';
import 'package:ahu_aio/theme_settings_screen.dart';

/// 主题设置页的布局回归测试。
///
/// 设计稿里两种风格的布局是**相反**的，这点很容易在重构时又搞混：
/// - Miuix：所有行装在**同一张卡片**里，行内**没有**前置图标；
/// - MD3：**每行一张独立卡片**，行内**有**前置图标。
///
/// 另外界面的缩放是卡内**内联滑块**，不再走弹窗。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pump(WidgetTester tester, UiMode mode) async {
    // 主题设置页有 7 行，默认 800x600 的测试视口装不下最后一行的滑块，
    // 会让针对滑块的拖拽落在视口之外。
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await ThemeManager().setUiMode(mode);
    await tester.pumpWidget(
      MiuixTheme(
        data: MiuixThemeData.light(),
        child: MaterialApp(
          theme: ThemeManager().isMaterial3
              ? material3LightTheme()
              : miuixLightTheme(),
          home: const ThemeSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    await ThemeManager().setUiMode(UiMode.miuix);
  });

  testWidgets('Miuix：单张卡片装下所有行，且行内没有前置图标', (tester) async {
    await pump(tester, UiMode.miuix);

    // 只有一张卡片。
    expect(find.byType(MiuixCard), findsOneWidget);
    expect(find.byType(Card), findsNothing);

    // 行内不带图标：页头有一个返回箭头，其余 Icon 只应来自滑块/开关。
    expect(
      find.byIcon(Icons.blur_on_outlined),
      findsNothing,
      reason: 'Miuix 的行内不显示前置图标',
    );
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);

    // 六行都在（主题 / 界面风格 / 模糊 / 悬浮底栏 / 液态玻璃 / 预测性返回 / 缩放）
    for (final String title in <String>[
      '主题',
      '界面风格',
      '模糊',
      '悬浮底栏',
      '液态玻璃',
      '预测性返回手势',
      '界面缩放',
    ]) {
      expect(find.text(title), findsOneWidget, reason: '缺少「$title」行');
    }
  });

  testWidgets('MD3：每行一张独立卡片，且行内有前置图标', (tester) async {
    await pump(tester, UiMode.material3);

    expect(find.byType(Card), findsWidgets);
    expect(find.byType(MiuixCard), findsNothing);

    // 每行都有前置图标。
    for (final IconData icon in <IconData>[
      Icons.dark_mode_outlined,
      Icons.palette_outlined,
      Icons.color_lens_outlined,
      Icons.swipe_outlined,
      Icons.format_size_outlined,
    ]) {
      expect(find.byIcon(icon), findsOneWidget, reason: 'MD3 每行都应有前置图标');
    }

    // 卡片数量 = 行数。
    final Finder cards = find.byType(Card);
    expect(tester.widgetList(cards).length, greaterThanOrEqualTo(6));
  });

  testWidgets('界面缩放是卡内内联滑块，不是弹窗', (tester) async {
    for (final UiMode mode in <UiMode>[UiMode.miuix, UiMode.material3]) {
      await pump(tester, mode);
      expect(find.byType(Slider), findsOneWidget, reason: '$mode 下界面缩放应有内联滑块');
      // 不应弹出对话框。
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('确定'), findsNothing);
    }
  });

  testWidgets('缩放滑块直接改主题管理器，无需确认', (tester) async {
    await pump(tester, UiMode.miuix);
    final double before = ThemeManager().uiScale;
    addTearDown(() => ThemeManager().setUiScale(1.0));

    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(ThemeManager().uiScale, greaterThan(before), reason: '拖动滑块应即时生效');
  });

  testWidgets('Miuix 取值行带箭头，MD3 只有文本', (tester) async {
    await pump(tester, UiMode.miuix);
    expect(
      find.byIcon(Icons.unfold_more),
      findsWidgets,
      reason: 'Miuix 的取值选择器用上下双箭头',
    );

    await pump(tester, UiMode.material3);
    expect(
      find.byIcon(Icons.unfold_more),
      findsNothing,
      reason: 'MD3 取值行只显示文本',
    );
  });

  testWidgets('MD3 开关滑块带勾选图标', (tester) async {
    await pump(tester, UiMode.material3);
    final SwitchListTile tile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile).first,
    );
    expect(tile.thumbIcon, isNotNull, reason: 'MD3 开关在选中时显示勾号');
  });
}
