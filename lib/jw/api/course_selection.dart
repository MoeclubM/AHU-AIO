// ignore_for_file: unused_import
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 选课功能API
class CourseSelectionApi {
  static const String _baseUrl = 'https://jw.ahu.edu.cn/course-selection-api/api/v1/student';

  /// 发送选课系统专用请求（需要特殊headers）
  static Future<http.Response?> _sendCourseSelectionRequest(String url, String token, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(url);
      http.Response response;

      final headers = {
        'accept': 'application/json',
        'authorization': token,
        'content-type': 'application/json;charset=UTF-8',
        'referer': 'https://jwapp.ahu.edu.cn/uniapp/',
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
        'sec-ch-ua': '"Chromium";v="140", "Not=A?Brand";v="24", "Google Chrome";v="140"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'usertoken': token,
        'x-id-token': token,
      };

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;
        default:
          throw UnsupportedError('HTTP method $method is not supported');
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  /// 获取可选课程列表
  static Future<List<dynamic>> getAvailableCourses(String token, {String? semesterId}) async {
    // 根据实际抓取的API，获取选课轮次信息
    final turnsResponse = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/open-turns/122304',
      token,
    );

    if (turnsResponse != null && turnsResponse.statusCode == 200) {
      final turnsData = ApiResponseHandler.handleSimpleResponse(turnsResponse);
      // 如果有选课轮次数据，返回对应的课程信息
      if (turnsData['data'] != null && turnsData['data'] is List) {
        return turnsData['data'] as List;
      }
    }

    // 备用API：获取学生选课信息
    final studentResponse = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/students',
      token,
    );

    if (studentResponse != null && studentResponse.statusCode == 200) {
      final studentData = ApiResponseHandler.handleSimpleResponse(studentResponse);
      if (studentData['data'] != null && studentData['data'] is List) {
        return studentData['data'] as List;
      }
    }

    return [];
  }

  /// 获取选课计划
  static Future<Map<String, dynamic>> getSelectionPlan(String token, String semesterId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/plan?semesterId=$semesterId',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取已选课程
  static Future<List<dynamic>> getSelectedCourses(String token, {String? semesterId}) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/selected${semesterId != null ? '?semesterId=$semesterId' : ''}',
      token,
    );

    if (response != null && response.statusCode == 200) {
      final data = ApiResponseHandler.handleSimpleResponse(response);
      if (data['data'] != null && data['data'] is List) {
        return data['data'] as List;
      }
    }

    return [];
  }

  /// 搜索课程
  static Future<List<dynamic>> searchCourses(String token, Map<String, dynamic> searchParams) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/search',
      token,
      method: 'POST',
      body: searchParams,
    );

    if (response != null && response.statusCode == 200) {
      final data = ApiResponseHandler.handleSimpleResponse(response);
      if (data['data'] != null && data['data'] is List) {
        return data['data'] as List;
      }
    }

    return [];
  }

  /// 获取课程详情
  static Future<Map<String, dynamic>> getCourseDetails(String token, String courseId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/course/$courseId',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取课程教学班列表
  static Future<List<dynamic>> getCourseClasses(String token, String courseId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/course/$courseId/classes',
      token,
    );

    if (response != null && response.statusCode == 200) {
      final data = ApiResponseHandler.handleSimpleResponse(response);
      if (data['data'] != null && data['data'] is List) {
        return data['data'] as List;
      }
    }

    return [];
  }

  /// 选课
  static Future<Map<String, dynamic>> selectCourse(String token, Map<String, dynamic> selectionData) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/select',
      token,
      method: 'POST',
      body: selectionData,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 退选
  static Future<Map<String, dynamic>> dropCourse(String token, String selectionId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/drop/$selectionId',
      token,
      method: 'DELETE',
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取选课结果
  static Future<Map<String, dynamic>> getSelectionResult(String token, String requestId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/result/$requestId',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取选课时间安排
  static Future<Map<String, dynamic>> getSelectionSchedule(String token) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/schedule',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取选课统计信息
  static Future<Map<String, dynamic>> getSelectionStats(String token, String semesterId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/stats/$semesterId',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取冲突检测
  static Future<Map<String, dynamic>> checkScheduleConflict(String token, Map<String, dynamic> courseData) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/conflict-check',
      token,
      method: 'POST',
      body: courseData,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取先修课程检查
  static Future<Map<String, dynamic>> checkPrerequisites(String token, String courseId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/prerequisite-check/$courseId',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取选课历史
  static Future<List<dynamic>> getSelectionHistory(String token) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/history',
      token,
    );

    if (response != null && response.statusCode == 200) {
      final data = ApiResponseHandler.handleSimpleResponse(response);
      if (data['data'] != null && data['data'] is List) {
        return data['data'] as List;
      }
    }

    return [];
  }

  /// 获取候补列表
  static Future<List<dynamic>> getWaitingList(String token, String courseId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/waiting-list/$courseId',
      token,
    );

    if (response != null && response.statusCode == 200) {
      final data = ApiResponseHandler.handleSimpleResponse(response);
      if (data['data'] != null && data['data'] is List) {
        return data['data'] as List;
      }
    }

    return [];
  }

  /// 加入候补
  static Future<Map<String, dynamic>> joinWaitingList(String token, Map<String, dynamic> waitingData) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/waiting-list/join',
      token,
      method: 'POST',
      body: waitingData,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 退出候补
  static Future<Map<String, dynamic>> leaveWaitingList(String token, String waitingId) async {
    final response = await _sendCourseSelectionRequest(
      '$_baseUrl/course-select/waiting-list/leave/$waitingId',
      token,
      method: 'DELETE',
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }
}
