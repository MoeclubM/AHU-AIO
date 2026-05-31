import 'dart:io' as io;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../api/jw_api.dart';

/// 将 Dio 会话 Cookie 同步到 InAppWebView，供教务网页版功能使用。
class JwWebViewAuth {
  JwWebViewAuth._();

  /// 把 [targetUrl] 所需 Cookie 写入 WebView。
  static Future<void> syncCookies(String targetUrl) async {
    final api = JwApi();
    await api.init();

    final targetUri = Uri.parse(targetUrl);
    final requestUris = <Uri>{
      Uri.parse(JwApi.baseUrl),
      Uri.parse('${JwApi.baseUrl}/'),
      Uri.parse('${JwApi.baseUrl}/student'),
      Uri.parse('${JwApi.baseUrl}/student/'),
      targetUri,
    };

    final merged = <String, io.Cookie>{};
    for (final uri in requestUris) {
      final cookies = await api.cookieJar.loadForRequest(uri);
      for (final cookie in cookies) {
        merged['${cookie.name}@${cookie.path ?? '/'}'] = cookie;
      }
    }

    if (merged.isEmpty) return;

    final cookieManager = CookieManager.instance();

    for (final cookie in merged.values) {
      final paths = <String>{cookie.path ?? '/', '/'};
      if ((cookie.path ?? '/').startsWith('/student')) {
        paths.add('/student');
        paths.add('/student/');
      }

      for (final path in paths) {
        await cookieManager.setCookie(
          url: WebUri('${JwApi.baseUrl}$path'),
          name: cookie.name,
          value: cookie.value,
          domain: 'jw.ahu.edu.cn',
          path: path,
          isSecure: true,
          isHttpOnly: cookie.httpOnly,
        );
      }
    }
  }

  /// 是否跳转到登录页（会话失效）。
  static bool isLoginRedirect(String? currentUrl, String originalUrl) {
    final url = currentUrl ?? '';
    if (!url.contains('/login')) return false;
    return !originalUrl.contains('/login');
  }

  /// 把原版 CAS Web 登录后的 WebView Cookie 写回 Dio，会话供原生接口复用。
  static Future<void> importCookiesFromWebView() async {
    final api = JwApi();
    await api.init();

    final cookieManager = CookieManager.instance();
    final targetUris = [
      Uri.parse(JwApi.baseUrl),
      Uri.parse('${JwApi.baseUrl}/student'),
      Uri.parse('${JwApi.baseUrl}/student/'),
    ];
    for (final uri in targetUris) {
      final cookies = await cookieManager.getCookies(
        url: WebUri(uri.toString()),
      );
      final converted = cookies.map((cookie) {
        final c = io.Cookie(cookie.name, cookie.value.toString());
        c.domain = cookie.domain ?? uri.host;
        c.path = cookie.path ?? '/';
        c.secure = cookie.isSecure ?? uri.scheme == 'https';
        c.httpOnly = cookie.isHttpOnly ?? false;
        if (cookie.expiresDate != null) {
          c.expires = DateTime.fromMillisecondsSinceEpoch(cookie.expiresDate!);
        }
        return c;
      }).toList();
      await api.cookieJar.saveFromResponse(uri, converted);
    }
  }
}
