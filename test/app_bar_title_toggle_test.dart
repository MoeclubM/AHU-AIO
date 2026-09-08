import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahu_aio/finance/pages/finance_recharge_page.dart';
import 'package:ahu_aio/theme_manager.dart';
import 'package:ahu_aio/app_settings_screen.dart';
import 'package:ahu_aio/widget_settings_screen.dart';
import 'package:ahu_aio/jwapp/mainpage/mainpage_view.dart';
import 'package:ahu_aio/jw/home/jw_main_tabs.dart';
import 'package:ahu_aio/finance/home/finance_main_tabs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeManager showAppBarTitle preference', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemeManager().setShowAppBarTitle(true);
    });

    test('default showAppBarTitle is true (enabled)', () {
      final tm = ThemeManager();
      expect(tm.showAppBarTitle, isTrue);
    });

    test(
      'setShowAppBarTitle toggles value and persists to SharedPreferences',
      () async {
        final tm = ThemeManager();
        await tm.setShowAppBarTitle(false);
        expect(tm.showAppBarTitle, isFalse);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('showAppBarTitle'), isFalse);

        // Reset to true
        await tm.setShowAppBarTitle(true);
        expect(tm.showAppBarTitle, isTrue);
        expect(prefs.getBool('showAppBarTitle'), isTrue);
      },
    );
  });

  group('AppSettingsScreen and WidgetSettingsScreen widget test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'displays 控件 card and navigates to WidgetSettingsScreen with 显示Title switch',
      (tester) async {
        final tm = ThemeManager();
        await tm.setShowAppBarTitle(false);

        await tester.pumpWidget(
          MaterialApp(home: AppSettingsScreen(onSwitchTab: (_) {})),
        );

        await tester.pump();

        // Check for 控件 card entry
        expect(find.text('控件'), findsAtLeastNWidgets(1));

        // Tap 控件 entry to navigate
        await tester.tap(find.text('控件').last);
        await tester.pumpAndSettle();

        // Verify WidgetSettingsScreen is pushed
        expect(find.byType(WidgetSettingsScreen), findsOneWidget);

        // Check for 显示Title switch preference inside WidgetSettingsScreen
        expect(find.text('显示Title'), findsOneWidget);

        // Check for 充值缴费显示样式 selection item
        expect(find.text('充值缴费显示样式'), findsOneWidget);

        // Tap 充值缴费显示样式 to open selection modal
        await tester.tap(find.text('充值缴费显示样式'));
        await tester.pumpAndSettle();

        // Check options in modal bottom sheet
        expect(find.text('双列大卡片，大图标大色块'), findsOneWidget);
        expect(find.text('列表 (左图标右文字)'), findsWidgets);

        // Select 列表 (左图标右文字)
        await tester.tap(find.text('单列水平排列，左侧图标右侧名称'));
        await tester.pumpAndSettle();

        // Verify state and persistence updated
        expect(financeRechargeIsListViewNotifier.value, isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('finance_recharge_is_list'), isTrue);
      },
    );
  });

  group('Main tabs showAppBarTitle behavior', () {
    late PageController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = PageController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets(
      'MainPage removes AppBar when showAppBarTitle is false, shows when true',
      (tester) async {
        final tm = ThemeManager();
        await tm.setShowAppBarTitle(false);

        await tester.pumpWidget(
          MaterialApp(home: MainPage(pageController: controller)),
        );
        await tester.pump();

        // When false, AppBar is null and '安大微教务' title is not shown
        expect(find.text('安大微教务'), findsNothing);

        // When true, AppBar is rendered with title
        await tm.setShowAppBarTitle(true);
        await tester.pump();
        expect(find.text('安大微教务'), findsOneWidget);

        // Reset
        await tm.setShowAppBarTitle(false);
        await tester.pump();
      },
    );

    testWidgets(
      'JwMainTabs removes AppBar when showAppBarTitle is false, shows when true',
      (tester) async {
        final tm = ThemeManager();
        await tm.setShowAppBarTitle(false);

        await tester.pumpWidget(
          MaterialApp(home: JwMainTabs(pageController: controller)),
        );
        await tester.pump();

        // When false, AppBar is null and '安大教务' title is not shown
        expect(find.text('安大教务'), findsNothing);

        // When true, AppBar is rendered with title
        await tm.setShowAppBarTitle(true);
        await tester.pump();
        expect(find.text('安大教务'), findsOneWidget);

        // Reset
        await tm.setShowAppBarTitle(false);
        await tester.pump();
      },
    );

    testWidgets(
      'FinanceMainTabs removes AppBar when showAppBarTitle is false, shows when true',
      (tester) async {
        final tm = ThemeManager();
        await tm.setShowAppBarTitle(false);

        await tester.pumpWidget(
          MaterialApp(home: FinanceMainTabs(pageController: controller)),
        );
        await tester.pump();

        // When false, AppBar is null and '一卡通系统' title is not shown
        expect(find.text('一卡通系统'), findsNothing);

        // When true, AppBar is rendered with title
        await tm.setShowAppBarTitle(true);
        await tester.pump();
        expect(find.text('一卡通系统'), findsOneWidget);

        // Reset
        await tm.setShowAppBarTitle(false);
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}
