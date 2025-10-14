/// API管理器 - 统一管理所有教务系统API
import 'api_response_handler.dart';
import 'sendrequest.dart';
import 'getgrades.dart';
import 'getclass.dart';
import 'getexams.dart';
import 'getuserinfo_extended.dart';
import 'getsemester_info.dart';

class ApiManager {
  // API基础URL
  static const String _baseUrl = 'https://jwapp.ahu.edu.cn';
  static const String _microServerBase = '$_baseUrl/eams-micro-server/api/v1';

  // ============ 认证相关API ============
  /// 用户登录
  static Future<Map<String, dynamic>> login(String username, String password) async {
    // 注意：这里需要实现RSA加密，具体实现需要根据前端逻辑
    final url = '$_baseUrl/token/password/passwordLogin';
    final response = await sendRequest(url, '', method: 'POST', body: {
      'username': username,
      'password': password, // 这里应该是RSA加密后的密码
      'appId': 'APP_ID',
      'deviceId': 'DEVICE_ID',
      'osType': 'OS_TYPE',
      'geo': 'GEO'
    });
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  // ============ 用户信息相关API ============
  /// 获取用户基本信息
  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    return UserInfoExtendedApi.getUserInfo(token);
  }

  /// 获取用户配置
  static Future<Map<String, dynamic>> getUserConfig(String token, {String type = ''}) async {
    return UserInfoExtendedApi.getUserConfig(token, type: type);
  }

  /// 获取通知公告
  static Future<Map<String, dynamic>> getNotices(String token) async {
    return UserInfoExtendedApi.getNotices(token);
  }

  /// 获取待办事项
  static Future<Map<String, dynamic>> getTodos(String token) async {
    return UserInfoExtendedApi.getTodos(token);
  }

  /// 获取日程安排
  static Future<Map<String, dynamic>> getSchedules(String token) async {
    return UserInfoExtendedApi.getSchedules(token);
  }

  // ============ 学期信息相关API ============
  /// 获取学生学期列表
  static Future<List<dynamic>> getStudentSemesters(String token) async {
    return SemesterApi.getStudentSemesters(token);
  }

  /// 获取当前学期信息
  static Future<Map<String, dynamic>> getCurrentSemester(String token) async {
    return SemesterApi.getCurrentSemester(token);
  }

  /// 获取当前周次信息
  static Future<Map<String, dynamic>> getCurrentWeek(String token, int semesterId) async {
    return SemesterApi.getCurrentWeek(token, semesterId);
  }

  /// 获取课程单元信息
  static Future<List<dynamic>> getCourseUnits(String token, {int bizTypeId = 2, String? semesterId, String? campusId}) async {
    return SemesterApi.getCourseUnits(token, bizTypeId: bizTypeId, semesterId: semesterId, campusId: campusId);
  }

  // ============ 课表相关API ============
  /// 获取学生课表
  static Future<List<dynamic>?> getStudentSchedule(String token, String semesterId) async {
    return getClass(token, semesterId: semesterId);
  }

  // ============ 成绩相关API ============
  /// 获取学生成绩
  static Future<List<dynamic>> getStudentGrades(String token) async {
    return GradeApi.getStudentGrades(token);
  }

  /// 获取指定学期成绩
  static Future<List<dynamic>> getGradesBySemester(String token, int semesterId) async {
    return GradeApi.getGradesBySemester(token, semesterId);
  }

  /// 获取学期列表（用于成绩筛选）
  static Future<List<dynamic>> getGradeSemesters(String token) async {
    return GradeApi.getSemesters(token);
  }

  /// 获取绩点统计
  static Future<Map<String, dynamic>> getGpaStats(String token) async {
    return GradeApi.getGpaStats(token);
  }

  // ============ 考试相关API ============
  /// 获取学生考试信息
  static Future<Map<String, dynamic>> getStudentExams(String token) async {
    return ExamApi.getStudentExams(token);
  }

  /// 获取考试安排
  static Future<List<dynamic>> getExamSchedule(String token) async {
    final response = await sendRequest('$_microServerBase/exam/student/schedule', token);
    return ApiResponseHandler.handleListResponse(response);
  }

  // ============ 学籍信息相关API ============
  /// 获取学籍信息
  static Future<Map<String, dynamic>> getAcademicInfo(String token) async {
    final response = await sendRequest('$_microServerBase/student/academic/info', token);
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取专业信息
  static Future<Map<String, dynamic>> getProgramInfo(String token) async {
    final response = await sendRequest('$_microServerBase/student/program/info', token);
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  // ============ 其他功能API ============
  /// 获取日历信息
  static Future<Map<String, dynamic>> getCalendar(String token) async {
    final response = await sendRequest('$_microServerBase/calendar/academic', token);
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取教室信息
  static Future<Map<String, dynamic>> getRoom(String token) async {
    final response = await sendRequest('$_microServerBase/room/search', token);
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取培养方案
  static Future<Map<String, dynamic>> getPlan(String token) async {
    final response = await sendRequest('$_microServerBase/plan/student/overview', token);
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  // ============ 工具方法 ============
  /// 检查Token是否有效
  static Future<bool> isTokenValid(String token) async {
    try {
      final response = await getUserInfo(token);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 获取API状态信息
  static Future<Map<String, dynamic>> getApiStatus(String token) async {
    try {
      final userInfo = await getUserInfo(token);
      final currentSemester = await getCurrentSemester(token);

      return {
        'userLoggedIn': true,
        'userInfo': userInfo,
        'currentSemester': currentSemester,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'userLoggedIn': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}