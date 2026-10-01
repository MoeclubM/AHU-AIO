/// 近邻宝包裹与柜体信息模型
class JlbParcelInfo {
  final String orderId;
  final String stationId;
  final String expCode;
  final String expressName;
  final String cabCode;
  final String cellDesc;
  final String pickupCode;
  final int storageType;
  final String storageTypeName;
  final String addr;
  final int status;
  final String statusName;
  final String createTime;
  final Map<String, dynamic> raw;

  const JlbParcelInfo({
    required this.orderId,
    required this.stationId,
    required this.expCode,
    required this.expressName,
    required this.cabCode,
    required this.cellDesc,
    required this.pickupCode,
    required this.storageType,
    required this.storageTypeName,
    required this.addr,
    required this.status,
    required this.statusName,
    required this.createTime,
    required this.raw,
  });

  /// 是否为智能快递柜
  bool get isSmartLocker => storageType == 3 || storageType == 4;

  /// 是否处于待取件状态
  bool get isUnpicked => status == 2;

  /// 是否支持在线下发一键开箱指令
  bool get canOpenBox => orderId.isNotEmpty && isSmartLocker && isUnpicked;

  static const Map<int, String> _storageTypeMap = {
    1: '服务台/驿站人工',
    2: '驿站普通货架',
    3: '智能快递柜',
    4: '寄存柜/储物柜',
    6: '驿站暂存区',
    7: '智能亮灯货架',
  };

  static const Map<int, String> _statusMap = {
    2: '待取件',
    3: '用户已取走',
    4: '已退回快递公司',
    6: '包裹状态异常',
    7: '包裹状态异常',
    9: '快递员已取回',
  };

  factory JlbParcelInfo.fromMap(Map<String, dynamic> map) {
    final storageType = (map['storageType'] as num?)?.toInt() ?? 0;
    final storageTypeName =
        _storageTypeMap[storageType] ?? '类型($storageType)';

    final statusCode = (map['status'] as num?)?.toInt() ?? 0;
    final statusName = _statusMap[statusCode] ?? '状态($statusCode)';

    final rawCab = (map['cabCode'] ??
            map['cabinetCode'] ??
            map['cabinet_code'] ??
            '')
        .toString()
        .trim();
    final cabCode = rawCab.isEmpty ? '无柜号' : rawCab;

    final rawCell = (map['cellCodeDesc'] ??
            map['cellDesc'] ??
            map['cellCode'] ??
            '')
        .toString()
        .trim();
    String cellDesc = rawCell.isEmpty ? '无格口号' : rawCell;
    if (cellDesc != '无格口号' && !cellDesc.endsWith('格口')) {
      cellDesc = '$cellDesc 格口';
    }

    final rawPickup =
        (map['pickupCode'] ?? map['openCode'] ?? '').toString().trim();
    String pickupCode = rawPickup;
    if (rawPickup.length == 8 && (storageType == 3 || storageType == 4)) {
      pickupCode = '${rawPickup.substring(0, 4)} ${rawPickup.substring(4)}';
    }

    final addr = (map['addr'] ??
            map['address'] ??
            map['stationName'] ??
            '未知位置')
        .toString()
        .trim();

    final expressName =
        (map['expressName'] ?? '快递包裹').toString().trim();
    final expCode = (map['expCode'] ?? '').toString().trim();

    String createTime = (map['createTime'] ?? '').toString().trim();
    if (createTime.isEmpty && map['operLogInfo'] is List) {
      final logs = map['operLogInfo'] as List;
      if (logs.isNotEmpty && logs.last is Map) {
        createTime = (logs.last['createTime'] ?? '').toString().trim();
      }
    }

    final orderId = (map['orderId'] ?? map['id'] ?? '').toString().trim();
    final stationId = (map['stationId'] ?? '').toString().trim();

    return JlbParcelInfo(
      orderId: orderId,
      stationId: stationId,
      expCode: expCode,
      expressName: expressName,
      cabCode: cabCode,
      cellDesc: cellDesc,
      pickupCode: pickupCode,
      storageType: storageType,
      storageTypeName: storageTypeName,
      addr: addr,
      status: statusCode,
      statusName: statusName,
      createTime: createTime,
      raw: map,
    );
  }
}

/// 近邻宝用户信息模型
class JlbUserInfo {
  final String phone;
  final String userName;
  final String simpleCode;
  final String fullCode;

  const JlbUserInfo({
    required this.phone,
    required this.userName,
    this.simpleCode = '',
    this.fullCode = '',
  });

  factory JlbUserInfo.fromMap(Map<String, dynamic> map,
      {String simpleCode = '', String fullCode = ''}) {
    return JlbUserInfo(
      phone: (map['phone'] ?? '').toString().trim(),
      userName: (map['userName'] ?? map['nickName'] ?? '近邻宝用户')
          .toString()
          .trim(),
      simpleCode: simpleCode,
      fullCode: fullCode,
    );
  }
}
