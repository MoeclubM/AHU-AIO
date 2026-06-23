import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/cas_auth_cache.dart';
import '../../auth/cas_native_client.dart';
import '../models/jw_models.dart';

/// 新教务系统 API 客户端 (jw.ahu.edu.cn)
class JwApi {
  static final JwApi _instance = JwApi._internal();
  factory JwApi() => _instance;

  static const String baseUrl = 'https://jw.ahu.edu.cn';
  static const String ssoLoginUrl = '$baseUrl/student/sso/login';
  late final Dio _dio;
  late final PersistCookieJar _cookieJar;
  String? studentId;
  bool _initialized = false;
  bool _isReLoggingIn = false;

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
    _cookieJar = await CasAuthCache.cookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          // 如果返回了包含 html 的文本，代表会话已失效重定向到了登录页
          if (response.data is String &&
              (response.data.toString().contains('<!DOCTYPE html>') ||
                  response.data.toString().contains('<html>') ||
                  response.data.toString().contains('login') ||
                  response.data.toString().contains('教务学生学生综合业务'))) {
            final success = await _attemptSilentReLogin();
            if (success) {
              final opts = response.requestOptions;
              try {
                final retryResp = await _dio.request(
                  opts.path,
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                  options: Options(method: opts.method, headers: opts.headers),
                );
                return handler.resolve(retryResp);
              } catch (e) {
                return handler.reject(
                  DioException(requestOptions: opts, error: e),
                );
              }
            }
          }
          return handler.next(response);
        },
        onError: (err, handler) async {
          final isUnauthorized =
              err.response?.statusCode == 401 ||
              err.response?.statusCode == 302;
          final isHtmlError =
              err.response?.data is String &&
              (err.response!.data.toString().contains('<!DOCTYPE html>') ||
                  err.response!.data.toString().contains('login'));

          if (isUnauthorized || isHtmlError) {
            final success = await _attemptSilentReLogin();
            if (success) {
              final opts = err.requestOptions;
              try {
                final retryResp = await _dio.request(
                  opts.path,
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                  options: Options(method: opts.method, headers: opts.headers),
                );
                return handler.resolve(retryResp);
              } catch (e) {
                return handler.reject(
                  DioException(requestOptions: opts, error: e),
                );
              }
            }
          }
          return handler.next(err);
        },
      ),
    );

    _initialized = true;
  }

  Future<bool> _attemptSilentReLogin() async {
    if (_isReLoggingIn) return false;
    _isReLoggingIn = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final u = prefs.getString('username');
      final p = prefs.getString('password');
      if (u != null && p != null && u.isNotEmpty && p.isNotEmpty) {
        final cas = CasNativeClient(cookieJar: _cookieJar);
        await cas.login(
          loginUri: CasNativeClient.loginUriForService(ssoLoginUrl),
          username: u,
          password: p,
          trustDevice: true,
        );
        studentId = await _fetchStudentId();
        return studentId != null;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isReLoggingIn = false;
    }
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

  Future<void> loginWithCas({
    required String username,
    required String password,
    required bool trustDevice,
  }) async {
    await init();
    final cas = CasNativeClient(cookieJar: _cookieJar);
    final result = await cas.login(
      loginUri: CasNativeClient.loginUriForService(ssoLoginUrl),
      username: username,
      password: password,
      trustDevice: trustDevice,
    );
    if (!await hasValidSession()) {
      throw StateError('CAS 登录完成但教务会话未建立：${result.finalUri}');
    }
    await fetchStudentIdDirect();
  }

  Future<bool> loginWithCachedCas() async {
    await init();
    final cas = CasNativeClient(cookieJar: _cookieJar);
    final result = await cas.loginWithCachedSession(
      loginUri: CasNativeClient.loginUriForService(ssoLoginUrl),
    );
    if (result == null) return false;
    if (!await hasValidSession()) {
      throw StateError('CAS 会话复用完成但教务会话未建立：${result.finalUri}');
    }
    await fetchStudentIdDirect();
    return true;
  }

  Future<bool> hasValidSession() async {
    if (!_initialized) return false;
    try {
      final cookies = await _cookieJar.loadForRequest(
        Uri.parse('$baseUrl/student/'),
      );
      final hasSession = cookies.any(
        (c) => c.name == 'SESSION' || c.name == '__pstsid__',
      );
      if (!hasSession) return false;
      final resp = await _dio.get(
        '/student/home/get-current-teach-week',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        // 会话有效，顺便恢复 studentId
        studentId ??= await _fetchStudentId();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 从 grade/sheet 重定向提取 studentId
  Future<String?> _fetchStudentId() async {
    try {
      final resp = await _dio.get(
        '/student/for-std/grade/sheet',
        options: Options(
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
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

  /// 获取所有学期列表（从多个 grade sheet 请求收集）
  Future<List<Map<String, dynamic>>> getSemesters() async {
    final allSemesters = <int, Map<String, dynamic>>{};
    for (final semId in [112, 92, 72, 52]) {
      try {
        final raw = await getGrades(semId);
        final semesters = raw['semesters'] as List? ?? [];
        for (final s in semesters) {
          if (s is Map) {
            final id = toInt(s['id']);
            if (id != null) allSemesters[id] = Map<String, dynamic>.from(s);
          }
        }
      } catch (_) {}
    }
    final sorted = allSemesters.values.toList()
      ..sort((a, b) => (toInt(b['id']) ?? 0).compareTo(toInt(a['id']) ?? 0));
    return sorted;
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
