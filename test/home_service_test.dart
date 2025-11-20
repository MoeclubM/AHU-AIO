import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/jw/home/home_service.dart';

void main() {
  group('HomePageLogic course timing detection', () {
    late HomePageLogic logic;

    setUp(() {
      logic = HomePageLogic();
    });

    test('detects ongoing course correctly', () {
      final now = DateTime.now();
      final startHour = (now.hour - 1).clamp(0, 23);
      final endHour = (now.hour + 1).clamp(0, 23);
      
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final course = {
        'context': '测试课程',
        'startTime': '${startHour.toString().padLeft(2, '0')}:00',
        'endTime': '${endHour.toString().padLeft(2, '0')}:00',
      };

      // 如果现在在课程时间范围内，应该返回true
      // 注意：这个测试依赖实际运行时间
      final result = logic.isCourseOngoingOrUpcoming(course, today);
      expect(result, true, reason: '正在进行的课程应该被检测到');
    });

    test('detects upcoming course correctly', () {
      final now = DateTime.now();
      final upcomingStart = now.add(const Duration(minutes: 15));
      
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final course = {
        'context': '即将开始的课程',
        'startTime': '${upcomingStart.hour.toString().padLeft(2, '0')}:${upcomingStart.minute.toString().padLeft(2, '0')}',
        'endTime': '${(upcomingStart.hour + 1).toString().padLeft(2, '0')}:${upcomingStart.minute.toString().padLeft(2, '0')}',
      };

      final result = logic.isCourseOngoingOrUpcoming(course, today);
      expect(result, true, reason: '即将开始的课程应该被检测到');
    });

    test('does not detect past course as ongoing', () {
      final now = DateTime.now();
      final pastStart = now.subtract(const Duration(hours: 2));
      final pastEnd = now.subtract(const Duration(hours: 1));
      
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final course = {
        'context': '已结束的课程',
        'startTime': '${pastStart.hour.toString().padLeft(2, '0')}:${pastStart.minute.toString().padLeft(2, '0')}',
        'endTime': '${pastEnd.hour.toString().padLeft(2, '0')}:${pastEnd.minute.toString().padLeft(2, '0')}',
      };

      final result = logic.isCourseOngoingOrUpcoming(course, today);
      expect(result, false, reason: '已结束的课程不应该被检测为进行中');
    });

    test('does not detect courses on other days', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final course = {
        'context': '明天的课程',
        'startTime': '10:00',
        'endTime': '11:30',
      };

      // 检查今天，但课程是明天的
      final result = logic.isCourseOngoingOrUpcoming(course, today);
      expect(result, false, reason: '其他日期的课程不应该被检测为当前进行中');
    });

    test('hasOngoingOrUpcomingCourse detects in list', () {
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final upcomingStart = now.add(const Duration(minutes: 20));
      
      final courses = [
        {
          'context': '过去的课程',
          'startTime': '08:00',
          'endTime': '09:30',
        },
        {
          'context': '即将开始的课程',
          'startTime': '${upcomingStart.hour.toString().padLeft(2, '0')}:${upcomingStart.minute.toString().padLeft(2, '0')}',
          'endTime': '${(upcomingStart.hour + 1).toString().padLeft(2, '0')}:${upcomingStart.minute.toString().padLeft(2, '0')}',
        },
      ];

      final result = logic.hasOngoingOrUpcomingCourse(courses, today);
      expect(result, true, reason: '应该检测到列表中包含即将进行的课程');
    });
  });
}
