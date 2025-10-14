import 'dart:convert';
import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 培养方案查询API
class PlanApi {
  /// 获取培养方案完成情况
  static Future<Map<String, dynamic>> getPlanCompletion(String token, {String code = '01'}) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/completion/info?code=$code',
      token,
    );

    if (response != null && response.statusCode == 200) {
      // 解析响应体
      final responseBody = response.body;

      Map<String, dynamic> responseData = {};
      responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (responseData['data'] != null) {
        final data = responseData['data'];
        Map<String, dynamic> parsedData = {};

        // 处理modules数据
        if (data['modules'] != null && data['modules'] is List) {
          List<Map<String, dynamic>> modules = [];
          Map<String, dynamic> planCreditsMap = {};
          Map<String, dynamic> actualCreditsMap = {};

          for (var module in data['modules']) {
            if (module is Map) {
              final typeName = module['type']?['nameZh']?.toString() ?? '';
              final requiredCredits = module['requireInfo']?['requiredCredits'] ?? 0;
              final passedCredits = module['passedCredits'] ?? 0;

              if (typeName.isNotEmpty) {
                planCreditsMap[typeName] = requiredCredits;
                actualCreditsMap[typeName] = passedCredits;
              }

              modules.add({
                'name': typeName,
                'requiredCredits': requiredCredits,
                'actualCredits': passedCredits,
                'result': module['result'] ?? '未知',
                'courses': module['planCourses'] ?? [],
              });
            }
          }

          parsedData = {
            'modules': modules,
            'planCreditsMap': planCreditsMap,
            'actualCreditsMap': actualCreditsMap,
            'totalPlanCredits': (data['requireInfo']?['credits'] as num?)?.toInt() ?? 0,
            'outOfPlanCompletion': _calculateOutOfPlanCompletion(data['outplanCourses'] ?? []),
            'outOfPlanCredits': _calculateOutOfPlanCredits(data['outplanCourses'] ?? []),
          };
        } else {
          // 如果没有modules数据，创建默认数据
          parsedData = {
            'modules': [],
            'planCreditsMap': {},
            'actualCreditsMap': {},
            'totalPlanCredits': (data['requireInfo']?['credits'] as num?)?.toInt() ?? 0,
            'outOfPlanCompletion': 0.0,
            'outOfPlanCredits': 0,
          };
        }

        return parsedData;
      } else {
        throw Exception('API响应中缺少data字段');
      }
    } else {
      throw Exception('API请求失败: ${response?.statusCode ?? '未知错误'}');
    }
  }

  
  /// 计算计划外完成情况
  static double _calculateOutOfPlanCompletion(List outplanCourses) {
    if (outplanCourses.isEmpty) return 0.0;

    int passedCourses = outplanCourses.where((course) =>
      course['result'] == '通过' || course['result'] == 'passed'
    ).length;

    return passedCourses / outplanCourses.length;
  }

  /// 计算计划外学分
  static int _calculateOutOfPlanCredits(List outplanCourses) {
    if (outplanCourses.isEmpty) return 0;

    double totalCredits = 0.0;
    for (var course in outplanCourses) {
      if (course['result'] == '通过' || course['result'] == 'passed') {
        totalCredits += (course['course']?['credits'] ?? 0).toDouble();
      }
    }

    return totalCredits.round();
  }

  /// 获取培养类型列表
  static Future<List<dynamic>> getCultivateTypes(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/completion/cultivateTypes',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取培养方案查询信息
  static Future<Map<String, dynamic>> getPlanQuery(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/info',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取计划列表
  static Future<List<dynamic>> getPlans(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/plans',
      token,
    );
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取课程要求
  static Future<List<dynamic>> getPlanRequirements(String token, String planId) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/requirements/$planId',
      token,
    );
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取已完成课程
  static Future<List<dynamic>> getCompletedCourses(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/completed-courses',
      token,
    );
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 判断课程是否通过
  static bool _isCoursePassed(String score) {
    if (score.isEmpty) return false;

    // 检查等级制成绩
    if (score.contains('优秀') || score.contains('良好') ||
        score.contains('中等') || score.contains('及格')) {
      return true;
    }

    // 检查数字制成绩
    final numericScore = double.tryParse(score);
    if (numericScore != null) {
      return numericScore >= 60;
    }

    return false;
  }

  /// 判断是否为核心课程
  static bool _isCoreCourse(String courseType) {
    return courseType.contains('必修') || courseType.contains('核心');
  }

  /// 获取培养方案汇总
  static Future<Map<String, dynamic>> getPlanSummary(String token, String planId) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/plan/search/summary/$planId',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }
}