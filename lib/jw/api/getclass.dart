import 'dart:convert';
import 'sendrequest.dart';

Future<List<dynamic>?> getClass(String token) async {
  const url = 'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/lesson/student/course-table/52';
  final response = await sendRequest(url, token);

  if (response == null) {
    throw Exception('网络请求超时');
  }

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['result'] == 0) {
      return data['data'];
    }
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized');
  }
  return null;
}