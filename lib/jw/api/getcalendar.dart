import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 校历查询API
class CalendarApi {
  /// 获取所有学期
  static Future<List<dynamic>> getAllSemesters(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-door/api/v1/calendar/get-all-semesters',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取校历事件
  static Future<Map<String, dynamic>> getCalendarEvents(String token, int semesterId) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-door/api/v1/calendar/get-calendar-event?semesterId=$semesterId',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取校园布局表
  static Future<Map<String, dynamic>> getCampusLayoutTable(String token, int semesterId) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-door/api/v1/calendar/get-campus-layout-table?semesterId=$semesterId',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取当前学期
  static Future<Map<String, dynamic>> getCurrentSemester(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-door/api/v1/semester/current-semester',
      token,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }
}