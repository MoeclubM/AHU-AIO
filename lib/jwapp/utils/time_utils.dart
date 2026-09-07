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

  /// 安徽大学标准节次对应的开始时间文本 (1..11)
  static const Map<int, String> standardUnitStartTimes = {
    1: '08:00',
    2: '08:50',
    3: '09:50',
    4: '10:40',
    5: '14:00',
    6: '14:50',
    7: '15:50',
    8: '16:40',
    9: '19:00',
    10: '19:55',
    11: '20:50',
  };

  /// 根据物理时间字符串智能解析起始节次 (1..11)
  static int resolveStartUnit(String startTime) {
    final startMin = timeToMinutes(startTime);
    if (startMin <= 0) return 1;
    if (startMin <= 515) return 1; // ~08:35 -> 1节 (08:00)
    if (startMin <= 560) return 2; // ~09:20 -> 2节 (08:50)
    if (startMin <= 620) return 3; // ~10:20 -> 3节 (09:50)
    if (startMin <= 750) return 4; // ~12:30 -> 4节 (10:40)
    if (startMin <= 870) return 5; // ~14:30 -> 5节 (14:00)
    if (startMin <= 930) return 6; // ~15:30 -> 6节 (14:50)
    if (startMin <= 980) return 7; // ~16:20 -> 7节 (15:50)
    if (startMin <= 1080) return 8; // ~18:00 -> 8节 (16:40)
    if (startMin <= 1170) return 9; // ~19:30 -> 9节 (19:00)
    if (startMin <= 1220) return 10; // ~20:20 -> 10节 (19:55)
    return 11; // 20:50 -> 11节
  }

  /// 根据结束物理时间与起始节次智能解析结束节次 (1..11)
  static int resolveEndUnit(String endTime, int startUnit) {
    final endMin = timeToMinutes(endTime);
    if (endMin <= 0) return startUnit;
    if (endMin <= 550) return mathMax(1, startUnit); // 08:45 -> 1节
    if (endMin <= 605) return mathMax(2, startUnit); // 09:35 -> 2节
    if (endMin <= 660) return mathMax(3, startUnit); // 10:35 -> 3节
    if (endMin <= 710) return mathMax(4, startUnit); // 11:25 -> 4节
    if (endMin <= 790) return mathMax(5, startUnit); // 12:15 -> 5节 (上午长课)
    if (endMin <= 900) return mathMax(5, startUnit); // 14:45 -> 5节
    if (endMin <= 960) return mathMax(6, startUnit); // 15:35 -> 6节
    if (endMin <= 1020) return mathMax(7, startUnit); // 16:35 -> 7节
    if (endMin <= 1070) return mathMax(8, startUnit); // 17:25 -> 8节
    if (endMin <= 1125) return mathMax(9, startUnit); // 18:15 -> 9节 (下午实验大课)
    if (endMin <= 1200) return mathMax(9, startUnit); // 19:45 -> 9节
    if (endMin <= 1260) return mathMax(10, startUnit); // 20:40 -> 10节
    return mathMax(11, startUnit); // 21:25 / 21:35 -> 11节
  }

  static int mathMax(int a, int b) => a > b ? a : b;
}
