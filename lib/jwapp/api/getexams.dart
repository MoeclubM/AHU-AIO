import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 考试查询API
class ExamApi {
  static const String _examUrl =
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/exam/student/exam';

  /// 获取学生考试信息
  static Future<Map<String, dynamic>> getStudentExams(String token) async {
    final response = await sendRequest(_examUrl, token);
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取学生考试列表
  static Future<List<dynamic>> getExamList(String token) async {
    final response = await sendRequest(_examUrl, token);
    final data = ApiResponseHandler.handleStandardResponse(response);
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return [];
  }
}
