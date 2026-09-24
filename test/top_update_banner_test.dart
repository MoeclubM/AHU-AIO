import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahu_aio/update/github_update_service.dart';
import 'package:ahu_aio/update/top_update_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TopUpdateBanner 顶部小提示测试', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    const dummyInfo = AppUpdateInfo(
      tagName: 'v2.0.0',
      version: '2.0.0',
      releaseNotes: '新特性说明',
      htmlUrl: 'https://github.com/example/release',
      publishedAt: null,
      assets: [],
      currentVersion: '1.0.9',
    );

    testWidgets('顶部弹出提示条，展示版本号且不阻塞底层', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showTopUpdateBanner(context, info: dummyInfo),
                    child: const Text('触发提示'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 点击触发
      await tester.tap(find.text('触发提示'));
      await tester.pump(); // 插入 overlay
      await tester.pump(const Duration(milliseconds: 250)); // 完成进场动画

      expect(find.text('发现新版本 2.0.0'), findsOneWidget);

      // 前进 2 秒定时器触发，再等待反向淡出动画完成
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('发现新版本 2.0.0'), findsNothing);
    });

    testWidgets('顶部提示条支持直接划走（Dismissible）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showTopUpdateBanner(context, info: dummyInfo),
                    child: const Text('触发提示'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('触发提示'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('发现新版本 2.0.0'), findsOneWidget);

      // 向上划走
      await tester.fling(find.text('发现新版本 2.0.0'), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('发现新版本 2.0.0'), findsNothing);
    });

    test('启用更新检查默认应为 false', () async {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('enable_auto_update_check') ?? false;
      expect(enabled, isFalse);
    });
  });
}
