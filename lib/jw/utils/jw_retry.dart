import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// 通用重试工具
/// 对瞬时网络抖动（超时、连接失败、5xx）自动重试，
/// 认证类错误（401/302/HTML 登录页）不重试，交由 JwApi 拦截器处理
class JwRetry {
  static const int defaultMaxAttempts = 3;
  static const Duration defaultInitialDelay = Duration(milliseconds: 700);

  /// 带重试执行 [task]
  /// - [maxAttempts] 总尝试次数（含首次），默认 3
  /// - [initialDelay] 首次重试前等待，默认 700ms，后续指数退避 x1.9
  /// - [retryIf] 自定义是否重试
  static Future<T> withRetry<T>(
    Future<T> Function() task, {
    int maxAttempts = defaultMaxAttempts,
    Duration initialDelay = defaultInitialDelay,
    bool Function(Object error)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    Object? lastError;
    StackTrace? lastStack;
    while (attempt < maxAttempts) {
      try {
        return await task();
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        attempt++;
        final shouldRetry = retryIf != null
            ? retryIf(e)
            : _defaultShouldRetry(e);
        if (!shouldRetry || attempt >= maxAttempts) {
          Error.throwWithStackTrace(e, st);
        }
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.9).round());
      }
    }
    // 理论不可达
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStack ?? StackTrace.current);
    }
    throw StateError('withRetry: unreachable');
  }

  static bool _defaultShouldRetry(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      // 认证/重定向类不重试，让拦截器静默重登录
      if (code == 401 || code == 302 || code == 403) return false;
      // HTML 登录页也不重试
      final data = e.response?.data;
      if (data is String &&
          (data.contains('<!DOCTYPE html>') ||
              data.contains('<html>') ||
              data.contains('login'))) {
        return false;
      }
      // 超时、连接错误、5xx、未知网络异常均重试
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        return true;
      }
      if (code != null && code >= 500 && code < 600) return true;
      // 其他 4xx 不重试
      if (code != null && code >= 400 && code < 500) return false;
      return true;
    }
    if (e is SocketException ||
        e is HandshakeException ||
        e is TimeoutException) {
      return true;
    }
    // 解析异常等不重试
    return false;
  }
}

/// 便捷顶层函数
Future<T> jwRetry<T>(
  Future<T> Function() task, {
  int maxAttempts = JwRetry.defaultMaxAttempts,
  Duration initialDelay = JwRetry.defaultInitialDelay,
  bool Function(Object error)? retryIf,
}) =>
    JwRetry.withRetry(
      task,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      retryIf: retryIf,
    );
