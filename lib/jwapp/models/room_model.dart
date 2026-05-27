/// 校区模型
class CampusModel {
  final String id;
  final String name;
  final String code;

  const CampusModel({required this.id, required this.name, required this.code});

  factory CampusModel.fromJson(Map<String, dynamic> json) {
    return CampusModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

/// 建筑模型
class BuildingModel {
  final String id;
  final String name;
  final String campusId;

  const BuildingModel({
    required this.id,
    required this.name,
    required this.campusId,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      campusId: json['campusId']?.toString() ?? '',
    );
  }
}

/// 教室模型
class RoomModel {
  final String id;
  final String name;
  final String buildingId;
  final String campusId;
  final String roomType;
  final int capacity;
  final String floor;
  final List<TimeSlot> timeSlots;
  final String? location;
  final List<String>? facilities;

  const RoomModel({
    required this.id,
    required this.name,
    required this.buildingId,
    required this.campusId,
    required this.roomType,
    required this.capacity,
    required this.floor,
    required this.timeSlots,
    this.location,
    this.facilities,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final List<TimeSlot> slots = [];
    if (json['timeSlots'] != null) {
      final slotsData = json['timeSlots'] as List;
      for (var slot in slotsData) {
        slots.add(TimeSlot.fromJson(slot));
      }
    }

    List<String>? facilities;
    if (json['facilities'] != null) {
      facilities = (json['facilities'] as List)
          .map((f) => f.toString())
          .toList();
    }

    return RoomModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      buildingId: json['buildingId']?.toString() ?? '',
      campusId: json['campusId']?.toString() ?? '',
      roomType: json['roomType']?.toString() ?? '',
      capacity: json['capacity'] ?? 0,
      floor: json['floor']?.toString() ?? '',
      timeSlots: slots,
      location: json['location']?.toString(),
      facilities: facilities,
    );
  }

  /// 检查指定时间段是否空闲
  bool isAvailableAt(String timeSlot) {
    for (final slot in timeSlots) {
      if (slot.timeSlot == timeSlot && slot.isOccupied) {
        return false;
      }
    }
    return true;
  }

  /// 获取空闲时间段
  List<String> getAvailableTimeSlots() {
    final allSlots = [
      '第1-2节(08:00-09:40)',
      '第3-4节(10:00-11:40)',
      '第5-6节(14:00-15:40)',
      '第7-8节(16:00-17:40)',
      '第9-10节(19:00-20:40)',
    ];

    final availableSlots = <String>[];
    for (final slot in allSlots) {
      if (isAvailableAt(slot)) {
        availableSlots.add(slot);
      }
    }
    return availableSlots;
  }
}

/// 时间段模型
class TimeSlot {
  final String timeSlot;
  final bool isOccupied;
  final String? courseName;
  final String? teacherName;

  const TimeSlot({
    required this.timeSlot,
    required this.isOccupied,
    this.courseName,
    this.teacherName,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      timeSlot: json['timeSlot']?.toString() ?? '',
      isOccupied: json['isOccupied'] ?? false,
      courseName: json['courseName']?.toString(),
      teacherName: json['teacherName']?.toString(),
    );
  }
}

/// 教室查询过滤器
class RoomFilter {
  String? campusId;
  String? buildingId;
  String? roomType;
  int? minCapacity;
  int? maxCapacity;
  String? date;
  List<String>? timeSlots;
  String? startTime;
  String? endTime;
  bool? hasProjector;
  bool? hasComputer;

  RoomFilter({
    this.campusId,
    this.buildingId,
    this.roomType,
    this.minCapacity,
    this.maxCapacity,
    this.date,
    this.timeSlots,
    this.startTime,
    this.endTime,
    this.hasProjector,
    this.hasComputer,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (campusId != null) data['campusId'] = campusId;
    if (buildingId != null) data['buildingId'] = buildingId;
    if (roomType != null) data['roomType'] = roomType;
    if (minCapacity != null) data['minCapacity'] = minCapacity;
    if (maxCapacity != null) data['maxCapacity'] = maxCapacity;
    if (date != null) data['date'] = date;
    if (timeSlots != null && timeSlots!.isNotEmpty) {
      data['timeSlots'] = timeSlots;
    }
    if (startTime != null) data['startTime'] = startTime;
    if (endTime != null) data['endTime'] = endTime;
    if (hasProjector != null) data['hasProjector'] = hasProjector;
    if (hasComputer != null) data['hasComputer'] = hasComputer;
    return data;
  }
}
