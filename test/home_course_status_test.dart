import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahu_aio/jwapp/home/home_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePageLogic 课程状态细分测试', () {
    late HomePageLogic logic;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      logic = HomePageLogic();
    });

    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    String formatTime(DateTime dt) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    test('当前正在进行的课程应被识别为 ongoing，但不是 upcoming', () {
      final start = now.subtract(const Duration(minutes: 20));
      final end = now.add(const Duration(minutes: 40));

      final course = {
        'context': '正在上课的课程',
        'startTime': formatTime(start),
        'endTime': formatTime(end),
      };

      expect(logic.isCourseOngoing(course, today), isTrue);
      expect(logic.isCourseUpcoming(course, today), isFalse);
      expect(logic.isCourseOngoingOrUpcoming(course, today), isTrue);
    });

    test('提前 10 分钟（<= 15 分钟）的课程应被识别为 upcoming，但不是 ongoing', () {
      final start = now.add(const Duration(minutes: 10));
      final end = now.add(const Duration(minutes: 70));

      final course = {
        'context': '即将开始的课程',
        'startTime': formatTime(start),
        'endTime': formatTime(end),
      };

      expect(logic.isCourseOngoing(course, today), isFalse);
      expect(logic.isCourseUpcoming(course, today), isTrue);
      expect(logic.isCourseOngoingOrUpcoming(course, today), isTrue);
    });

    test('提前 25 分钟（> 15 分钟）的课程不应提前高亮', () {
      final start = now.add(const Duration(minutes: 25));
      final end = now.add(const Duration(minutes: 85));

      final course = {
        'context': '较远未来的课程',
        'startTime': formatTime(start),
        'endTime': formatTime(end),
      };

      expect(logic.isCourseOngoing(course, today), isFalse);
      expect(logic.isCourseUpcoming(course, today), isFalse);
      expect(logic.isCourseOngoingOrUpcoming(course, today), isFalse);
    });

    test('已经结束的课程不应高亮', () {
      final start = now.subtract(const Duration(minutes: 60));
      final end = now.subtract(const Duration(minutes: 10));

      final course = {
        'context': '已下课的课程',
        'startTime': formatTime(start),
        'endTime': formatTime(end),
      };

      expect(logic.isCourseOngoing(course, today), isFalse);
      expect(logic.isCourseUpcoming(course, today), isFalse);
      expect(logic.isCourseOngoingOrUpcoming(course, today), isFalse);
    });
  });
}
