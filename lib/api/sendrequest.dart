import 'package:http/http.dart' as http;

Future<http.Response?> sendRequest(String url, String token) async {
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'authorization': 'JWTToken $token',
        'content-type': 'application/json',
        'referer': 'https://jwapp.ahu.edu.cn/uniapp/',
        'cookie': 'userToken=$token;',
        'x-id-token': token,
      },
    ).timeout(const Duration(seconds: 5)); // 设置超时时间为10秒
    return response;
  } catch (e) {
    return null; // 请求超时或其他错误
  }
}