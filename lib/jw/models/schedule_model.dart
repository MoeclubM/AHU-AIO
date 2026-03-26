/// 日程数据模型，提供类型安全的数据处理
class ScheduleModel {
  final String date;
  final String whatDay;
  final String context;
  final String? place;
  final String startTime;
  final String endTime;
  final int type;
  final bool identification;

  const ScheduleModel({
    required this.date,
    required this.whatDay,
    required this.context,
    this.place,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.identification,
  });

  /// 从动态数据创建ScheduleModel，包含类型转换和验证
  factory ScheduleModel.fromJson(Map<String, dynamic> json, String dateKey) {
    return ScheduleModel(
      date: dateKey,
      whatDay: _parseWhatDay(json['whatDay']),
      context: json['context']?.toString() ?? '未知课程',
      place: json['place']?.toString(),
      startTime: _parseTime(json['startTime']),
      endTime: _parseTime(json['endTime']),
      type: _parseInt(json['type']) ?? 0,
      identification: _parseBool(json['identification']) ?? false,
    );
  }

  /// 解析星期数据，支持多种格式
  static String _parseWhatDay(dynamic whatDay) {
    if (whatDay is int) {
      final weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return whatDay > 0 && whatDay <= 7 ? weekdays[whatDay] : '未知';
    } else if (whatDay is String) {
      if (whatDay.startsWith('周')) {
        return whatDay;
      } else {
        final dayNum = int.tryParse(whatDay);
        if (dayNum != null) {
          final weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
          return dayNum > 0 && dayNum <= 7 ? weekdays[dayNum] : '未知';
        }
        return whatDay.isNotEmpty ? whatDay : '未知';
      }
    }
    return '未知';
  }

  /// 解析时间格式
  static String _parseTime(dynamic time) {
    if (time == null) return '00:00';

    if (time is int) {
      final hours = (time / 100).floor().toString().padLeft(2, '0');
      final minutes = (time % 100).toString().padLeft(2, '0');
      return '$hours:$minutes';
    } else if (time is String) {
      if (time.contains(':')) return time;
      final timeInt = int.tryParse(time);
      if (timeInt != null) {
        final hours = (timeInt / 100).floor().toString().padLeft(2, '0');
        final minutes = (timeInt % 100).toString().padLeft(2, '0');
        return '$hours:$minutes';
      }
    }
    return '00:00';
  }

  /// 安全解析整数
  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 安全解析布尔值
  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
      return int.tryParse(value) == 1;
    }
    return null;
  }

  /// 获取时间段描述
  String get timeSlot {
    final start = _parseTimeToInt(startTime);

    if (start < 800) {
      return '早晨 ($startTime-$endTime)';
    } else if (start < 1200) {
      return '上午 ($startTime-$endTime)';
    } else if (start < 1400) {
      return '中午 ($startTime-$endTime)';
    } else if (start < 1800) {
      return '下午 ($startTime-$endTime)';
    } else {
      return '晚上 ($startTime-$endTime)';
    }
  }

  /// 将时间字符串转换为整数以便比较
  int _parseTimeToInt(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 100 + minutes;
    }
    return 0;
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'whatDay': whatDay,
      'context': context,
      'place': place,
      'startTime': startTime,
      'endTime': endTime,
      'timeSlot': timeSlot,
      'type': type,
      'identification': identification,
    };
  }

  /// 创建唯一标识符，用于去重
  String get uniqueKey => '${context}_${place ?? ''}_${startTime}_$endTime';
}
