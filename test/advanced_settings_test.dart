import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahu_aio/auth/auth_manager.dart';
import 'package:ahu_aio/advanced_settings_screen.dart';
import 'package:ahu_aio/app_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthManager unit tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default behavior is unified', () {
      final manager = AuthManager();
      expect(manager.behavior, AuthBehavior.unified);
      expect(manager.isUnified, isTrue);
      expect(manager.isIndependent, isFalse);
    });

    test('setBehavior updates and persists to SharedPreferences', () async {
      final manager = AuthManager();
      await manager.setBehavior(AuthBehavior.independent);

      expect(manager.behavior, AuthBehavior.independent);
      expect(manager.isIndependent, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_behavior'), 'independent');

      // Switch back
      await manager.setBehavior(AuthBehavior.unified);
      expect(manager.behavior, AuthBehavior.unified);
      expect(prefs.getString('auth_behavior'), 'unified');
    });

    test('loadConfig restores saved preference', () async {
      SharedPreferences.setMockInitialValues({'auth_behavior': 'independent'});
      final manager = AuthManager();
      await manager.loadConfig();

      expect(manager.behavior, AuthBehavior.independent);

      // Clean up
      await manager.setBehavior(AuthBehavior.unified);
    });

    test('platform passwords fallback to unified password in unified mode', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password', 'unifiedPass123');
      await prefs.setString('jwapp_password', 'jwappPass456');

      final manager = AuthManager();
      await manager.setBehavior(AuthBehavior.unified);

      // In unified mode, all should return unified password
      expect(await manager.getJwappPassword(), 'unifiedPass123');
      expect(await manager.getJwPassword(), 'unifiedPass123');
      expect(await manager.getFinancePassword(), 'unifiedPass123');

      // In independent mode, platform specific password should be preferred
      await manager.setBehavior(AuthBehavior.independent);
      expect(await manager.getJwappPassword(), 'jwappPass456');
      expect(await manager.getJwPassword(), 'unifiedPass123', reason: 'falls back if not set');

      await manager.savePlatformPassword('jw', 'jwPass789');
      expect(await manager.getJwPassword(), 'jwPass789');

      // Clean up
      await manager.setBehavior(AuthBehavior.unified);
    });
  });

  group('AdvancedSettingsScreen widget tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('displays 密码认证行为 and switches between options via bottom sheet',
        (tester) async {
      final manager = AuthManager();
      await manager.setBehavior(AuthBehavior.unified);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdvancedSettingsScreen(),
        ),
      );
      await tester.pump();

      // Check title and item
      expect(find.text('高级'), findsOneWidget);
      expect(find.text('密码认证行为'), findsOneWidget);
      expect(find.text('统一密码认证'), findsWidgets);

      // In unified mode, shows info card
      expect(find.textContaining('当前为统一密码认证模式'), findsOneWidget);
      expect(find.text('微教务平台'), findsNothing);

      // Tap 密码认证行为 to open bottom sheet
      await tester.tap(find.text('密码认证行为'));
      await tester.pumpAndSettle();

      // Check options in modal bottom sheet
      expect(find.text('统一密码认证'), findsWidgets);
      expect(find.text('独立密码认证'), findsOneWidget);
      expect(find.text('各业务平台使用各自独立的账号密码分别认证与维护'), findsOneWidget);

      // Tap 独立密码认证
      await tester.tap(find.text('独立密码认证'));
      await tester.pumpAndSettle();

      // Verify AuthManager updated and persisted
      expect(manager.behavior, AuthBehavior.independent);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_behavior'), 'independent');

      // Verify UI updated to independent mode with 3 platform boxes and verification buttons
      expect(find.text('独立密码认证'), findsWidgets);
      expect(find.text('独立密码配置'), findsOneWidget);
      expect(find.text('认证学号/账号'), findsOneWidget);
      expect(find.text('微教务平台'), findsOneWidget);
      expect(find.text('安大教务系统 (CAS)'), findsOneWidget);
      expect(find.text('一卡通系统 (CAS)'), findsOneWidget);
      expect(find.text('验证'), findsNWidgets(3));

      // Clean up
      await manager.setBehavior(AuthBehavior.unified);
    });

    testWidgets('shows warning when tapping 验证 with empty fields in independent mode',
        (tester) async {
      final manager = AuthManager();
      await manager.setBehavior(AuthBehavior.independent);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdvancedSettingsScreen(),
        ),
      );
      await tester.pump();

      // Tap first 验证 button with empty username
      await tester.tap(find.text('验证').first);
      await tester.pump();

      // Shows SnackBar for empty username
      expect(find.text('请先输入认证学号/账号'), findsOneWidget);

      // Clean up
      await manager.setBehavior(AuthBehavior.unified);
    });
  });

  group('AppSettingsScreen navigation to AdvancedSettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('displays 高级 card and navigates to AdvancedSettingsScreen',
        (tester) async {
      final manager = AuthManager();
      await manager.setBehavior(AuthBehavior.unified);

      await tester.pumpWidget(
        MaterialApp(
          home: AppSettingsScreen(onSwitchTab: (_) {}),
        ),
      );
      await tester.pump();

      // Check for 高级 card entry
      expect(find.text('高级'), findsAtLeastNWidgets(1));

      // Tap 高级 entry to navigate
      await tester.tap(find.text('高级').last);
      await tester.pumpAndSettle();

      // Verify AdvancedSettingsScreen is pushed
      expect(find.byType(AdvancedSettingsScreen), findsOneWidget);
      expect(find.text('密码认证行为'), findsOneWidget);
    });
  });
}
