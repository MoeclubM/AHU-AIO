import 'package:flutter/services.dart';

/// 微信客户端唤起服务（原生通道封装）
class WeChatLauncher {
  static const MethodChannel _channel =
      MethodChannel('com.example.ahu_aio/wechat_launcher');

  /// 检查当前设备是否安装了微信
  static Future<bool> isInstalled() async {
    try {
      final bool? installed =
          await _channel.invokeMethod<bool>('isWeChatInstalled');
      return installed ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 唤醒微信主程序
  static Future<bool> launch() async {
    try {
      final bool? success =
          await _channel.invokeMethod<bool>('launchWeChat');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
