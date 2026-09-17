import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/miuix/liquid_glass_layer.dart';
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

  // ─────────────────────────────────────────────────────────────────────
  // 像素探针：静止态也必须能看出玻璃胶囊
  //
  // 曾经的 bug：静止时胶囊画的是「关闭模糊」回退分支的 `accent@0.15` 平涂，
  // 叠在半透明栏面上几乎不可见，只有按住时 BloomStroke 高光亮起才"看起来有玻璃"。
  // 官方 `LiquidGlassNavigationBar.kt` 的静止态其实是 `onDrawSurface` 画的
  // `black@0.1`（深色 `white@0.1`）面纱，所以这里用像素断言把它钉死。
  // ─────────────────────────────────────────────────────────────────────

  /// 灰底页面 + 悬浮底栏，返回可采样像素的探针。
  ///
  /// 页面刻意用中灰：白色页面上高光会被 255 截断，测不出玻璃高光。
  Future<_Probe> pumpProbe(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = PageController();
    addTearDown(controller.dispose);
    final items = <MiuixFloatingBarItemData>[
      for (int i = 0; i < 4; i++)
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
          lightColors: lightColorScheme(),
          darkColors: darkColorScheme(),
        ),
        child: MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('probe'),
            child: Scaffold(
              body: Stack(
                children: [
                  const ColoredBox(
                    color: Color(0xFF808080),
                    child: SizedBox.expand(),
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
      ),
    );
    await tester.pumpAndSettle();
    return _Probe(tester, controller);
  }

  testWidgets('静止时选中胶囊就是可见玻璃（不依赖按压）', (tester) async {
    final probe = await pumpProbe(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double tabWidth = tabWidthOf(tester, 4);
    final double contentLeft =
        barRect.left +
        MiuixFloatingBarDefaults.horizontalMargin +
        MiuixFloatingBarDefaults.insidePadding.left;
    final double midY = barRect.center.dy;

    final _Pixels px = await probe.capture();
    final double onPill = px.luminance((contentLeft + 8).round(), midY.round());
    final double onBar = px.luminance(
      (contentLeft + tabWidth + 8).round(),
      midY.round(),
    );
    debugPrint('静止：胶囊=$onPill 栏面=$onBar');

    expect(
      onPill,
      lessThan(onBar - 0.02),
      reason: '静止态胶囊必须比栏面暗一层（官方 10% 面纱），否则看起来根本没有指示器',
    );
  });

  testWidgets('按压驱动胶囊折射（静止无折射，按下才有透镜）', (tester) async {
    await pumpProbe(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));
    final double contentLeft =
        barRect.left +
        MiuixFloatingBarDefaults.horizontalMargin +
        MiuixFloatingBarDefaults.insidePadding.left;

    // 胶囊那层玻璃的 padding 是 8，底栏那层是 24，以此区分。
    LiquidGlassLayer pillLayer() {
      final Iterable<LiquidGlassLayer> layers = tester
          .widgetList<LiquidGlassLayer>(find.byType(LiquidGlassLayer))
          .where((l) => l.padding == 8);
      expect(layers, isNotEmpty, reason: '胶囊应使用液态玻璃层');
      return layers.first;
    }

    // 静止：参考库只在按压时给胶囊加透镜，所以此时折射应几乎为 0
    // （按压弹簧是渐近收敛的，允许极小残值）。
    expect(
      pillLayer().refractionAmount,
      lessThan(0.5),
      reason: '静止态胶囊不应有折射（参考库的 lens 由 pressProgress 驱动）',
    );

    final gesture = await tester.startGesture(
      Offset(contentLeft + 10, barRect.center.dy),
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final LiquidGlassLayer pressed = pillLayer();
    expect(pressed.refractionAmount, greaterThan(0), reason: '按压应给胶囊加上透镜');
    expect(
      pressed.dispersion,
      greaterThan(0),
      reason: '参考库按压态带色散（chromaticAberration = 0.5）',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(pillLayer().refractionAmount, lessThan(0.5), reason: '松手后折射应回到 0');
  });

  testWidgets('底栏常开 24dp 折射（玻璃质感的主体）', (tester) async {
    await pumpProbe(tester);
    final Iterable<LiquidGlassLayer> bars = tester
        .widgetList<LiquidGlassLayer>(find.byType(LiquidGlassLayer))
        .where((l) => l.refractionHeight == 24);
    expect(bars, isNotEmpty, reason: '底栏应常开 lens(24dp, 24dp)，这是玻璃质感的主体');
    expect(bars.first.blurSigma, greaterThan(0), reason: '底栏背景应带模糊');
  });
  testWidgets('按压时底栏本身不缩放，只有胶囊胀大', (tester) async {
    final probe = await pumpProbe(tester);
    final Rect barRect = tester.getRect(find.byType(MiuixFloatingTabBar));

    /// 从左侧扫出玻璃边缘的 x：底栏玻璃比页面灰底亮。
    Future<double> glassLeftEdge() async {
      final _Pixels px = await probe.capture();
      final int y = barRect.center.dy.round();
      for (int x = 0; x < px.width; x++) {
        if (px.luminance(x, y) > 0.55) return x.toDouble();
      }
      return -1;
    }

    final double restEdge = await glassLeftEdge();
    // 玻璃左右各有 24dp 外边距，所以静止时的左边缘就在这里。
    expect(
      restEdge,
      closeTo(barRect.left + MiuixFloatingBarDefaults.horizontalMargin, 2),
      reason: '静止时玻璃左边缘应落在左边距处',
    );

    // 按住最后一个条目：胶囊在右侧胀大，不会影响左侧边缘。
    final gesture = await tester.startGesture(
      Offset(
        barRect.right - MiuixFloatingBarDefaults.horizontalMargin - 20,
        barRect.center.dy,
      ),
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      await glassLeftEdge(),
      closeTo(restEdge, 2),
      reason: '按压只让胶囊胀大（液滴效果），底栏整体不能缩放',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('子栏槽位给玻璃留出取样空间，不会切掉上半边', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MiuixTheme(
        data: MiuixThemeData.of(
          Brightness.light,
          lightColors: lightColorScheme(),
          darkColors: darkColorScheme(),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixFloatingSubBarSlot(
                    visibility: 1,
                    child: MiuixFloatingTabBar(
                      controller: controller,
                      height: MiuixFloatingBarDefaults.subBarHeight,
                      iconSize: MiuixFloatingBarDefaults.subIconSize,
                      fontSize: MiuixFloatingBarDefaults.subLabelFontSize,
                      items: const <MiuixFloatingBarItemData>[
                        MiuixFloatingBarItemData(
                          icon: Icons.circle_outlined,
                          activeIcon: Icons.circle,
                          label: '标签',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect clip = tester.getRect(find.byType(ClipRect));
    final Rect bar = tester.getRect(find.byType(MiuixFloatingTabBar));

    // 玻璃的折射要往形状外取样，裁剪窗口必须比子栏本身高出一圈，
    // 否则上半边的折射取样被切掉，看起来就是「玻璃缺了上半部分」。
    expect(
      bar.top - clip.top,
      greaterThanOrEqualTo(MiuixFloatingBarDefaults.refractionPad),
      reason: '槽位上方必须留出折射取样空间',
    );
    expect(
      clip.bottom - bar.bottom,
      greaterThanOrEqualTo(MiuixFloatingSubBarSlot.gap),
      reason: '槽位下方要留出与主栏的间距',
    );
    expect(clip.height, MiuixFloatingSubBarSlot.slotHeight);
  });
}

/// 悬浮底栏测试用的像素探针。
class _Probe {
  _Probe(this.tester, this.controller);

  final WidgetTester tester;
  final PageController controller;

  /// 读取渲染结果（`toImage` 依赖真实异步，必须放在 `runAsync` 里）。
  Future<_Pixels> capture() async {
    final _Pixels? result = await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          tester.renderObject(find.byKey(const ValueKey('probe')))
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage();
      final ByteData data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final _Pixels pixels = _Pixels(
        width: image.width,
        height: image.height,
        rgba: data.buffer.asUint8List(),
      );
      image.dispose();
      return pixels;
    });
    return result!;
  }
}

/// 一次渲染结果的 RGBA 像素。
class _Pixels {
  _Pixels({required this.width, required this.height, required this.rgba});

  final int width;
  final int height;
  final Uint8List rgba;

  /// 相对亮度（0–1）：判断"亮/暗"比单看某个通道稳。
  double luminance(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    final int i = (y * width + x) * 4;
    return (0.2126 * rgba[i] + 0.7152 * rgba[i + 1] + 0.0722 * rgba[i + 2]) /
        255.0;
  }

  /// 区域内最大亮度，用于检测细窄的边缘高光。
  double maxLuminance(Rect rect) {
    double best = 0;
    for (int y = rect.top.round(); y < rect.bottom.round(); y++) {
      for (int x = rect.left.round(); x < rect.right.round(); x++) {
        final double value = luminance(x, y);
        if (value > best) best = value;
      }
    }
    return best;
  }
}
