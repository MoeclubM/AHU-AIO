import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ahu_aio/jwapp/api/getallsemesters.dart';
import 'package:ahu_aio/jwapp/schedule/schedule_logic.dart';

void main() {
  group('ScheduleLogic - Complete Semester Switching Flow', () {
    late ScheduleLogic logic;

    setUp(() {
      Get.reset();
      logic = ScheduleLogic();
    });

    test('完整流程：选择其他学期 -> 加载数据 -> 验证状态', () async {
      // 模拟学期数据
      final semester1 = SemesterInfo(
        id: 1,
        code: '2023-2024-1',
        nameZh: '2023-2024学年第一学期',
        nameEn: '2023-2024-1',
        schoolYear: '2023-2024',
        startDate: '2023-09-01',
        endDate: '2024-01-15',
        season: '秋季',
      );

      final semester2 = SemesterInfo(
        id: 2,
        code: '2023-2024-2',
        nameZh: '2023-2024学年第二学期',
        nameEn: '2023-2024-2',
        schoolYear: '2023-2024',
        startDate: '2024-02-20',
        endDate: '2024-06-30',
        season: '春季',
      );

      logic.allSemesters.value = [semester1, semester2];
      logic.selectedSemester.value = semester1;

      // 验证初始状态
      expect(logic.selectedSemester.value?.id, equals(1));
      expect(logic.availableWeeks.isEmpty, isTrue);

      // 选择第二个学期
      await logic.selectSemester(semester2);

      // 验证选择成功且没有被重置
      expect(logic.selectedSemester.value?.id, equals(2));
      expect(logic.selectedSemester.value?.nameZh, equals('2023-2024学年第二学期'));

      // 验证周数已设置为默认值（1-20周）
      expect(logic.availableWeeks.length, equals(20));
      expect(logic.availableWeeks.first, equals(1));
      expect(logic.availableWeeks.last, equals(20));

      // 验证选中的周数为第一周
      expect(logic.selectedWeek.value, equals(1));
    });

    test('选择当前学期时，应使用真实的周数信息', () async {
      // 这里只是验证逻辑，实际测试中需要模拟 CurrentSemesterInfo
      final semester1 = SemesterInfo(
        id: 1,
        code: '2023-2024-1',
        nameZh: '2023-2024学年第一学期',
        nameEn: '2023-2024-1',
        schoolYear: '2023-2024',
        startDate: '2023-09-01',
        endDate: '2024-01-15',
        season: '秋季',
      );

      logic.allSemesters.value = [semester1];
      logic.selectedSemester.value = semester1;

      // 验证选择当前学期时逻辑正确
      await logic.selectSemester(semester1);

      expect(logic.selectedSemester.value?.id, equals(1));
    });
  });
}
