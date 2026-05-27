import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 教室查询API
class RoomApi {
  /// 获取校区列表
  static Future<List<dynamic>> getCampuses(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/place/campus',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取教室类型列表
  static Future<List<dynamic>> getRoomTypes(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/place/roomTypes',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取建筑列表
  static Future<List<dynamic>> getBuildings(
    String token, {
    String? campusAssoc,
  }) async {
    final url = campusAssoc != null
        ? 'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/place/building?campusAssoc=$campusAssoc'
        : 'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/place/building';

    final response = await sendRequest(url, token);

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取楼层列表
  static Future<List<dynamic>> getFloors(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/place/floors',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取教室列表 (POST请求)
  static Future<Map<String, dynamic>> getRooms(
    String token,
    Map<String, dynamic> filters,
  ) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/place/rooms',
      token,
      method: 'POST',
      body: filters,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取教室占用情况 (POST请求)
  static Future<Map<String, dynamic>> getRoomOccupancy(
    String token,
    Map<String, dynamic> params,
  ) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/place/room-occupancy',
      token,
      method: 'POST',
      body: params,
    );

    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 获取课程单元列表
  static Future<List<dynamic>> getCourseUnits(String token) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/system/course-units',
      token,
    );

    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取教室课表
  static Future<Map<String, dynamic>> getRoomSchedule(
    String token,
    String roomId,
    String weekStartDate,
  ) async {
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1/room/room/$roomId/schedule?week=$weekStartDate',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }
}
