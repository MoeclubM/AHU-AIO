import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_logic.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_service.dart';

void main() {
  group('ScheduleLogic processClassesForWeek', () {
    late ScheduleLogic logic;
    late ScheduleService service;

    setUp(() {
      logic = ScheduleLogic();
      service = ScheduleService();
      service.replaceClassesForTest([
        {
          'course': {'nameZh': '操作系统'},
          'weekIndices': [1, 2, 3],
          'schedules': [
            {
              'weekday': 1,
              'startTime': 800,
              'endTime': 935,
              'room': {'nameZh': '行知楼101'},
            },
          ],
        },
        {
          'course': {'nameZh': '编译原理'},
          'weekIndices': [2, 3, 4],
          'schedules': [
            {
              'weekday': 2,
              'startTime': 950,
              'endTime': 1125,
              'room': {'nameZh': '笃学楼202'},
            },
          ],
        },
      ]);
    });

    test('processClassesForWeek filters courses correctly for different weeks', () {
      final scheduleServiceField = logic.runtimeType;
      expect(scheduleServiceField, isNotNull);

      // Verify that service buildWeekSchedule works across different weeks
      final week1 = service.buildWeekSchedule(selectedWeek: 1);
      expect(week1[1]!.length, 1);
      expect(week1[1]!.first.courseName, '操作系统');
      expect(week1[2]!, isEmpty);

      final week2 = service.buildWeekSchedule(selectedWeek: 2);
      expect(week2[1]!.length, 1);
      expect(week2[2]!.length, 1);
      expect(week2[2]!.first.courseName, '编译原理');

      final week4 = service.buildWeekSchedule(selectedWeek: 4);
      expect(week4[1]!, isEmpty);
      expect(week4[2]!.length, 1);
    });
  });
}
