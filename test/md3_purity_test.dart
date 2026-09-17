import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          home: const Scaffold(appBar: LiquidGlassAppBar(title: '课程表')),
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

    testWidgets('Miuix 顶栏仍是 50 高且居中', (tester) async {
      await pumpAppBar(tester, UiMode.miuix);
      final Size size = tester.getSize(find.byType(AppBar));
      expect(size.height, 50);
      expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    });
  });
}
