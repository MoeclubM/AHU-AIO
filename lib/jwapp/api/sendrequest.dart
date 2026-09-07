import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_service.dart';
import '../../globals.dart' as globals;

bool _isRefreshingToken = false;

Future<http.Response?> sendRequest(
  String url,
  String token, {
  String method = 'GET',
  Map<String, dynamic>? body,
  bool allowRetry = true,
}) async {
  try {
    final effectiveToken = token.isNotEmpty ? token : (globals.idToken ?? '');

    final headers = {
      'accept': 'application/json',
      'authorization': effectiveToken,
      'content-type': 'application/json;charset=UTF-8',
      'referer': 'https://jwapp.ahu.edu.cn/uniapp/',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
      'sec-ch-ua':
          '"Chromium";v="140", "Not=A?Brand";v="24", "Google Chrome";v="140"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'usertoken': effectiveToken,
      'x-id-token': effectiveToken,
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
        responseFuture = http.delete(Uri.parse(url), headers: headers);
        break;
      case 'GET':
      default:
        responseFuture = http.get(Uri.parse(url), headers: headers);
        break;
    }

    final response = await responseFuture.timeout(const Duration(seconds: 15));

    // 401 凭据失效自动重连机制
    if (allowRetry && response.statusCode == 401) {
      final refreshed = await _refreshJwappToken();
      if (refreshed && globals.idToken != null) {
        return sendRequest(
          url,
          globals.idToken!,
          method: method,
          body: body,
          allowRetry: false,
        );
      }
    }

    return response;
  } catch (e) {
    return null;
  }
}

Future<bool> _refreshJwappToken() async {
  if (_isRefreshingToken) return false;
  _isRefreshingToken = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    if (username != null &&
        password != null &&
        username.isNotEmpty &&
        password.isNotEmpty) {
      final newToken = await LoginService.login(
        username: username,
        password: password,
      );
      if (newToken != null && newToken.isNotEmpty) {
        globals.idToken = newToken;
        await prefs.setString('idToken', newToken);
        globals.onLoginStateChanged?.call();
        return true;
      }
    }
    return false;
  } catch (_) {
    return false;
  } finally {
    _isRefreshingToken = false;
  }
}
