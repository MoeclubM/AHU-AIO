import 'dart:convert';
import 'sendrequest.dart';

Future<Map<String, dynamic>?> getUserInfo(String token) async {
  final response = await sendRequest(
    'https://jwapp.ahu.edu.cn/eams-door/api/v1/portal/home/user-info',
    token,
  );

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