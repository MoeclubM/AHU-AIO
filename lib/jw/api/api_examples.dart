// ignore_for_file: dangling_library_doc_comments, unused_import
/// API使用示例
import 'api_manager.dart';
import 'api_models.dart';

/// API使用示例类
class ApiExamples {
  static String _token = 'your_token_here';

  /// 示例1: 获取用户完整信息
  static Future<Map<String, dynamic>> getUserCompleteInfo() async {
    try {
      // 获取用户基本信息
      final userInfo = await ApiManager.getUserInfo(_token);

      // 获取当前学期信息
      final currentSemester = await ApiManager.getCurrentSemester(_token);

      // 获取用户配置
      final userConfig = await ApiManager.getUserConfig(_token);

      return {
        'userInfo': userInfo,
        'currentSemester': currentSemester,
        'userConfig': userConfig,
      };
    } catch (e) {
      throw Exception('获取用户信息失败: $e');
    }
  }

  /// 示例2: 获取学生的学术信息（课表、成绩、考试）
  static Future<Map<String, dynamic>> getStudentAcademicInfo() async {
    try {
      // 获取当前学期
      final currentSemester = await ApiManager.getCurrentSemester(_token);
      final semesterId = currentSemester['semesterId'].toString();

      // 并行获取所有学术信息
      final results = await Future.wait([
        ApiManager.getStudentSchedule(_token, semesterId),
        ApiManager.getStudentGrades(_token),
        ApiManager.getStudentExams(_token),
        ApiManager.getCurrentWeek(_token, currentSemester['semesterId']),
      ]);

      return {
        'schedule': results[0],
        'grades': results[1],
        'exams': results[2],
        'currentWeek': results[3],
        'semesterId': semesterId,
      };
    } catch (e) {
      throw Exception('获取学术信息失败: $e');
    }
  }

  /// 示例3: 获取指定学期的详细信息
  static Future<Map<String, dynamic>> getSemesterDetails(int semesterId) async {
    try {
      final results = await Future.wait([
        ApiManager.getGradesBySemester(_token, semesterId),
        ApiManager.getStudentSchedule(_token, semesterId.toString()),
        ApiManager.getCurrentWeek(_token, semesterId),
      ]);

      return {
        'semesterId': semesterId,
        'grades': results[0],
        'schedule': results[1],
        'weekInfo': results[2],
      };
    } catch (e) {
      throw Exception('获取学期详情失败: $e');
    }
  }

  /// 示例4: 获取首页所需的所有信息
  static Future<Map<String, dynamic>> getHomeData() async {
    try {
      final results = await Future.wait([
        ApiManager.getUserInfo(_token),
        ApiManager.getCurrentSemester(_token),
        ApiManager.getNotices(_token),
        ApiManager.getTodos(_token),
        ApiManager.getSchedules(_token),
      ]);

      return {
        'userInfo': results[0],
        'currentSemester': results[1],
        'notices': results[2],
        'todos': results[3],
        'schedules': results[4],
      };
    } catch (e) {
      throw Exception('获取首页数据失败: $e');
    }
  }

  /// 示例5: 检查Token状态并刷新信息
  static Future<Map<String, dynamic>> checkTokenAndRefresh() async {
    try {
      // 检查Token是否有效
      final isValid = await ApiManager.isTokenValid(_token);

      if (!isValid) {
        return {
          'valid': false,
          'message': 'Token已失效，请重新登录',
        };
      }

      // 获取API状态
      final apiStatus = await ApiManager.getApiStatus(_token);

      return {
        'valid': true,
        'apiStatus': apiStatus,
        'message': 'Token有效',
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Token检查失败: $e',
      };
    }
  }

  /// 示例6: 获取成绩统计信息
  static Future<Map<String, dynamic>> getGradeStatistics() async {
    try {
      // 获取所有成绩
      final grades = await ApiManager.getStudentGrades(_token);

      // 获取绩点统计
      final gpaStats = await ApiManager.getGpaStats(_token);

      // 获取学期列表
      final semesters = await ApiManager.getGradeSemesters(_token);

      // 计算基本统计信息
      double totalCredits = 0;
      double totalScore = 0;
      double totalGpa = 0;

      for (var grade in grades) {
        totalCredits += (grade['credit'] ?? 0).toDouble();
        totalScore += (grade['score'] ?? 0).toDouble();
        totalGpa += (grade['gpa'] ?? 0).toDouble();
      }

      double averageScore = totalCredits > 0 ? totalScore / grades.length : 0;
      double averageGpa = totalCredits > 0 ? totalGpa / grades.length : 0;

      return {
        'totalCourses': grades.length,
        'totalCredits': totalCredits,
        'averageScore': averageScore.toStringAsFixed(2),
        'averageGpa': averageGpa.toStringAsFixed(2),
        'gpaStats': gpaStats,
        'semesters': semesters,
        'grades': grades,
      };
    } catch (e) {
      throw Exception('获取成绩统计失败: $e');
    }
  }

  /// 示例7: 获取周课表信息
  static Future<Map<String, dynamic>> getWeeklySchedule() async {
    try {
      // 获取当前学期
      final currentSemester = await ApiManager.getCurrentSemester(_token);
      final semesterId = currentSemester['semesterId'];

      // 获取当前周次
      final currentWeek = await ApiManager.getCurrentWeek(_token, semesterId);

      // 获取课表
      final schedule = await ApiManager.getStudentSchedule(_token, semesterId.toString());

      // 获取课程单元
      final courseUnits = await ApiManager.getCourseUnits(_token, semesterId: semesterId.toString());

      return {
        'currentSemester': currentSemester,
        'currentWeek': currentWeek,
        'schedule': schedule,
        'courseUnits': courseUnits,
      };
    } catch (e) {
      throw Exception('获取周课表失败: $e');
    }
  }

  /// 设置Token（实际使用时应该从持久化存储中获取）
  static void setToken(String token) {
    _token = token;
  }

  /// 获取当前Token
  static String get token => _token;
}
