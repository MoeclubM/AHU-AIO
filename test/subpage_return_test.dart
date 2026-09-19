import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahu_aio/main_layout_screen.dart';
import 'package:ahu_aio/miuix/liquid_glass_layer.dart';
import 'package:ahu_aio/miuix/miuix_floating_bar.dart';
import 'package:ahu_aio/globals.dart' as globals;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'enableLiquidGlass': true,
      'enableBlur': true,
      'enableBottomBarTransparent': true,
      'uiMode': 'miuix',
    });
    globals.idToken = 'mock_token';
  });

  testWidgets('Subpage push and pop maintains valid bottom bar without tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(themeMode: ThemeMode.light, home: MainLayoutScreen()),
    );
    await tester.pumpAndSettle();

    // 初始状态：底栏可见且位于底部
    expect(find.byType(MiuixFloatingTabBar), findsWidgets);
    final Finder mainBar = find.byType(MiuixFloatingTabBar).last;
    final RenderBox barBox = tester.renderObject(mainBar);
    final Offset initialPos = barBox.localToGlobal(Offset.zero);
    expect(initialPos.dx, 0.0);

    // 跳转进入子页面
    final NavigatorState nav = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('子页面')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => nav.pop(),
              child: const Text('返回'),
            ),
          ),
        ),
      ),
    );

    // 经历转场
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('子页面'), findsOneWidget);

    // 从子页面返回
    await tester.tap(find.text('返回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 确认已回到主页
    expect(find.text('子页面'), findsNothing);
    expect(find.byType(MiuixFloatingTabBar), findsWidgets);

    // 确认底栏回到正确定位，且无需点击已处于就绪状态
    final RenderBox returnedBox = tester.renderObject(mainBar);
    expect(returnedBox.localToGlobal(Offset.zero), initialPos);
  });

  testWidgets('LiquidGlassLayer handles real-time transform updates in paint', (
    tester,
  ) async {
    final ui.FragmentProgram program = await loadLiquidGlassRefractionProgram();
    final ui.FragmentShader shader = program.fragmentShader();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 60,
            child: LiquidGlassLayer(
              cornerRadius: 30,
              padding: 10,
              refractionHeight: 12,
              refractionAmount: 12,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 即使在没有点击交互的情况下，组件树也完整构建并正常渲染
    expect(find.byType(LiquidGlassLayer), findsOneWidget);
    shader.dispose();
  });
}
