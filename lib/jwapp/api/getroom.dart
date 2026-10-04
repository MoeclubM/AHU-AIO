import 'api_response_handler.dart';
import 'sendrequest.dart';

/// 教室查询 API（对齐 jwapp `eams-micro-server` 实测行为）。
///
/// 注意：
/// - `POST .../room/place/rooms` 的 `buildingId`/`campusId` **服务端基本不生效**，
///   拉全量后由客户端按楼筛选；
/// - 占用信息在请求带上 `date`、且 `pageSize` 足够大时才会出现在
///   `roomOccupationInfoVms`；
/// - 课节定义用 `room/system/course-units`（1–13 节，HHMM）。
class RoomApi {
  static const String _base =
      'https://jwapp.ahu.edu.cn/eams-micro-server/api/v1';

  /// 获取校区列表
  static Future<List<dynamic>> getCampuses(String token) async {
    final response = await sendRequest('$_base/room/place/campus', token);
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取教室类型列表
  static Future<List<dynamic>> getRoomTypes(String token) async {
    final response = await sendRequest(
      '$_base/room/place/roomTypes',
      token,
    );
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取建筑列表（按校区；参数名是 campusAssoc）
  static Future<List<dynamic>> getBuildings(
    String token, {
    String? campusAssoc,
  }) async {
    final url = campusAssoc != null && campusAssoc.isNotEmpty
        ? '$_base/room/place/building?campusAssoc=$campusAssoc'
        : '$_base/room/place/building';
    final response = await sendRequest(url, token);
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 获取楼层号列表
  static Future<List<dynamic>> getFloors(String token) async {
    final response = await sendRequest('$_base/room/place/floors', token);
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 官方课节（节次 1–13，startTime/endTime 为 HHMM）
  static Future<List<dynamic>> getCourseUnits(String token) async {
    final response = await sendRequest(
      '$_base/room/system/course-units',
      token,
    );
    return ApiResponseHandler.handleListResponse(response);
  }

  /// 拉取教室列表（含当日占用）。
  ///
  /// [pageSize] 建议 ≥500；占用字段与 `date`、分页深度有关。
  /// 返回原始 Map（含 `data.data` 列表）。
  static Future<Map<String, dynamic>> getRooms(
    String token,
    Map<String, dynamic> filters,
  ) async {
    final response = await sendRequest(
      '$_base/room/place/rooms',
      token,
      method: 'POST',
      body: filters,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 分页拉取教室，直到没有更多页或达到 [maxPages]。
  ///
  /// 每页统一带上 [date]，便于服务端返回占用。
  static Future<List<dynamic>> fetchRoomsPaged(
    String token, {
    required String date,
    int pageSize = 500,
    int maxPages = 20,
  }) async {
    final List<dynamic> all = [];
    for (int page = 1; page <= maxPages; page++) {
      final Map<String, dynamic> resp = await getRooms(token, {
        'date': date,
        'currentPage': page,
        'pageSize': pageSize,
      });
      final dynamic dataObj = resp['data'];
      final List<dynamic> pageList = (dataObj is Map)
          ? (dataObj['data'] as List? ?? <dynamic>[])
          : <dynamic>[];
      all.addAll(pageList);
      // 不足一页视为结束。
      if (pageList.length < pageSize) break;
    }
    return all;
  }

  /// 教室占用接口（备用；部分环境返回空数组，优先用 rooms 列表内嵌占用）。
  static Future<Map<String, dynamic>> getRoomOccupancy(
    String token,
    Map<String, dynamic> params,
  ) async {
    final response = await sendRequest(
      '$_base/room/place/room-occupancy',
      token,
      method: 'POST',
      body: params,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 当前学期（学生视图）
  static Future<Map<String, dynamic>> getCurrentSemester(String token) async {
    final response = await sendRequest(
      '$_base/lesson/student/current-semester',
      token,
    );
    return ApiResponseHandler.handleSimpleResponse(response);
  }

  /// 学生学期列表
  static Future<List<dynamic>> getStudentSemesters(String token) async {
    final response = await sendRequest('$_base/semester/std-semesters', token);
    return ApiResponseHandler.handleListResponse(response);
  }
}
