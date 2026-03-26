import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 扩展用户信息API
class UserInfoExtendedApi {
  /// 获取用户详细信息
  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    try {
      final response = await sendRequest(
        'https://jwapp.ahu.edu.cn/eams-door/api/v1/portal/home/user-info',
        token,
      );

      return ApiResponseHandler.handleSimpleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取用户配置信息
  static Future<Map<String, dynamic>> getUserConfig(
    String token, {
    String type = '',
  }) async {
    String url =
        'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/superApp-userConfig';
    if (type.isNotEmpty) {
      url += '?type=$type';
    }

    final response = await sendRequest(url, token);
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取通知公告
  static Future<Map<String, dynamic>> getNotices(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-notice/get-notices',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取待办事项
  static Future<Map<String, dynamic>> getTodos(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-door/api/v1/todo/getTodos',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取日程安排
  static Future<Map<String, dynamic>> getSchedules(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-schedule/getSchedules',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }
}
