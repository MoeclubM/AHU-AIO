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
}