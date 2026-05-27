import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// 新教务系统 API 客户端 (jw.ahu.edu.cn)
class JwApi {
  static final JwApi _instance = JwApi._internal();
  factory JwApi() => _instance;

  static const String baseUrl = 'https://jw.ahu.edu.cn';
  late final Dio _dio;
  late final PersistCookieJar _cookieJar;
  String? studentId;
  bool _initialized = false;

  JwApi._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json;charset=UTF-8',
          'Referer': 'https://jw.ahu.edu.cn/student/login',
          'Origin': 'https://jw.ahu.edu.cn',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
        },
      ),
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    final dir = await path_provider.getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/jw_cookies'),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
    _initialized = true;
  }

  PersistCookieJar get cookieJar {
    if (!_initialized) {
      throw StateError('JwApi not initialized. Call init() first.');
    }
    return _cookieJar;
  }

  Future<void> deleteAllCookies() async {
    if (!_initialized) return;
    try {
      await _cookieJar.deleteAll();
    } catch (_) {}
  }

  Future<bool> hasValidSession() async {
    if (!_initialized) return false;
    try {
      final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
      final hasSession = cookies.any(
        (c) => c.name == 'SESSION' || c.name == '__pstsid__',
      );
      if (!hasSession) return false;
      final resp = await _dio.get(
        '/student/home/get-current-teach-week',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      return resp.statusCode == 200 && resp.data is Map;
    } catch (_) {
      return false;
    }
  }

  /// 获取登录盐值
  Future<String> getLoginSalt() async {
    final resp = await _dio.get(
      '/student/login-salt',
      options: Options(
        contentType: 'text/plain',
        responseType: ResponseType.plain,
      ),
    );
    return resp.data.toString().trim();
  }

  /// 访问登录页面建立 session cookie（必须在 getLoginSalt 之前调用）
  Future<void> prepareLogin() async {
    try {
      await _dio.get('/student/login');
    } catch (_) {}
  }

  /// 获取登录验证码图片 (GET /student/login-captcha)
  /// 返回 {"code":"0000","originalImageBase64":"iVBOR..."}
  Future<Map<String, dynamic>> getLoginCaptcha() async {
    final resp = await _dio.get('/student/login-captcha');
    return Map<String, dynamic>.from(resp.data);
  }

  /// 登录
  Future<LoginResult> login({
    required String username,
    required String passwordHash,
    String captchaToken = '',
  }) async {
    try {
      final data = <String, dynamic>{
        'username': username,
        'password': passwordHash,
      };
      if (captchaToken.isNotEmpty) {
        data['captchaToken'] = captchaToken;
      }
      final resp = await _dio.post('/student/login', data: data);
      final body = resp.data;
      if (body is Map && body['result'] == true) {
        studentId = await _fetchStudentId();
        return LoginResult(success: true);
      }
      return LoginResult(
        success: false,
        message: body['message']?.toString() ?? '登录失败',
        needCaptcha: body['needCaptcha'] == true,
      );
    } on DioException catch (e) {
      return LoginResult(
        success: false,
        message: '服务器错误(${e.response?.statusCode}): ${e.message}',
      );
    }
  }

  /// 从 grade/sheet 重定向提取 studentId
  Future<String?> _fetchStudentId() async {
    try {
      final resp = await _dio.get(
        '/student/for-std/grade/sheet',
        options: Options(followRedirects: false),
      );
      if (resp.statusCode == 302) {
        final loc = resp.headers.value('location') ?? '';
        final parts = loc.split('/');
        for (int i = 0; i < parts.length; i++) {
          if (parts[i] == 'semester-index' && i + 1 < parts.length) {
            return parts[i + 1];
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> fetchStudentIdDirect() async {
    studentId = await _fetchStudentId();
  }

  // ============ 首页 API ============

  /// {"currentSemester":"2025-2026-2","dayIndex":-86,"weekIndex":13,"isInSemester":true}
  Future<Map<String, dynamic>> getCurrentTeachWeek() async {
    final resp = await _dio.get('/student/home/get-current-teach-week');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<List<dynamic>> getMenu() async {
    final resp = await _dio.get('/student/home/menu');
    return List<dynamic>.from(resp.data);
  }

  /// 通知数量 {"notices":[],"noticeCount":{"notificationCount":4,"noReadCount":0,"readCount":4}}
  Future<Map<String, dynamic>> getNoticeCounts() async {
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

  /// 分页通知列表
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await _dio.get(
      '/student/my-notification/get-notifications',
      queryParameters: {'_current_page_': page, '_page_size_': pageSize},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 成绩 API ============

  /// 获取成绩（含学期列表）
  /// 返回 {"semesterId2studentGrades":{"92":[gradeItems...]},"semesters":[semesterList],"id2semesters":{}}
  Future<Map<String, dynamic>> getGrades(int semesterId) async {
    final resp = await _dio.get(
      '/student/for-std/grade/sheet/info/$studentId',
      queryParameters: {'semester': semesterId},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 获取所有学期列表（从 grade sheet 推导）
  Future<List<Map<String, dynamic>>> getSemesters() async {
    final raw = await getGrades(0);
    final semesters = raw['semesters'] as List? ?? [];
    return semesters
        .whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  }

  /// 获取非重修成绩ID列表
  Future<Map<String, dynamic>> getNotRetakeGrades() async {
    final resp = await _dio.get(
      '/student/for-std/grade/sheet/get-not-retake-grade/$studentId',
    );
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 课表 API ============

  Future<Map<String, dynamic>> getSemester(int semesterId) async {
    final resp = await _dio.get('/student/ws/semester/get/$semesterId');
    return Map<String, dynamic>.from(resp.data);
  }

  /// 课表详细数据（lessons数组 + scheduleText）
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

  /// 课表打印数据（结构化活动: weekday, startUnit, endUnit, weekIndexes）
  /// 返回 {"studentTableVms":[{"id":122304,"name":"...","code":"P...","activities":[...]}]}
  Future<Map<String, dynamic>> getCourseTablePrintData(int semesterId) async {
    final resp = await _dio.get(
      '/student/for-std/course-table/semester/$semesterId/print-data',
      queryParameters: {'semesterId': semesterId, 'hasExperiment': 'false'},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  // ============ 培养方案 API ============

  /// 获取培养方案课程模块
  Future<Map<String, dynamic>> getProgramModules(int programId) async {
    final resp = await _dio.get(
      '/student/for-std/credit-certification-apply/other_apply/get-all-course-module',
      queryParameters: {'programId': programId},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// 从培养方案页面 HTML 提取 programId
  Future<int?> fetchProgramId() async {
    try {
      final resp = await _dio.get(
        '/student/for-std/program-completion-preview/info/$studentId',
        options: Options(responseType: ResponseType.plain),
      );
      final html = resp.data.toString();
      // 匹配 programId=3007 或 programId: 3007
      final match = RegExp(r'programId[=:]\s*(\d+)').firstMatch(html);
      if (match != null) return int.tryParse(match.group(1)!);
    } catch (_) {}
    return null;
  }
}

class LoginResult {
  final bool success;
  final String? message;
  final bool needCaptcha;

  LoginResult({required this.success, this.message, this.needCaptcha = false});
}
