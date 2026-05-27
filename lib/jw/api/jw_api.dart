import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

/// 新教务系统 API 客户端 (jw.ahu.edu.cn)
class JwApi {
  static final JwApi _instance = JwApi._internal();
  factory JwApi() => _instance;

  static const String baseUrl = 'https://jw.ahu.edu.cn';
  late final Dio _dio;
  late final CookieJar _cookieJar;
  String? studentId;

  JwApi._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
      },
    ));
    _cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  CookieJar get cookieJar => _cookieJar;

  /// 获取登录盐值
  Future<String> getLoginSalt() async {
    final resp = await _dio.get('/student/login-salt');
    return resp.data.toString();
  }

  /// 登录
  Future<LoginResult> login({
    required String username,
    required String passwordHash,
    String captchaToken = '',
  }) async {
    final resp = await _dio.post(
      '/student/login',
      data: {
        'username': username,
        'password': passwordHash,
        'captchaToken': captchaToken,
      },
    );
    final data = resp.data;
    if (data['result'] == true) {
      studentId = await _fetchStudentId();
      return LoginResult(success: true);
    }
    return LoginResult(
      success: false,
      message: data['message']?.toString() ?? '登录失败',
      needCaptcha: data['needCaptcha'] == true,
    );
  }

  /// 登录后获取学生ID
  Future<String?> _fetchStudentId() async {
    try {
      final resp = await _dio.get('/student/for-std/grade/sheet');
      final location = resp.redirects.isNotEmpty
          ? resp.redirects.last.location.toString()
          : resp.realUri.toString();
      final parts = location.split('/');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i] == 'semester-index' && i + 1 < parts.length) {
          return parts[i + 1];
        }
      }
      final tableResp = await _dio.get('/student/for-std/course-table',
          options: Options(followRedirects: true));
      final html = tableResp.data.toString();
      final match = RegExp(r'dataId=(\d+)').firstMatch(html);
      if (match != null) return match.group(1);
    } catch (_) {}
    return null;
  }

  // ============ 首页 API ============

  Future<Map<String, dynamic>> getCurrentTeachWeek() async {
    final resp = await _dio.get('/student/home/get-current-teach-week');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<List<dynamic>> getMenu() async {
    final resp = await _dio.get('/student/home/menu');
    return List<dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getNotices() async {
    final resp = await _dio.get(
      '/student/my-notification/get-notices',
      queryParameters: {
        'titleOrContentLike': '',
        'currentIdentity': 'STUDENT',
        'read': 'false',
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getNotifications() async {
    final resp = await _dio.get('/student/my-notification/get-notifications');
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 成绩 API ============

  Future<Map<String, dynamic>> getGradeSemesterIndex() async {
    final resp = await _dio
        .get('/student/for-std/grade/sheet/semester-index/$studentId');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getGrades(int semesterId) async {
    final resp = await _dio.get(
      '/student/for-std/grade/sheet/info/$studentId',
      queryParameters: {'semester': semesterId},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  Future<List<dynamic>> getNotRetakeGradeIds() async {
    final resp = await _dio
        .get('/student/for-std/grade/sheet/get-not-retake-grade/$studentId');
    final data = Map<String, dynamic>.from(resp.data);
    return data['notRetakeGradeIds'] ?? [];
  }

  // ============ 课表 API ============

  Future<Map<String, dynamic>> getSemester(int semesterId) async {
    final resp = await _dio.get('/student/ws/semester/get/$semesterId');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getCourseTable({
    required int semesterId,
    int bizTypeId = 2,
  }) async {
    final resp = await _dio.get(
      '/student/for-std/course-table/get-data',
      queryParameters: {
        'semesterId': semesterId,
        'dataId': studentId,
        'bizTypeId': bizTypeId,
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getCourseTablePrintData({
    required int semesterId,
  }) async {
    final resp = await _dio.get(
      '/student/for-std/course-table/semester/$semesterId/print-data',
      queryParameters: {
        'semesterId': semesterId,
        'hasExperiment': 'false',
      },
    );
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 考试 API ============

  Future<Map<String, dynamic>> getExamArrange() async {
    final resp =
        await _dio.get('/student/for-std/exam-arrange/info/$studentId');
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 培养方案 API ============

  Future<Map<String, dynamic>> getProgramCompletion() async {
    final resp = await _dio
        .get('/student/for-std/program-completion-preview/info/$studentId');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getCourseModules(int programId) async {
    final resp = await _dio.get(
      '/student/for-std/credit-certification-apply/other_apply/get-all-course-module',
      queryParameters: {'programId': programId},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 学籍 API ============

  Future<Map<String, dynamic>> getStudentInfo() async {
    final resp = await _dio.get(
      '/student/for-std/student-info/info/$studentId',
      queryParameters: {'baseURI': '/for-std/student-info'},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 学业预警 API ============

  Future<Map<String, dynamic>> getPrecaution() async {
    final resp =
        await _dio.get('/student/precaution/index/$studentId');
    return Map<String, dynamic>.from(resp.data);
  }
}

class LoginResult {
  final bool success;
  final String? message;
  final bool needCaptcha;

  LoginResult({
    required this.success,
    this.message,
    this.needCaptcha = false,
  });
}
