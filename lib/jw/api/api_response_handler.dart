import 'dart:convert';
import 'package:http/http.dart' as http;

/// 通用API响应处理器
class ApiResponseHandler {
  /// 处理标准API响应
  /// 返回解析后的数据，如果失败则抛出异常
  static dynamic handleStandardResponse(http.Response? response) {
    if (response == null) {
      throw Exception('网络请求超时');
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        // 检查多种可能的响应格式
        if (data['result'] == 0 || data['code'] == 0 || data['success'] == true) {
          return data['data'] ?? data;
        } else {
          throw Exception('API返回错误: ${data['message'] ?? data['msg'] ?? data['error'] ?? '未知错误'}');
        }
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('响应数据解析失败: ${e.toString()}');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - 登录已过期，请重新登录');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - 没有权限访问此资源');
    } else if (response.statusCode == 404) {
      throw Exception('Not Found - 请求的资源不存在');
    } else if (response.statusCode >= 500) {
      throw Exception('服务器错误: ${response.statusCode}');
    } else {
      throw Exception('HTTP错误: ${response.statusCode}');
    }
  }

  /// 处理简单API响应（不检查result字段）
  /// 返回解析后的完整数据
  static Map<String, dynamic> handleSimpleResponse(http.Response? response) {
    if (response == null) {
      throw Exception('网络请求超时');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('HTTP错误: ${response.statusCode}');
    }
  }

  /// 处理列表响应，直接返回数据数组
  static List<dynamic> handleListResponse(http.Response? response) {
    if (response == null) {
      throw Exception('网络请求超时');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map) {
        // 如果是对象，尝试提取data字段或直接返回
        return data['data'] ?? [data];
      } else {
        throw Exception('响应数据格式错误');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('HTTP错误: ${response.statusCode}');
    }
  }
}