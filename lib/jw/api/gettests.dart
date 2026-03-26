import 'sendrequest.dart';
import 'api_response_handler.dart';

Future<List<dynamic>?> getTests(String token) async {
  final response = await sendRequest(
    'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/exam/student/exam',
    token,
  );

  return ApiResponseHandler.handleStandardResponse(response);
}
