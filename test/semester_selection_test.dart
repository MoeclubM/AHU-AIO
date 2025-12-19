import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ahu_aio/jw/api/getallsemesters.dart';
import 'package:ahu_aio/jw/schedule/schedule_logic.dart';
import 'package:ahu_aio/jw/schedule/schedule_service.dart';

void main() {
  group('ScheduleLogic - Semester Selection', () {
    late ScheduleLogic logic;

    setUp(() {
      Get.reset();
      logic = ScheduleLogic();
    });

    test('选择其他学期时不应重置为当前学期', () async {
      // 模拟所有学期数据
      final allSemesters = [
        SemesterInfo(
          id: 1,
          code: '2023-2024-1',
          nameZh: '2023-2024学年第一学期',
          nameEn: '2023-2024-1',
          schoolYear: '2023-2024',
          startDate: '2023-09-01',
          endDate: '2024-01-15',
          season: '秋季',
        ),
        SemesterInfo(
          id: 2,
          code: '2023-2024-2',
          nameZh: '2023-2024学年第二学期',
          nameEn: '2023-2024-2',
          schoolYear: '2023-2024',
          startDate: '2024-02-20',
          endDate: '2024-06-30',
          season: '春季',
        ),
      ];

      logic.allSemesters.value = allSemesters;
      logic.selectedSemester.value = allSemesters.first;

      // 验证初始状态
      expect(logic.selectedSemester.value?.id, equals(1));

      // 手动选择第二个学期
      await logic.selectSemester(allSemesters[1]);

      // 验证选择没有在 selectSemester 内部被重置
      expect(logic.selectedSemester.value?.id, equals(2));
      expect(logic.selectedSemester.value?.nameZh, equals('2023-2024学年第二学期'));
    });

    test('selectSemester 不应调用 loadSemesterData', () async {
      // 这个测试验证 selectSemester 方法不会重新加载学期数据
      final allSemesters = [
        SemesterInfo(
          id: 1,
          code: '2023-2024-1',
          nameZh: '2023-2024学年第一学期',
          nameEn: '2023-2024-1',
          schoolYear: '2023-2024',
          startDate: '2023-09-01',
          endDate: '2024-01-15',
          season: '秋季',
        ),
      ];

      logic.allSemesters.value = allSemesters;
      logic.selectedSemester.value = allSemesters.first;

      final originalSemesterCount = logic.allSemesters.length;

      // 选择学期（虽然这里只有一个学期）
      await logic.selectSemester(allSemesters.first);

      // 验证学期列表没有变化
      expect(logic.allSemesters.length, equals(originalSemesterCount));
      expect(logic.selectedSemester.value?.id, equals(allSemesters.first.id));
    });
  });
}
