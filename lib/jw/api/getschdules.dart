import 'sendrequest.dart';
import 'api_response_handler.dart';

Future<Map<String, dynamic>?> getSchedules(String token, {String? date}) async {
  final url = date != null
      ? 'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-schedule/getSchedules?date=$date'
      : 'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-schedule/getSchedules';
  final response = await sendRequest(url, token);

  return ApiResponseHandler.handleSimpleResponse(response);
}