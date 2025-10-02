import 'dart:convert';
import 'sendrequest.dart';

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

  if (response == null) {
    throw Exception('网络请求超时');
  }

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['result'] == 0) {
      return CurrentSemesterInfo.fromJson(data['data']);
    }
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized');
  }
  return null;
}