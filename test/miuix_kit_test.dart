import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/miuix/miuix_theme.dart';

/// 自研 Miuix 组件的规格回归测试。
///
/// 这些数字全部来自 compose-miuix-ui 的 Kotlin 源码，是「看起来像不像 HyperOS」
/// 的硬指标；换实现时最容易在这里悄悄跑偏，所以固定成断言。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// 用浅色 Miuix 主题包裹被测组件。
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MiuixTheme(
        data: MiuixThemeData.of(
          brightness,
          lightColors: lightColorScheme(),
          darkColors: darkColorScheme(),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Align(alignment: Alignment.topCenter, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MiuixColors', () {
    test('浅色方案使用 HyperOS 原值', () {
      final c = lightColorScheme();
      expect(c.primary, const Color(0xFF3482FF));
      expect(c.surface, const Color(0xFFF7F7F7));
      expect(c.surfaceContainer, const Color(0xFFFFFFFF));
      expect(c.onBackgroundVariant, const Color(0xFF8C93B0));
      expect(c.dividerLine, const Color(0xFFE0E0E0));
    });

    test('深色方案使用 HyperOS 原值', () {
      final c = darkColorScheme();
      expect(c.primary, const Color(0xFF277AF7));
      expect(c.background, const Color(0xFF242424));
      expect(c.surfaceContainer, const Color(0xFF242424));
    });

    test('种子取色得到的颜色全部不透明（带 alpha 的角色已合成）', () {
      for (final bool dark in [true, false]) {
        final c = miuixColorsFromSeed(
          seed: const Color(0xFF3482FF),
          dark: dark,
        );
        for (final Color color in [
          c.primary,
          c.disabledPrimary,
          c.disabledOnPrimary,
          c.disabledSecondary,
          c.disabledOnSecondaryVariant,
          c.onSurfaceSecondary,
          c.sliderBackground,
        ]) {
          expect(color.a, 1.0, reason: 'dark=$dark 出现半透明令牌');
        }
      }
    });

    test('copy 只覆盖指定字段', () {
      final base = darkColorScheme();
      final amoled = base.copy(
        background: const Color(0xFF000000),
        surfaceContainer: const Color(0xFF0A0A0A),
      );
      expect(amoled.background, const Color(0xFF000000));
      expect(amoled.surfaceContainer, const Color(0xFF0A0A0A));
      expect(amoled.primary, base.primary);
    });
  });

  group('主题文本体系', () {
    test('textTheme 映射到 Miuix 字号', () {
      final t = miuixLightTheme().textTheme;
      expect(t.displayLarge?.fontSize, 32);
      expect(t.displayMedium?.fontSize, 24);
      expect(t.displaySmall?.fontSize, 20);
      expect(t.titleLarge?.fontSize, 17);
      expect(t.bodyLarge?.fontSize, 17);
      expect(t.bodyMedium?.fontSize, 16);
      expect(t.bodySmall?.fontSize, 14);
      expect(t.labelMedium?.fontSize, 13);
      expect(t.labelSmall?.fontSize, 11);
    });

    test('字重偏移按 100 一档叠加', () {
      expect(
        const TextStyle(fontWeight: FontWeight.w400).withMiuixWeight(100),
        const TextStyle(fontWeight: FontWeight.w500),
      );
      expect(
        const TextStyle(fontWeight: FontWeight.w600).withMiuixWeight(100),
        const TextStyle(fontWeight: FontWeight.w700),
      );
      // 偏移 0 时原样返回，包含 null 字重。
      expect(const TextStyle().withMiuixWeight(0).fontWeight, isNull);
    });
  });

  group('MiuixNavigationBar（贴底栏）', () {
    testWidgets('条目高 64、图标 26、标签 12sp，选中加粗', (tester) async {
      await pump(
        tester,
        MiuixNavigationBar(
          children: [
            MiuixNavigationBarItem(
              selected: true,
              onPressed: () {},
              icon: const Icon(Icons.home),
              label: '首页',
            ),
            MiuixNavigationBarItem(
              selected: false,
              onPressed: () {},
              icon: const Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      );

      final items = find.byType(MiuixNavigationBarItem);
      expect(tester.getSize(items.at(0)).height, MiuixNavigationBar.itemHeight);
      expect(tester.getSize(find.byIcon(Icons.home)).width, 26);

      final selected = tester.widget<Text>(find.text('首页'));
      expect(selected.style?.fontSize, 12);
      expect(selected.style?.fontWeight, FontWeight.bold);

      final unselected = tester.widget<Text>(find.text('设置'));
      expect(unselected.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('未选中内容降到 40% 不透明度，选中为满不透明', (tester) async {
      await pump(
        tester,
        MiuixNavigationBar(
          children: [
            MiuixNavigationBarItem(
              selected: true,
              onPressed: () {},
              icon: const Icon(Icons.home),
              label: '首页',
            ),
            MiuixNavigationBarItem(
              selected: false,
              onPressed: () {},
              icon: const Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      );

      final base = lightColorScheme().onSurfaceContainer;
      final selectedColor = tester.widget<Text>(find.text('首页')).style?.color;
      final unselectedColor = tester.widget<Text>(find.text('设置')).style?.color;

      expect(selectedColor, base);
      expect(
        unselectedColor?.a,
        closeTo(MiuixNavigationBar.unselectedAlpha, 0.01),
      );
    });

    testWidgets('顶部有 0.5dp 分隔线，点按触发回调', (tester) async {
      int tapped = -1;
      await pump(
        tester,
        MiuixNavigationBar(
          children: [
            for (int i = 0; i < 2; i++)
              MiuixNavigationBarItem(
                selected: i == 0,
                onPressed: () => tapped = i,
                icon: const Icon(Icons.circle),
                label: '项$i',
              ),
          ],
        ),
      );

      // 分隔线：0.5dp 高、颜色取 dividerLine。
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == lightColorScheme().dividerLine,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('项1'));
      await tester.pump();
      expect(tapped, 1);
    });
  });

  group('MiuixTabRow（二级标签）', () {
    testWidgets('高 42、条目宽度落在 76–98、选中加粗', (tester) async {
      await pump(
        tester,
        MiuixTabRow(
          tabs: const ['全部', '本周', '下周', '考试'],
          selectedTabIndex: 1,
          onTabSelected: (_) {},
        ),
      );

      expect(tester.getSize(find.byType(MiuixTabRow)).height, 42);

      // 360 宽、4 个标签、间距 9：(360 - 27) / 4 = 83.25
      final double itemWidth = tester.getSize(find.text('全部')).width;
      expect(itemWidth, lessThanOrEqualTo(83.25 - 2 * 12 + 0.01));

      final bold = tester.widget<Text>(find.text('本周'));
      expect(bold.style?.fontWeight, FontWeight.bold);
      final normal = tester.widget<Text>(find.text('全部'));
      expect(normal.style?.fontWeight, FontWeight.normal);
      // 字号取 body1（16sp）。
      expect(bold.style?.fontSize, 16);
    });

    testWidgets('点按标签回调索引', (tester) async {
      int selected = 0;
      await pump(
        tester,
        MiuixTabRow(
          tabs: const ['全部', '本周', '下周'],
          selectedTabIndex: selected,
          onTabSelected: (i) => selected = i,
        ),
      );
      await tester.tap(find.text('下周'));
      await tester.pump();
      expect(selected, 2);
    });
  });

  group('MiuixSwitch / 设置行', () {
    testWidgets('开关轨道 49×28、滑块 20', (tester) async {
      await pump(tester, MiuixSwitch(value: true, onChanged: (_) {}));
      expect(
        tester.getSize(find.byType(MiuixSwitch)).width,
        MiuixSwitch.trackWidth,
      );
      expect(
        tester.getSize(find.byType(MiuixSwitch)).height,
        MiuixSwitch.trackHeight,
      );
    });

    testWidgets('开关行整行可点，点标题即切换', (tester) async {
      bool value = false;
      await pump(
        tester,
        MiuixSwitchPreference(
          title: '悬浮底栏',
          summary: '液态玻璃胶囊',
          value: value,
          onChanged: (v) => value = v,
        ),
      );

      final title = tester.widget<Text>(find.text('悬浮底栏'));
      expect(title.style?.fontSize, 17);
      final summary = tester.widget<Text>(find.text('液态玻璃胶囊'));
      expect(summary.style?.fontSize, 14);

      await tester.tap(find.text('悬浮底栏'));
      await tester.pump();
      expect(value, isTrue);
    });
  });

  group('MiuixButton', () {
    testWidgets('最小 58×40 且用 squircle 形状', (tester) async {
      await pump(
        tester,
        MiuixButton(onPressed: () {}, child: const Text('确定')),
      );

      final Size size = tester.getSize(find.byType(MiuixButton));
      expect(size.width, greaterThanOrEqualTo(MiuixButtonDefaults.minWidth));
      expect(size.height, greaterThanOrEqualTo(MiuixButtonDefaults.minHeight));

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MiuixButton),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final ShapeDecoration decoration = box.decoration as ShapeDecoration;
      expect(decoration.shape, isA<MiuixSquircleBorder>());
    });

    testWidgets('禁用时不响应点按', (tester) async {
      int taps = 0;
      await pump(
        tester,
        MiuixButton(
          onPressed: () => taps++,
          enabled: false,
          child: const Text('确定'),
        ),
      );
      await tester.tap(find.byType(MiuixButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });
  });

  group('MiuixSquircleBorder', () {
    test('胶囊边界退化为圆角矩形，路径非空', () {
      const border = MiuixSquircleBorder(cornerRadius: 100);
      final Path path = border.getOuterPath(const Rect.fromLTWH(0, 0, 200, 56));
      expect(path.getBounds().width, closeTo(200, 0.01));
      expect(path.contains(const Offset(100, 28)), isTrue);
      expect(path.contains(const Offset(1, 1)), isFalse);
    });
  });

  group('取色器', () {
    testWidgets('OKLCH 往返转换保持颜色基本不变', (tester) async {
      for (final Color color in [
        const Color(0xFF3482FF),
        const Color(0xFFE94634),
        const Color(0xFF00A870),
      ]) {
        final Oklch oklch = Oklch.fromColor(color);
        final Color back = oklch.toColor();
        // 感知均匀空间的往返误差应远小于 1/255。
        expect((back.r - color.r).abs(), lessThan(0.01));
        expect((back.g - color.g).abs(), lessThan(0.01));
        expect((back.b - color.b).abs(), lessThan(0.01));
      }
    });

    testWidgets('拖动面板回调新颜色', (tester) async {
      Color? picked;
      await pump(
        tester,
        MiuixColorPicker(
          color: const Color(0xFF3482FF),
          colorSpace: MiuixColorSpace.oklch,
          onColorChanged: (c) => picked = c,
        ),
      );

      final Finder panel = find
          .descendant(
            of: find.byType(MiuixColorPicker),
            matching: find.byType(CustomPaint),
          )
          .first;
      await tester.drag(panel, const Offset(-40, 20));
      await tester.pump();
      expect(picked, isNotNull);
      expect(picked, isNot(const Color(0xFF3482FF)));
    });
  });

  group('像素探针：卡片与贴底栏不出现内部压暗', () {
    /// 采样某点的颜色。
    ///
    /// `toImage()` 依赖真实的异步渲染，必须放在 [WidgetTester.runAsync] 里，
    /// 否则在 fake_async 时钟下永远不会完成（表现为测试挂起）。
    Future<Color> sample(WidgetTester tester, Offset point) async {
      final Color? result = await tester.runAsync(() async {
        final RenderRepaintBoundary boundary =
            tester.renderObject(find.byKey(const ValueKey('probe')))
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage();
        final ByteData data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final int x = point.dx.round();
        final int y = point.dy.round();
        final int offset = (y * image.width + x) * 4;
        final Color color = Color.fromARGB(
          data.getUint8(offset + 3),
          data.getUint8(offset),
          data.getUint8(offset + 1),
          data.getUint8(offset + 2),
        );
        image.dispose();
        return color;
      });
      return result!;
    }

    testWidgets('卡片内部是纯底色，未被阴影填黑', (tester) async {
      const Color cardColor = Color(0xFF3B82F6);
      await tester.pumpWidget(
        MiuixTheme(
          data: MiuixThemeData.light(),
          child: RepaintBoundary(
            key: const ValueKey('probe'),
            child: MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFFFFFFFF),
                body: Center(
                  child: MiuixCard(
                    colors: const MiuixCardColors(
                      color: cardColor,
                      contentColor: Colors.white,
                    ),
                    cornerRadius: 16,
                    insideMargin: const EdgeInsets.all(16),
                    child: const SizedBox(
                      width: 120,
                      height: 40,
                      child: Text('x'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(MiuixCard));
      final Offset topLeft = tester.getTopLeft(find.byType(MiuixCard));
      final Color center = await sample(
        tester,
        topLeft + Offset(size.width / 2, size.height / 2),
      );
      final Color outside = await sample(
        tester,
        topLeft + Offset(size.width / 2, -6),
      );

      expect(center, cardColor, reason: '卡片内部被阴影或半透明填充压暗了');
      expect(outside, const Color(0xFFFFFFFF), reason: '卡片外侧不应被填充');
    });

    testWidgets('贴底栏底色为 surface', (tester) async {
      await tester.pumpWidget(
        MiuixTheme(
          data: MiuixThemeData.light(),
          child: RepaintBoundary(
            key: const ValueKey('probe'),
            child: MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF00FF00),
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: MiuixNavigationBar(
                    defaultWindowInsetsPadding: false,
                    children: [
                      MiuixNavigationBarItem(
                        selected: true,
                        onPressed: () {},
                        icon: const Icon(Icons.home),
                        label: '首页',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final Offset topLeft = tester.getTopLeft(find.byType(MiuixNavigationBar));
      final Size size = tester.getSize(find.byType(MiuixNavigationBar));
      final Color bottom = await sample(
        tester,
        topLeft + Offset(size.width / 2, size.height - 4),
      );
      expect(bottom, lightColorScheme().surface);
    });
  });
}
