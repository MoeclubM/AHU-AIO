import 'sendrequest.dart';
import 'api_response_handler.dart';

Future<Map<String, dynamic>?> getUserInfo(String token) async {
  final response = await sendRequest(
    'https://jwapp.ahu.edu.cn/eams-door/api/v1/portal/home/user-info',
    token,
  );

  return ApiResponseHandler.handleStandardResponse(response);
}
