import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 考试查询API
class ExamApi {
  /// 获取学生考试信息
  static Future<Map<String, dynamic>> getStudentExams(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/exam/student/exam',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }
}
