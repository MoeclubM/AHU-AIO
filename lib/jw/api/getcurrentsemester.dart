import 'sendrequest.dart';
import 'api_response_handler.dart';

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
      id: json['id'],
      code: json['code'],
      nameZh: json['nameZh'],
      nameEn: json['nameEn'],
      schoolYear: json['schoolYear'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      season: json['season'],
      weekIndices: List<int>.from(json['weekIndices']),
    );
  }
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