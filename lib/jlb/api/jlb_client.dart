import 'package:dio/dio.dart';
import '../models/jlb_models.dart';

/// 近邻宝网关 API 客户端
class JlbClient {
  static const String baseUrl = 'https://yz-api.jinlb.cn/openapi/miniapp/user';
  static const String defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 '
      'MicroMessenger/7.0.20.1781(0x6700143B) NetType/WIFI MiniProgramEnv/Windows '
      'WindowsWechat/WMPF WindowsWechat(0x6309092b) XWEB/9185';

  final Dio _dio;
  String sessionId;

  JlbClient({this.sessionId = ''})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ));

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json, text/javascript, */*;',
      'content-type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'sessionId': sessionId.trim(),
      'User-Agent': defaultUserAgent,
    };
  }

  /// 验证 Session 是否有效并获取用户信息与身份码
  Future<({bool ok, String message, JlbUserInfo? user})> checkSession() async {
    if (sessionId.trim().isEmpty) {
      return (ok: false, message: '未配置 Session ID', user: null);
    }

    try {
      final resp = await _dio.get(
        '/info',
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      final code = data['code'];
      if (code == 0) {
        final body = data['body'] is Map
            ? data['body'] as Map<String, dynamic>
            : <String, dynamic>{};
        
        // 尝试拉取出库身份码
        String simpleCode = '';
        String fullCode = '';
        try {
          final idResp = await _dio.get(
            '/order/getIdentityCode',
            options: Options(headers: _getHeaders()),
          );
          if (idResp.data is Map && idResp.data['code'] == 0 && idResp.data['body'] is Map) {
            final idBody = idResp.data['body'] as Map<String, dynamic>;
            simpleCode = (idBody['simpleCode'] ?? '').toString();
            fullCode = (idBody['fullCode'] ?? '').toString();
          }
        } catch (_) {}

        final user = JlbUserInfo.fromMap(
          body,
          simpleCode: simpleCode,
          fullCode: fullCode,
        );
        return (
          ok: true,
          message: '登录有效: ${user.phone.isNotEmpty ? user.phone : user.userName}',
          user: user
        );
      } else if (code == 6 || code == 20001) {
        return (ok: false, message: 'Session 已失效，请在微信重新获取', user: null);
      } else {
        return (
          ok: false,
          message: data['msg']?.toString() ?? '验证失败 (code=$code)',
          user: null
        );
      }
    } catch (e) {
      return (ok: false, message: '网络请求异常: $e', user: null);
    }
  }

  /// 根据快递运单号核心查询包裹详情
  Future<({bool ok, String message, JlbParcelInfo? parcel})> queryByExpCode(
      String expCode) async {
    final cleanCode = expCode.trim();
    if (cleanCode.isEmpty) {
      return (ok: false, message: '请输入快递运单号', parcel: null);
    }
    if (sessionId.trim().isEmpty) {
      return (ok: false, message: '请先配置有效的 Session ID', parcel: null);
    }

    // 路径 1: 调用 /index/getByExpCode
    try {
      final resp = await _dio.get(
        '/index/getByExpCode',
        queryParameters: {'expCode': cleanCode},
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      final code = data['code'];
      if (code == 0) {
        final body = data['body'] is Map
            ? Map<String, dynamic>.from(data['body'] as Map)
            : <String, dynamic>{};
        if (body['type'] == 4) {
          return (ok: false, message: '该包裹尚未到达门店/驿站！', parcel: null);
        }
        final newOrder = body['newOrder'] is Map
            ? Map<String, dynamic>.from(body['newOrder'] as Map)
            : <String, dynamic>{};
        final orderId = newOrder['orderId']?.toString();
        if (orderId != null && orderId.isNotEmpty) {
          final detailRes = await getOrderInfo(orderId);
          if (detailRes.ok && detailRes.parcel != null) {
            return (ok: true, message: '查询成功', parcel: detailRes.parcel);
          }
          return (
            ok: true,
            message: '查询成功',
            parcel: JlbParcelInfo.fromMap(newOrder)
          );
        }
      } else if (code == 6 || code == 20001) {
        return (ok: false, message: 'Session 已过期失效，请重新授权', parcel: null);
      }
    } catch (_) {}

    // 路径 2: 备选遍历待取件列表
    final unpickRes = await getUnpickupList(pageIndex: 1, pageSize: 50);
    if (unpickRes.ok) {
      for (final item in unpickRes.list) {
        final itemCode = item.expCode.trim();
        if (itemCode.toLowerCase() == cleanCode.toLowerCase() ||
            itemCode.endsWith(cleanCode)) {
          if (item.orderId.isNotEmpty) {
            final detailRes = await getOrderInfo(item.orderId);
            if (detailRes.ok && detailRes.parcel != null) {
              return (ok: true, message: '查询成功 (待取列表匹配)', parcel: detailRes.parcel);
            }
          }
          return (ok: true, message: '查询成功 (待取列表匹配)', parcel: item);
        }
      }
    }

    return (
      ok: false,
      message: '未查询到单号 [$cleanCode] 对应的快递柜包裹信息（可能包裹未到柜、已取走或不在该账号下）',
      parcel: null
    );
  }

  /// 根据订单ID查询详细格口与物流信息
  Future<({bool ok, String message, JlbParcelInfo? parcel})> getOrderInfo(
      String orderId) async {
    try {
      final resp = await _dio.get(
        '/order/orderInfo',
        queryParameters: {'orderId': orderId},
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      if (data['code'] == 0 && data['body'] is Map) {
        final body = Map<String, dynamic>.from(data['body'] as Map);
        return (
          ok: true,
          message: '获取包裹详情成功',
          parcel: JlbParcelInfo.fromMap(body)
        );
      }
      return (
        ok: false,
        message: data['msg']?.toString() ?? '获取订单详情失败',
        parcel: null
      );
    } catch (e) {
      return (ok: false, message: '网络请求异常: $e', parcel: null);
    }
  }

  /// 获取用户当前所有待取包裹
  Future<({bool ok, String message, List<JlbParcelInfo> list})>
      getUnpickupList({int pageIndex = 1, int pageSize = 50}) async {
    try {
      final resp = await _dio.get(
        '/order/unPickupList',
        queryParameters: {'pageIndex': pageIndex, 'pageSize': pageSize},
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      if (data['code'] == 0 && data['body'] is Map) {
        final body = Map<String, dynamic>.from(data['body'] as Map);
        final rawList = (body['list'] as List?) ?? [];
        final list = rawList
            .whereType<Map>()
            .map((e) => JlbParcelInfo.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return (ok: true, message: '获取成功', list: list);
      } else if (data['code'] == 6 || data['code'] == 20001) {
        return (ok: false, message: 'Session 已失效，请重新授权', list: <JlbParcelInfo>[]);
      }
      return (
        ok: false,
        message: data['msg']?.toString() ?? '获取列表失败',
        list: <JlbParcelInfo>[]
      );
    } catch (e) {
      return (ok: false, message: '网络请求异常: $e', list: <JlbParcelInfo>[]);
    }
  }

  /// 检查包裹超期费用 (单位: 分)
  Future<({bool ok, String message, int amountFen})> getCharge(
      String orderId) async {
    try {
      final resp = await _dio.get(
        '/order/getCharge',
        queryParameters: {'orderId': orderId},
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      if (data['code'] == 0) {
        final body = data['body'] is Map ? data['body'] as Map<String, dynamic> : {};
        final amount = (body['amount'] as num?)?.toInt() ?? 0;
        return (ok: true, message: '查询费用成功', amountFen: amount);
      }
      return (
        ok: false,
        message: data['msg']?.toString() ?? '费用检查失败',
        amountFen: 0
      );
    } catch (e) {
      return (ok: false, message: '网络请求异常: $e', amountFen: 0);
    }
  }

  /// 发送一键开箱指令
  Future<({bool ok, String message})> cabPickupQuick(
      String orderId, [String stationId = '']) async {
    try {
      final params = <String, dynamic>{'orderId': orderId};
      if (stationId.isNotEmpty) {
        params['stationId'] = stationId;
      }
      final resp = await _dio.get(
        '/order/cabPickupQuick',
        queryParameters: params,
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      final code = data['code'];
      if (code == 0) {
        return (ok: true, message: '开箱指令已发送，正在打开箱门...');
      } else if (code == 40000 ||
          code == 40001 ||
          code == 40002 ||
          code == 40003) {
        return (ok: false, message: '柜体网络断开或离线，无法开箱');
      }
      return (ok: false, message: data['msg']?.toString() ?? '开箱失败 (code=$code)');
    } catch (e) {
      return (ok: false, message: '网络请求异常: $e');
    }
  }

  /// 检查箱门是否已经打开
  Future<({bool isOpened, String message})> cabPickupCheck(
      String orderId) async {
    try {
      final resp = await _dio.get(
        '/order/cabPickupCheck',
        queryParameters: {'orderId': orderId},
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      if (data['code'] == 0 && data['body'] is Map) {
        final body = data['body'] as Map<String, dynamic>;
        final isPickup = body['is_pickup'] == true;
        return (
          isOpened: isPickup,
          message: isPickup ? '箱门已打开' : '箱门开启中...'
        );
      }
      return (isOpened: false, message: data['msg']?.toString() ?? '状态检查失败');
    } catch (e) {
      return (isOpened: false, message: '网络请求异常: $e');
    }
  }

  /// 再次开箱 / 重开箱门
  Future<({bool ok, String message})> cabPickupReopen(String orderId) async {
    try {
      final resp = await _dio.get(
        '/order/cabPickupReopen',
        queryParameters: {'orderId': orderId},
        options: Options(headers: _getHeaders()),
      );
      final data = resp.data is Map ? resp.data as Map<String, dynamic> : {};
      if (data['code'] == 0) {
        return (ok: true, message: '重开箱门指令已发送');
      }
      return (ok: false, message: data['msg']?.toString() ?? '重开箱门失败');
    } catch (e) {
      return (ok: false, message: '网络请求异常: $e');
    }
  }
}
