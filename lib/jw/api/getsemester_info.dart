import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 学期信息API
class SemesterApi {
  /// 获取学生学期列表
  static Future<List<dynamic>> getStudentSemesters(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/semester/std-semesters',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取当前学期信息
  static Future<Map<String, dynamic>> getCurrentSemester(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/lesson/student/current-semester',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取当前周次信息
  static Future<Map<String, dynamic>> getCurrentWeek(
    String token,
    int semesterId,
  ) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/semester/current-week/$semesterId',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取课程单元信息
  static Future<List<dynamic>> getCourseUnits(
    String token, {
    int bizTypeId = 2,
    String? semesterId,
    String? campusId,
  }) async {
    String url =
        'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/system/course-units?bizTypeId=$bizTypeId';
    if (semesterId != null) {
      url += '&semesterId=$semesterId';
    }
    if (campusId != null && campusId.isNotEmpty) {
      url += '&campusId=$campusId';
    }

    final response = await sendRequest(url, token);
    return ApiResponseHandler.handleListResponse(response);
  }
}
