import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ahu_aio/adaptive_dropdown.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_logic.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SchedulePage displays semester and week dropdowns in selection area',
    (tester) async {
      // Put ScheduleLogic
      if (!Get.isRegistered<ScheduleLogic>()) {
        Get.put(ScheduleLogic());
      }

      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: SchedulePage(embed: true))),
      );

      await tester.pump();

      // 周次下拉走自适应实现（byType 是运行时精确类型匹配，
      // 泛型实例必须写出类型参数才找得到）。
      expect(find.byType(AdaptiveDropdown<int>), findsOneWidget);

      // Material 2 的 DropdownButton 必须彻底消失（它在 M3 下也是 MD2 外观）。
      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.byType(DropdownButtonFormField<Object?>), findsNothing);

      // Verify week dropdown displays text with '周'
      expect(find.textContaining('周'), findsWidgets);

      // Verify floating action button is completely removed
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );
}
