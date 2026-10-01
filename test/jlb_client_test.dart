import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/jlb/models/jlb_models.dart';
import 'package:ahu_aio/jlb/api/jlb_client.dart';

void main() {
  group('近邻宝数据模型与业务逻辑测试', () {
    test('JlbParcelInfo 格式化与智能快递柜判断', () {
      final rawLockerData = {
        'orderId': '10023456',
        'stationId': '1052',
        'expCode': '78873766620581',
        'expressName': '中通快递',
        'cabCode': '100582',
        'cellCodeDesc': '12',
        'openCode': '35891204',
        'storageType': 3,
        'addr': '安大磬苑校区橘园食堂西侧3号柜',
        'status': 2,
        'createTime': '2026-09-24 10:30:00',
      };

      final parcel = JlbParcelInfo.fromMap(rawLockerData);

      expect(parcel.orderId, '10023456');
      expect(parcel.stationId, '1052');
      expect(parcel.expCode, '78873766620581');
      expect(parcel.expressName, '中通快递');
      expect(parcel.cabCode, '100582');
      expect(parcel.cellDesc, '12 格口');
      expect(parcel.pickupCode, '3589 1204');
      expect(parcel.isSmartLocker, isTrue);
      expect(parcel.isUnpicked, isTrue);
      expect(parcel.canOpenBox, isTrue);
      expect(parcel.storageTypeName, '智能快递柜');
      expect(parcel.statusName, '待取件');
    });

    test('JlbParcelInfo 人工台/普通货架包裹不可开箱判断', () {
      final rawStationData = {
        'orderId': '10099887',
        'expCode': 'SF123456789',
        'expressName': '顺丰速运',
        'storageType': 1,
        'addr': '橘园快递服务台',
        'status': 2,
      };

      final parcel = JlbParcelInfo.fromMap(rawStationData);

      expect(parcel.isSmartLocker, isFalse);
      expect(parcel.canOpenBox, isFalse);
      expect(parcel.storageTypeName, '服务台/驿站人工');
    });

    test('JlbParcelInfo 已取件状态判断', () {
      final rawPickedData = {
        'orderId': '10099888',
        'cabCode': '100582',
        'cellDesc': '05',
        'storageType': 3,
        'status': 3,
      };

      final parcel = JlbParcelInfo.fromMap(rawPickedData);

      expect(parcel.isSmartLocker, isTrue);
      expect(parcel.isUnpicked, isFalse);
      expect(parcel.canOpenBox, isFalse);
      expect(parcel.statusName, '用户已取走');
    });

    test('JlbUserInfo 模型解析', () {
      final rawUserData = {
        'phone': '13812345678',
        'userName': '张同学',
      };

      final user = JlbUserInfo.fromMap(
        rawUserData,
        simpleCode: '8899',
        fullCode: 'JLB8899',
      );

      expect(user.phone, '13812345678');
      expect(user.userName, '张同学');
      expect(user.simpleCode, '8899');
      expect(user.fullCode, 'JLB8899');
    });

    test('JlbClient 默认配置测试', () {
      final client = JlbClient(sessionId: 'test_session');
      expect(client.sessionId, 'test_session');
      expect(JlbClient.baseUrl, 'https://yz-api.jinlb.cn/openapi/miniapp/user');
    });

    test('离线扫码协议解析测试 (jlb://auth 及纯文本)', () {
      String? extractSession(String text) {
        final clean = text.trim();
        if (clean.isEmpty) return null;
        if (clean.startsWith('jlb://')) {
          final uri = Uri.tryParse(clean);
          if (uri != null) {
            final sid = uri.queryParameters['session'] ??
                uri.queryParameters['sessionId'] ??
                uri.queryParameters['sid'];
            if (sid != null && sid.isNotEmpty) return sid.trim();
          }
        }
        if (clean.contains('sessionId') || clean.contains('session_id')) {
          final match = RegExp(r'(?:sessionId|session_id)[:=]\s*([a-zA-Z0-9_-]+)')
              .firstMatch(clean);
          if (match != null) {
            return match.group(1);
          }
        }
        if (clean.length >= 24 &&
            clean.length <= 64 &&
            !clean.contains(' ') &&
            !clean.contains('http') &&
            RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clean)) {
          return clean;
        }
        return null;
      }

      // 测试 1: jlb://auth?session=xxxx
      expect(
        extractSession('jlb://auth?session=c627abcde1234567890abcdef1234567'),
        'c627abcde1234567890abcdef1234567',
      );

      // 测试 2: sessionId: xxxx
      expect(
        extractSession('sessionId: c627abcde1234567890abcdef1234567'),
        'c627abcde1234567890abcdef1234567',
      );

      // 测试 3: 纯 32 位 Session 字符串
      expect(
        extractSession('c627abcde1234567890abcdef1234567'),
        'c627abcde1234567890abcdef1234567',
      );

      // 测试 4: 无关普通文本
      expect(extractSession('https://www.baidu.com'), isNull);
      expect(extractSession('hello world'), isNull);
    });
  });
}
