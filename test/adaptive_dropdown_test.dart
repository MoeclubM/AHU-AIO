import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/adaptive_dropdown.dart';
import 'package:ahu_aio/miuix/miuix_theme.dart';
import 'package:ahu_aio/theme_manager.dart';

/// 自适应下拉的回归测试。
///
/// Flutter 的 `DropdownButton` / `DropdownButtonFormField` 从来没升到 M3，两套
/// 主题下都是 MD2 外观，所以项目里统一换成 [AdaptiveDropdown]。这里固定住两套
/// 风格的行为：Miuix 用自绘菜单（无 Material 水波纹、HyperOS 的上下 chevron），
/// MD3 走框架的 M3 菜单。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const List<AdaptiveDropdownItem<String>> items =
      <AdaptiveDropdownItem<String>>[
        AdaptiveDropdownItem<String>(value: 'a', label: '选项一'),
        AdaptiveDropdownItem<String>(value: 'b', label: '选项二'),
      ];

  Future<void> pump(
    WidgetTester tester,
    UiMode mode, {
    required ValueChanged<String?> onChanged,
    String? value = 'a',
  }) async {
    await ThemeManager().setUiMode(mode);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeManager().isMaterial3
            ? material3LightTheme()
            : miuixLightTheme(),
        home: Scaffold(
          body: Center(
            child: AdaptiveDropdown<String>(
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await ThemeManager().setUiMode(UiMode.miuix);
  });

  testWidgets('Miuix：菜单能打开、选中态打勾、点选回调正确', (tester) async {
    String? picked;
    await pump(tester, UiMode.miuix, onChanged: (String? v) => picked = v);

    // 触发器显示当前值，且是 HyperOS 的上下 chevron 而不是 Material 三角。
    expect(find.text('选项一'), findsOneWidget);

    await tester.tap(find.text('选项一'));
    await tester.pumpAndSettle();

    expect(find.text('选项二'), findsWidgets, reason: '菜单里应该列出全部选项');
    expect(find.byIcon(Icons.check), findsOneWidget, reason: '选中项要打勾');

    await tester.tap(find.text('选项二').last);
    await tester.pumpAndSettle();
    expect(picked, 'b');
  });

  testWidgets('MD3：用框架 M3 菜单（MenuAnchor + MenuItemButton）', (tester) async {
    String? picked;
    await pump(tester, UiMode.material3, onChanged: (String? v) => picked = v);

    expect(find.byType(MenuAnchor), findsOneWidget);

    await tester.tap(find.text('选项一'));
    await tester.pumpAndSettle();

    expect(find.byType(MenuItemButton), findsNWidgets(2));
    await tester.tap(find.text('选项二').last);
    await tester.pumpAndSettle();
    expect(picked, 'b');
  });

  testWidgets('Miuix：禁用时不打开菜单', (tester) async {
    await ThemeManager().setUiMode(UiMode.miuix);
    await tester.pumpWidget(
      MaterialApp(
        theme: miuixLightTheme(),
        home: const Scaffold(
          body: Center(
            child: AdaptiveDropdown<String>(
              value: 'a',
              items: items,
              onChanged: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('选项一'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  test('MiuixSquircleBorder 可作为 OutlinedBorder 使用（MenuStyle.shape 要求）', () {
    const MiuixSquircleBorder border = MiuixSquircleBorder(cornerRadius: 16);
    expect(border, isA<OutlinedBorder>());
    expect(border.copyWith(), isA<OutlinedBorder>());
  });
}
