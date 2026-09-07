/// 时间格式化工具类
class TimeUtils {
  /// 将时间数字格式化为时间字符串
  ///
  /// 例如：800 -> "08:00", 1330 -> "13:30"
  static String formatTime(int time) {
    if (time <= 0) {
      return '00:00';
    }

    // 支持两种常见格式：HHmm（例如 830）以及分钟数（例如 480）
    final asMinutes = time % 100 >= 60 || time >= 2400
        ? time
        : (time ~/ 100) * 60 + (time % 100);

    return minutesToTime(asMinutes);
  }

  /// 解析时间字符串为分钟数
  ///
  /// 例如："08:00" -> 480, "13:30" -> 810
  static int timeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return hour * 60 + minute;
    }
    return 0;
  }

  /// 将分钟数转换为时间字符串
  ///
  /// 例如：480 -> "08:00", 810 -> "13:30"
  static String minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 比较两个时间字符串
  ///
  /// 返回：-1 如果 time1 < time2，0 如果相等，1 如果 time1 > time2
  static int compareTimeStrings(String timeA, String timeB) {
    final partsA = timeA.split(':');
    final partsB = timeB.split(':');

    if (partsA.length >= 2 && partsB.length >= 2) {
      final hourA = int.tryParse(partsA[0]) ?? 0;
      final minuteA = int.tryParse(partsA[1]) ?? 0;
      final hourB = int.tryParse(partsB[0]) ?? 0;
      final minuteB = int.tryParse(partsB[1]) ?? 0;

      final totalMinutesA = hourA * 60 + minuteA;
      final totalMinutesB = hourB * 60 + minuteB;

      return totalMinutesA.compareTo(totalMinutesB);
    }

    return timeA.compareTo(timeB);
  }

  /// 获取当前时间的时间字符串
  static String getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 判断时间字符串是否在指定范围内
  static bool isTimeInRange(String time, String startTime, String endTime) {
    final timeMinutes = timeToMinutes(time);
    final startMinutes = timeToMinutes(startTime);
    final endMinutes = timeToMinutes(endTime);

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// 安徽大学标准节次对应的开始时间文本 (1..13)
  static const Map<int, String> standardUnitStartTimes = {
    1: '08:00',
    2: '08:50',
    3: '09:50',
    4: '10:40',
    5: '11:30',
    6: '14:00',
    7: '14:50',
    8: '15:50',
    9: '16:40',
    10: '17:30',
    11: '19:00',
    12: '19:50',
    13: '20:40',
  };

  /// 安徽大学标准节次对应的结束时间文本 (1..13)
  static const Map<int, String> standardUnitEndTimes = {
    1: '08:45',
    2: '09:35',
    3: '10:35',
    4: '11:25',
    5: '12:15',
    6: '14:45',
    7: '15:35',
    8: '16:35',
    9: '17:25',
    10: '18:15',
    11: '19:45',
    12: '20:35',
    13: '21:25',
  };

  /// 根据物理时间字符串智能解析起始节次 (1..13)
  static int resolveStartUnit(String startTime) {
    final startMin = timeToMinutes(startTime);
    if (startMin <= 0) return 1;
    if (startMin < 510) return 1; // 08:00
    if (startMin < 565) return 2; // 08:50
    if (startMin < 620) return 3; // 09:50
    if (startMin < 670) return 4; // 10:40
    if (startMin < 770) return 5; // 11:30
    if (startMin < 870) return 6; // 14:00
    if (startMin < 925) return 7; // 14:50
    if (startMin < 980) return 8; // 15:50
    if (startMin < 1030) return 9; // 16:40
    if (startMin < 1100) return 10; // 17:30
    if (startMin < 1170) return 11; // 19:00
    if (startMin < 1220) return 12; // 19:50
    return 13; // 20:40 -> 13节
  }

  /// 根据结束物理时间与起始节次智能解析结束节次 (1..13)
  static int resolveEndUnit(String endTime, int startUnit) {
    final endMin = timeToMinutes(endTime);
    if (endMin <= 0) return startUnit;
    if (endMin <= 550) return mathMax(1, startUnit); // 08:45 -> 1节
    if (endMin <= 605) return mathMax(2, startUnit); // 09:35 -> 2节
    if (endMin <= 660) return mathMax(3, startUnit); // 10:35 -> 3节
    if (endMin <= 710) return mathMax(4, startUnit); // 11:25 -> 4节
    if (endMin <= 800) return mathMax(5, startUnit); // 12:15 -> 5节 (上午结束)
    if (endMin <= 910) return mathMax(6, startUnit); // 14:45 -> 6节
    if (endMin <= 965) return mathMax(7, startUnit); // 15:35 -> 7节
    if (endMin <= 1020) return mathMax(8, startUnit); // 16:35 -> 8节
    if (endMin <= 1070) return mathMax(9, startUnit); // 17:25 -> 9节
    if (endMin <= 1140) return mathMax(10, startUnit); // 18:15 -> 10节 (下午结束)
    if (endMin <= 1210) return mathMax(11, startUnit); // 19:45 -> 11节
    if (endMin <= 1260) return mathMax(12, startUnit); // 20:35 -> 12节
    return mathMax(13, startUnit); // 21:25 -> 13节
  }

  static int mathMax(int a, int b) => a > b ? a : b;
}
