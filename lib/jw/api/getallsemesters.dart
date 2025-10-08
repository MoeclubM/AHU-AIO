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