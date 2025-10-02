import 'dart:convert';
import 'sendrequest.dart';

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

  if (response == null) {
    throw Exception('网络请求超时');
  }

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['result'] == 0) {
      final List<dynamic> semesterList = data['data'];
      return semesterList.map((json) => SemesterInfo.fromJson(json)).toList();
    }
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized');
  }
  return null;
}