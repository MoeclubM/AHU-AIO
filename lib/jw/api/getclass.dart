import 'dart:convert';
import 'sendrequest.dart';

Future<List<dynamic>?> getClass(String token, {String? semesterId}) async {
  // semesterId 必须传入，不使用默认值
  if (semesterId == null) {
    throw Exception('semesterId 参数不能为空，请传入实际的学期ID');
  }
  final semester = semesterId;
  final url = 'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/lesson/student/course-table/$semester';
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