import 'sendrequest.dart';
import 'api_response_handler.dart';

/// 学期信息数据模型
class SemesterInfo {
  final int id;
  final String code;
  final String nameZh;
  final String nameEn;
  final String schoolYear;
  final String startDate;
  final String endDate;
  final String season;

  SemesterInfo({
    required this.id,
    required this.code,
    required this.nameZh,
    required this.nameEn,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    required this.season,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(
      id: json['id'],
      code: json['code'],
      nameZh: json['nameZh'],
      nameEn: json['nameEn'],
      schoolYear: json['schoolYear'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      season: json['season'],
    );
  }

  @override
  String toString() {
    return nameZh;
  }
}

/// 当前学期信息数据模型
class CurrentSemesterInfo {
  final int id;
  final String code;
  final String nameZh;
  final String nameEn;
  final String schoolYear;
  final String startDate;
  final String endDate;
  final String season;
  final List<int> weekIndices;

  CurrentSemesterInfo({
    required this.id,
    required this.code,
    required this.nameZh,
    required this.nameEn,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    required this.season,
    required this.weekIndices,
  });

  factory CurrentSemesterInfo.fromJson(Map<String, dynamic> json) {
    return CurrentSemesterInfo(
      id: json['id'] ?? json['semesterId'] ?? 0,
      code: json['code'] ?? json['semesterCode'] ?? '',
      nameZh: json['nameZh'] ?? json['semesterName'] ?? json['name'] ?? '未知学期',
      nameEn: json['nameEn'] ?? json['englishName'] ?? '',
      schoolYear: json['schoolYear'] ?? json['academicYear'] ?? '',
      startDate: json['startDate'] ?? json['beginDate'] ?? '',
      endDate: json['endDate'] ?? json['finishDate'] ?? '',
      season: json['season'] ?? '',
      weekIndices: json['weekIndices'] != null
          ? List<int>.from(json['weekIndices'])
          : (json['weeks'] != null ? List<int>.from(json['weeks']) : []),
    );
  }
}

/// 获取所有学期信息
Future<List<SemesterInfo>?> getAllSemestersApi(String token) async {
  final response = await sendRequest(
    'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/semester/std-semesters',
    token,
  );

  final data = ApiResponseHandler.handleStandardResponse(response);
  if (data is List) {
    return data.map((json) => SemesterInfo.fromJson(json)).toList();
  }
  return null;
}

/// 获取当前学期信息
Future<CurrentSemesterInfo?> getCurrentSemester(String token) async {
  final response = await sendRequest(
    'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/lesson/student/current-semester',
    token,
  );

  final data = ApiResponseHandler.handleStandardResponse(response);
  if (data is Map<String, dynamic>) {
    return CurrentSemesterInfo.fromJson(data);
  }
  return null;
}
