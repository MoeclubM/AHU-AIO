/// 空闲教室模型：字段与 `eams-micro-server` 实测响应对齐。
library;

/// 教室类型 / 校区 / 建筑（列表接口）
class CampusModel {
  final String id;
  final String name;
  final String code;

  const CampusModel({required this.id, required this.name, this.code = ''});

  factory CampusModel.fromJson(Map<String, dynamic> json) => CampusModel(
    id: json['id']?.toString() ?? '',
    name: json['nameZh']?.toString() ?? json['name']?.toString() ?? '',
    code: json['code']?.toString() ?? '',
  );
}

class BuildingModel {
  final String id;
  final String name;
  final String campusId;

  const BuildingModel({
    required this.id,
    required this.name,
    this.campusId = '',
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) => BuildingModel(
    id: json['id']?.toString() ?? '',
    name: json['nameZh']?.toString() ?? json['name']?.toString() ?? '',
    campusId: (json['campusAssoc'] ?? json['campusId'])?.toString() ?? '',
  );
}

/// 官方课节（`room/system/course-units`）
///
/// startTime/endTime 为 HHMM 整数，例如 800 = 08:00，1450 = 14:50。
class CourseUnit {
  final int indexNo;
  final String name;
  final int startTime; // HHMM
  final int endTime; // HHMM
  final String dayPart;

  const CourseUnit({
    required this.indexNo,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.dayPart = '',
  });

  factory CourseUnit.fromJson(Map<String, dynamic> json) => CourseUnit(
    indexNo: json['indexNo'] as int? ?? 0,
    name: json['nameZh']?.toString() ?? json['name']?.toString() ?? '',
    startTime: json['startTime'] as int? ?? 0,
    endTime: json['endTime'] as int? ?? 0,
    dayPart: json['dayPart']?.toString() ?? '',
  );

  String get label => '第$name节';

  String get timeRange {
    final String s = _hhmm(startTime);
    final String e = _hhmm(endTime);
    return '($s-$e)';
  }

  String get display => '$label$timeRange';

  /// 占用活动是否与本课节重叠（按 HHMM）。
  bool overlaps(int startHHMM, int endHHMM) {
    if (startHHMM <= 0 || endHHMM <= 0) return false;
    // 兼容 endTime 缺失时按 1 小时估。
    final int end = endHHMM > startHHMM ? endHHMM : startHHMM + 100;
    return startHHMM < endTime && end > startTime;
  }

  static String _hhmm(int v) {
    final int h = v ~/ 100;
    final int m = v % 100;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

/// 教室占用片段
class RoomOccupation {
  final String activityName;
  final String teacherName;
  final int startTime; // HHMM
  final int endTime; // HHMM

  const RoomOccupation({
    this.activityName = '',
    this.teacherName = '',
    this.startTime = 0,
    this.endTime = 0,
  });

  factory RoomOccupation.fromJson(Map<String, dynamic> json) {
    return RoomOccupation(
      activityName:
          json['activityName']?.toString() ??
          json['courseName']?.toString() ??
          '',
      teacherName: json['teacherName']?.toString() ?? '',
      startTime: _toIntHHMM(json['startTime'] ?? json['startTimeString']),
      endTime: _toIntHHMM(json['endTime'] ?? json['endTimeString']),
    );
  }

  static int _toIntHHMM(dynamic value) {
    if (value == null) return 0;
    if (value is int) {
      // 800 / 80000 等异常格式归一到 HHMM。
      if (value >= 2400 && value < 240000) {
        return (value / 100).round();
      }
      return value;
    }
    final String s = value.toString().trim();
    if (s.isEmpty) return 0;
    if (s.contains(':')) {
      final List<String> parts = s.split(':');
      final int h = int.tryParse(parts[0]) ?? 0;
      final int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return h * 100 + m;
    }
    return int.tryParse(s) ?? 0;
  }
}

/// 教室
class RoomModel {
  final String id;
  final String name;
  final String code;
  final String buildingId;
  final String campusName;
  final String floor;
  final int capacity;
  final bool virtualRoom;
  final bool enabled;
  final List<RoomOccupation> occupations;

  const RoomModel({
    required this.id,
    required this.name,
    this.code = '',
    this.buildingId = '',
    this.campusName = '',
    this.floor = '',
    this.capacity = 0,
    this.virtualRoom = false,
    this.enabled = true,
    this.occupations = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final List<RoomOccupation> occupations = [];
    final occ = json['roomOccupationInfoVms'];
    if (occ is List) {
      for (final dynamic item in occ) {
        if (item is Map<String, dynamic>) {
          occupations.add(RoomOccupation.fromJson(item));
        } else if (item is Map) {
          occupations.add(
            RoomOccupation.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return RoomModel(
      id: json['id']?.toString() ?? '',
      name: json['nameZh']?.toString() ?? json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      buildingId: json['buildingId']?.toString() ?? '',
      campusName:
          json['campusNameZh']?.toString() ??
          json['campusName']?.toString() ??
          '',
      floor: json['floor']?.toString() ?? '',
      // 实测字段为 seatsForLesson；旧接口 capacity 作兼容。
      capacity: _toInt(json['seatsForLesson'] ?? json['capacity'] ?? 0),
      virtualRoom: json['virtual'] == true || json['isVirtual'] == true,
      enabled: json['enabled'] != false,
      occupations: occupations,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// 在指定课节是否被占用。
  bool isOccupiedAt(CourseUnit unit) {
    for (final occ in occupations) {
      if (unit.overlaps(occ.startTime, occ.endTime)) return true;
    }
    return false;
  }

  /// 指定日期下空闲的官方课节。
  List<CourseUnit> freeUnits(List<CourseUnit> units) {
    return units.where((u) => !isOccupiedAt(u)).toList();
  }

  /// 指定日期下被占用的官方课节。
  List<CourseUnit> occupiedUnits(List<CourseUnit> units) {
    return units.where(isOccupiedAt).toList();
  }

  bool get hasOccupation => occupations.isNotEmpty;

  /// 当日是否“空闲”（无任何占用活动）。
  bool get isFreeDay => occupations.isEmpty;
}
