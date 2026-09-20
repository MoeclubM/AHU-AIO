import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/adaptive_ui.dart';
import 'package:ahu_aio/miuix/miuix_components.dart';
import 'package:ahu_aio/miuix/miuix_theme.dart';
import 'package:ahu_aio/theme_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await ThemeManager().setUiMode(UiMode.miuix);
  });

  testWidgets('Miuix 模式：AdaptiveLogoutButton 呈现 MiuixDangerButton 与圆角退出图标', (
    tester,
  ) async {
    await ThemeManager().setUiMode(UiMode.miuix);
    bool clicked = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: miuixLightTheme(),
        home: Scaffold(
          body: Center(
            child: AdaptiveLogoutButton(
              onPressed: () => clicked = true,
              label: '退出登录',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MiuixDangerButton), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);

    final Size size = tester.getSize(find.byType(AdaptiveLogoutButton));
    expect(size.height, greaterThanOrEqualTo(50.0));

    await tester.tap(find.byType(AdaptiveLogoutButton));
    await tester.pumpAndSettle();
    expect(clicked, isTrue);
  });

  testWidgets(
    'MD3 模式：AdaptiveLogoutButton 呈现 FilledButton 且具有正确的 error 配色与高度',
    (tester) async {
      await ThemeManager().setUiMode(UiMode.material3);
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: material3LightTheme(),
          home: Scaffold(
            body: Center(
              child: AdaptiveLogoutButton(
                onPressed: () => clicked = true,
                label: '退出登录',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.text('退出登录'), findsOneWidget);

      final Size size = tester.getSize(find.byType(AdaptiveLogoutButton));
      expect(size.height, greaterThanOrEqualTo(50.0));

      final FilledButton button = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      final ColorScheme scheme = material3LightTheme().colorScheme;
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        scheme.error,
      );
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        scheme.onError,
      );

      await tester.tap(find.byType(AdaptiveLogoutButton));
      await tester.pumpAndSettle();
      expect(clicked, isTrue);
    },
  );

  testWidgets('showAdaptiveConfirmDialog 在 isDanger 为 true 时渲染取消与危险操作按钮', (
    tester,
  ) async {
    await ThemeManager().setUiMode(UiMode.miuix);
    bool? dialogResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: miuixLightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await showAdaptiveConfirmDialog(
                    context: context,
                    title: '退出登录',
                    content: const Text('确定要退出吗？'),
                    confirmText: '退出登录',
                    isDanger: true,
                  );
                },
                child: const Text('打开弹窗'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开弹窗'));
    await tester.pumpAndSettle();

    expect(find.text('退出登录'), findsNWidgets(2)); // title and button
    expect(find.text('确定要退出吗？'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);

    await tester.tap(find.text('退出登录').last);
    await tester.pumpAndSettle();

    expect(dialogResult, isTrue);
  });
}
