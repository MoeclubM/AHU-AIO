import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 成绩查询API
class GradeApi {
  /// 获取学生成绩
  static Future<List<dynamic>> getStudentGrades(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/grade/student/grades',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取学期列表（用于筛选成绩）
  static Future<List<dynamic>> getSemesters(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/semester/bizType-semesters?bizTypeId=2',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取指定学期的成绩
  static Future<List<dynamic>> getGradesBySemester(
    String token,
    int semesterId,
  ) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/grade/student/grades?semesterId=$semesterId',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取绩点统计信息
  static Future<Map<String, dynamic>> getGpaStats(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/grade/student/gpa-stats',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }
}
