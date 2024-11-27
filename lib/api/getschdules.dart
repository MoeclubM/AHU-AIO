import 'dart:convert';
import 'sendrequest.dart';

Future<Map<String, dynamic>?> getSchedules(String token, {String? date}) async {
  final url = date != null
      ? 'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-schedule/getSchedules?date=$date'
      : 'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-schedule/getSchedules';
  final response = await sendRequest(url, token);

  if (response == null) {
    throw Exception('网络请求超时');
  }

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized');
  }
  return null;
}