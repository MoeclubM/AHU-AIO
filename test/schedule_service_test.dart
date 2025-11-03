import 'package:flutter_test/flutter_test.dart';

import 'package:ahu_aio/jw/schedule/schedule_service.dart';

void main() {
  group('ScheduleService.buildWeekSchedule', () {
    late ScheduleService service;

    setUp(() {
      service = ScheduleService();
    });

    test('filters entries by selected week and marks current and honor flags', () {
      service.replaceClassesForTest([
        {
          'course': {
            'nameZh': '数学分析',
            'courseType': '荣誉课程',
          },
          'teacherAssignmentList': [
            {
              'person': {'nameZh': '张老师'},
            },
          ],
          'weekIndices': [1, 2, 3],
          'schedules': [
            {
              'weekday': 1,
              'startTime': 800,
              'endTime': 900,
              'weekIndices': [1, 2, 3],
              'room': {'nameZh': '致知楼101'},
            },
            {
              'weekday': 2,
              'startTime': 600,
              'endTime': 660,
              'weekIndices': ['4-6'],
              'room': {'nameZh': '慎思楼202'},
            },
          ],
        },
      ]);

      final schedule = service.buildWeekSchedule(
        selectedWeek: 2,
        currentWeek: 2,
        semesterStartDate: DateTime(2024, 9, 2),
      );

      final mondayEntries = schedule[DateTime.monday]!;
      expect(mondayEntries, hasLength(1));
      final entry = mondayEntries.first;
      expect(entry.courseName, '数学分析');
      expect(entry.isCurrentWeek, isTrue);
      expect(entry.isHonorCourse, isTrue);
      expect(entry.startTime, '08:00');
      expect(entry.endTime, '09:00');

      final tuesdayEntries = schedule[DateTime.tuesday]!;
      expect(tuesdayEntries, isEmpty, reason: '课程不应在不包含选中周次的日子里显示');
    });

    test('derives week number from course date when indices are missing', () {
      service.replaceClassesForTest([
        {
          'course': {
            'nameZh': 'C语言程序设计',
          },
          'teacherAssignmentList': [
            {
              'person': {'nameZh': '李老师'},
            },
          ],
          'schedules': [
            {
              'weekday': 3,
              'startTime': '10:00',
              'endTime': '11:40',
              'date': DateTime(2024, 9, 16),
              'roomName': '创新楼305',
            },
          ],
        },
      ]);

      final schedule = service.buildWeekSchedule(
        selectedWeek: 3,
        currentWeek: 4,
        semesterStartDate: DateTime(2024, 9, 2),
      );

      final wednesdayEntries = schedule[DateTime.wednesday]!;
      expect(wednesdayEntries, hasLength(1));
      final entry = wednesdayEntries.first;
      expect(entry.courseName, 'C语言程序设计');
      expect(entry.isCurrentWeek, isFalse,
          reason: '当前周不同于课程所在周，因而不应高亮');
      expect(entry.roomName, '创新楼305');
    });

    test('parses textual week indices including odd/even hints', () {
      service.replaceClassesForTest([
        {
          'course': {
            'nameZh': '思想政治理论',
          },
          'teacherAssignmentList': [
            {
              'person': {'nameZh': '王老师'},
            },
          ],
          'weekIndices': '1-4(单)',
          'schedules': [
            {
              'weekday': 4,
              'startTime': 780,
              'endTime': 840,
              'room': {'name': '至善楼406'},
            },
          ],
        },
      ]);

      final oddWeekSchedule = service.buildWeekSchedule(
        selectedWeek: 3,
        currentWeek: 3,
        semesterStartDate: DateTime(2024, 9, 2),
      );
      expect(oddWeekSchedule[DateTime.thursday], isNotEmpty);

      final evenWeekSchedule = service.buildWeekSchedule(
        selectedWeek: 2,
        currentWeek: 3,
        semesterStartDate: DateTime(2024, 9, 2),
      );
      expect(evenWeekSchedule[DateTime.thursday], isEmpty,
          reason: '单周课程在双周不应展示');
    });
  });
}
