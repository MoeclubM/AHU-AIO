import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_logic.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SchedulePage displays semester and week dropdowns in selection area',
      (tester) async {
    // Put ScheduleLogic
    if (!Get.isRegistered<ScheduleLogic>()) {
      Get.put(ScheduleLogic());
    }

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SchedulePage(embed: true),
        ),
      ),
    );

    await tester.pump();

    // Verify DropdownButton for week exists
    expect(find.byType(DropdownButton<int>), findsOneWidget);

    // Verify week dropdown displays text with '周'
    expect(find.textContaining('周'), findsWidgets);

    // Verify floating action button is completely removed
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
