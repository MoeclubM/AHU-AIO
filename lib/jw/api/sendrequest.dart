import 'package:http/http.dart' as http;
import 'dart:convert';

Future<http.Response?> sendRequest(String url, String token, {String method = 'GET', Map<String, dynamic>? body}) async {
  try {
    final headers = {
      'accept': 'application/json',
      'authorization': token, // 直接使用token，不带JWTToken前缀
      'content-type': 'application/json;charset=UTF-8',
      'referer': 'https://jwapp.ahu.edu.cn/uniapp/',
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
      'sec-ch-ua': '"Chromium";v="140", "Not=A?Brand";v="24", "Google Chrome";v="140"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'usertoken': token,
      'x-id-token': token,
    };

    late Future<http.Response> responseFuture;

    switch (method.toUpperCase()) {
      case 'POST':
        responseFuture = http.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        responseFuture = http.put(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        responseFuture = http.delete(
          Uri.parse(url),
          headers: headers,
        );
        break;
      case 'GET':
      default:
        responseFuture = http.get(
          Uri.parse(url),
          headers: headers,
        );
        break;
    }

    final response = await responseFuture.timeout(const Duration(seconds: 15));
    return response;
  } catch (e) {
    return null; // 请求超时或其他错误
  }
}