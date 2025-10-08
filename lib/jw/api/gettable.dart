import 'sendrequest.dart';
import 'api_response_handler.dart';

Future<List<dynamic>?> getTable(String token, {String? semesterId}) async {
  // semesterId 必须传入，不使用默认值
  if (semesterId == null) {
    throw Exception('semesterId 参数不能为空，请传入实际的学期ID');
  }
  
  final url = 'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/system/course-units?bizTypeId=2&semesterId=$semesterId&campusId=';
  final response = await sendRequest(url, token);
  
  return ApiResponseHandler.handleStandardResponse(response);
}