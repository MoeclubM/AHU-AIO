import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ahu_aio/adaptive_dropdown.dart';
import 'package:ahu_aio/jwapp/api/getallsemesters.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_logic.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_view.dart';
import 'package:ahu_aio/widgets/schedule_week_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SchedulePage displays a semester dropdown and horizontal week chips',
    (tester) async {
      // Put ScheduleLogic
      if (!Get.isRegistered<ScheduleLogic>()) {
        Get.put(ScheduleLogic());
      }

      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: SchedulePage(embed: true))),
      );

      await tester.pump();

      expect(find.byType(AdaptiveDropdown<SemesterInfo>), findsOneWidget);
      expect(find.byType(ScheduleWeekSelector), findsOneWidget);
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(20));
      expect(find.byType(AdaptiveDropdown<int>), findsNothing);

      // Material 2 的 DropdownButton 必须彻底消失（它在 M3 下也是 MD2 外观）。
      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.byType(DropdownButtonFormField<Object?>), findsNothing);

      // 周次由横向胶囊选择器显示，不再使用下拉菜单。
      expect(find.textContaining('周'), findsWidgets);

      // Verify floating action button is completely removed
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );
}
