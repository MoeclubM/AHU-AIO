import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/adaptive_ui.dart';
import 'package:ahu_aio/miuix/liquid_glass_app_bar.dart';
import 'package:ahu_aio/miuix/miuix_theme.dart';
import 'package:ahu_aio/theme_manager.dart';

/// Material 3 纯度的回归测试。
///
/// MD3 模式必须完全遵守 Material 3 规范：不套 Miuix 的几何、不做居中标题、
/// 不退化成 Material 2 的转场。这些点在重构时极易被顺手改回去，所以固定成断言。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MD3 主题不做自定义覆盖', () {
    test('不强制顶栏标题居中（Android MD3 是左对齐）', () {
      for (final ThemeData theme in [
        material3LightTheme(),
        material3DarkTheme(),
        material3AmoledTheme(),
      ]) {
        expect(
          theme.appBarTheme.centerTitle,
          isNot(isTrue),
          reason: 'centerTitle: true 属于 iOS 约定，MD3 不该覆盖',
        );
      }
    });

    test('不覆盖顶栏高度（用框架默认 kToolbarHeight）', () {
      for (final ThemeData theme in [
        material3LightTheme(),
        material3DarkTheme(),
      ]) {
        expect(
          theme.appBarTheme.toolbarHeight,
          anyOf(isNull, kToolbarHeight),
          reason: '50 是 Miuix SmallTopAppBar 规格，MD3 必须用 64',
        );
      }
    });

    test('AMOLED 只压暗 surface 族，不改前景与语义色', () {
      final base = material3DarkTheme();
      final amoled = material3AmoledTheme();
      expect(amoled.colorScheme.surface, const Color(0xFF000000));
      expect(
        amoled.colorScheme.surfaceContainerLowest,
        const Color(0xFF000000),
      );
      // 前景色必须仍是原 scheme 的值，保证对比度语义不被绕过。
      expect(amoled.colorScheme.onSurface, base.colorScheme.onSurface);
      expect(
        amoled.colorScheme.onSurfaceVariant,
        base.colorScheme.onSurfaceVariant,
      );
      expect(amoled.colorScheme.primary, base.colorScheme.primary);
      expect(amoled.colorScheme.error, base.colorScheme.error);
      // 不该再单独覆写 AppBar 主题。
      expect(amoled.appBarTheme.backgroundColor, isNull);
    });

    test('关闭预测性返回也不用 Material 2 的 Zoom 转场', () {
      final theme = withPredictiveBack(material3LightTheme(), false);
      final builders = theme.pageTransitionsTheme.builders;
      expect(
        builders[TargetPlatform.android],
        isA<FadeForwardsPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.android],
        isNot(isA<ZoomPageTransitionsBuilder>()),
      );
      // 其他平台保持各自原生转场，不做显式覆盖。
      expect(builders[TargetPlatform.iOS], isNull);
      expect(builders[TargetPlatform.macOS], isNull);
    });

    test('开启预测性返回时保持框架默认（不设 pageTransitionsTheme）', () {
      final base = material3LightTheme();
      final theme = withPredictiveBack(base, true);
      expect(
        identical(theme.pageTransitionsTheme, base.pageTransitionsTheme),
        isTrue,
      );
    });
  });

  group('顶栏在 MD3 下不套 Miuix 规格', () {
    Future<void> pumpAppBar(WidgetTester tester, UiMode mode) async {
      // 直接切换全局主题管理器，模拟用户在设置里选了对应界面风格。
      await ThemeManager().setUiMode(mode);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeManager().isMaterial3
              ? material3LightTheme()
              : miuixLightTheme(),
          home: const Scaffold(appBar: LiquidGlassAppBar(title: Text('课程表'))),
        ),
      );
      await tester.pumpAndSettle();
    }

    tearDown(() async {
      await ThemeManager().setUiMode(UiMode.miuix);
    });

    testWidgets('MD3 顶栏高度是框架默认，不是 Miuix 的 50', (tester) async {
      await pumpAppBar(tester, UiMode.material3);
      final Size size = tester.getSize(find.byType(AppBar));
      expect(size.height, kToolbarHeight, reason: 'MD3 工具栏高 64；50 是 Miuix 规格');
      expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isNull);
    });

    testWidgets('Miuix 顶栏走自研 MiuixTopAppBar，不再是 Material AppBar', (
      tester,
    ) async {
      await pumpAppBar(tester, UiMode.miuix);
      expect(
        find.byType(MiuixTopAppBar),
        findsOneWidget,
        reason: 'Miuix 模式必须用自研 SmallTopAppBar，否则会带出 Material 的水波纹与图标规格',
      );
      expect(find.byType(AppBar), findsNothing);
      expect(
        tester.getSize(find.byType(MiuixTopAppBar)).height,
        MiuixTopAppBarDefaults.smallTopAppBarCenterHeight,
        reason: '官方 SmallTopAppBar 高度 50',
      );
    });

    testWidgets('Miuix 顶栏标题居中（有无操作图标都不偏）', (tester) async {
      for (final bool withActions in <bool>[false, true]) {
        await ThemeManager().setUiMode(UiMode.miuix);
        await tester.pumpWidget(
          MaterialApp(
            theme: miuixLightTheme(),
            home: Scaffold(
              appBar: LiquidGlassAppBar(
                title: const Text('课程表'),
                actions: withActions
                    ? <Widget>[
                        AdaptiveIconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final double barWidth = tester
            .getSize(find.byType(MiuixTopAppBar))
            .width;
        final double center = tester.getCenter(find.text('课程表')).dx;
        expect(
          center,
          moreOrLessEquals(barWidth / 2, epsilon: 1),
          reason: 'Compose SmallTopAppBar 把标题居中；withActions=$withActions',
        );
      }
    });

    testWidgets('Miuix 顶栏标题是 title3 + w500', (tester) async {
      await pumpAppBar(tester, UiMode.miuix);
      final Finder title = find.descendant(
        of: find.byType(MiuixTopAppBar),
        matching: find.text('课程表'),
      );
      expect(title, findsOneWidget);
      // 标题自身不带样式，规格由最近的 DefaultTextStyle 提供。
      final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
        find.ancestor(of: title, matching: find.byType(DefaultTextStyle)).first,
      );
      expect(style.style.fontWeight, FontWeight.w500);
      expect(
        style.style.fontSize,
        defaultTextStyles().title3.fontSize,
        reason: 'Compose 源码里 SmallTopAppBar 用 title3 的字号',
      );
    });
  });

  group('源码里不再出现 Material 2 的下拉与裸顶栏', () {
    /// 递归收集 lib/ 下的 Dart 源码。
    List<File> libSources() => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();

    /// 去掉注释，避免文档里提到组件名就误报。
    String stripComments(String text) => text
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
        .split('\n')
        .where((String line) => !line.trimLeft().startsWith('//'))
        .join('\n');

    test('没有 DropdownButton / DropdownButtonFormField / DropdownMenuItem', () {
      // 这三个组件是 Material 2 时代的产物，Flutter 从未把它们升级到 M3，
      // 所以在两套主题下都会渲染成 MD2。统一改用 AdaptiveDropdown。
      final RegExp md2 = RegExp(
        r'\bDropdownButton\b|\bDropdownButtonFormField\b|\bDropdownMenuItem\b',
      );
      final List<String> offenders = <String>[];
      for (final File file in libSources()) {
        if (md2.hasMatch(stripComments(file.readAsStringSync()))) {
          offenders.add(file.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: '这些文件仍在使用 MD2 下拉组件，请改用 AdaptiveDropdown：$offenders',
      );
    });

    test('顶栏统一走 LiquidGlassAppBar，不再裸用 AppBar', () {
      final RegExp raw = RegExp(r'(?<![A-Za-z_])AppBar\(');
      final List<String> offenders = <String>[];
      for (final File file in libSources()) {
        // 顶栏适配层自己当然要用 AppBar。
        if (file.path.endsWith('liquid_glass_app_bar.dart')) continue;
        final String text = file.readAsStringSync();
        if (raw.hasMatch(text)) offenders.add(file.path);
      }
      expect(
        offenders,
        isEmpty,
        reason: '这些文件还在裸用 Material AppBar，Miuix 模式会退化成 MD2 外观：$offenders',
      );
    });
  });
}
