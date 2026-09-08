import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:ahu_aio/auth/cas_native_client.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('CasNativeClient login behavior', () {
    test(
      'login clears existing CAS session cookie before authentication',
      () async {
        final cookieJar = CookieJar();
        final casUri = Uri.parse('https://one.ahu.edu.cn/cas/login');

        // Pre-populate cookieJar with a CAS session cookie (CASTGC)
        await cookieJar.saveFromResponse(casUri, [
          Cookie('CASTGC', 'mock_tgt_token_123456')
            ..domain = 'one.ahu.edu.cn'
            ..path = '/cas',
        ]);

        // Verify cookie exists before login
        final cookiesBefore = await cookieJar.loadForRequest(casUri);
        expect(cookiesBefore.any((c) => c.name == 'CASTGC'), isTrue);

        final client = CasNativeClient(cookieJar: cookieJar);

        // Calling login with credentials should clear the CAS cookies and attempt real login,
        // NOT short-circuit with cached session.
        expect(
          () async => await client.login(
            loginUri: casUri,
            username: 'test_user',
            password: 'test_password',
            trustDevice: true,
          ),
          throwsA(anything),
        );

        // Also verify that the old CASTGC cookie was deleted
        final cookiesAfter = await cookieJar.loadForRequest(casUri);
        expect(cookiesAfter.any((c) => c.name == 'CASTGC'), isFalse);
      },
    );

    test(
      'login throws error when password is wrong, never falsely succeeds',
      () async {
        final dio = Dio();
        final cookieJar = CookieJar();

        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          final uri = options.uri;
          if (uri.path == '/cas/login') {
            // Return CAS login page with lt and execution fields
            const html = '''
            <html>
              <body>
                <input type="hidden" name="lt" value="LT-mock-123456" />
                <input type="hidden" name="execution" value="e1s1" />
              </body>
            </html>
          ''';
            return ResponseBody.fromString(
              html,
              200,
              headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8'],
              },
            );
          } else if (uri.path == '/cas/device') {
            // Return wrong password error from device check
            return ResponseBody.fromString(
              jsonEncode({'info': 'err'}),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          return ResponseBody.fromString('Not found', 404);
        });

        final client = CasNativeClient(cookieJar: cookieJar, dio: dio);

        expect(
          () async => await client.login(
            loginUri: Uri.parse(
              'https://one.ahu.edu.cn/cas/login?service=https%3A%2F%2Fjw.ahu.edu.cn%2Fstudent%2Fsso%2Flogin',
            ),
            username: '20230001',
            password: 'wrong_password',
            trustDevice: true,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('CAS 用户名或密码错误'),
            ),
          ),
        );
      },
    );

    test('login succeeds when password is correct and follows redirects', () async {
      final dio = Dio();
      final cookieJar = CookieJar();

      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        final uri = options.uri;
        if (options.method == 'GET' && uri.path == '/cas/login') {
          const html = '''
            <html>
              <body>
                <input type="hidden" name="lt" value="LT-mock-123456" />
                <input type="hidden" name="execution" value="e1s1" />
              </body>
            </html>
          ''';
          return ResponseBody.fromString(
            html,
            200,
            headers: {
              Headers.contentTypeHeader: ['text/html; charset=utf-8'],
            },
          );
        } else if (options.method == 'POST' && uri.path == '/cas/device') {
          return ResponseBody.fromString(
            jsonEncode({'info': 'ok'}),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        } else if (options.method == 'POST' && uri.path == '/cas/login') {
          // Return redirect to service with ticket
          return ResponseBody.fromString(
            '',
            302,
            headers: {
              'location': [
                'https://jw.ahu.edu.cn/student/sso/login?ticket=ST-mock-ticket-123',
              ],
            },
          );
        } else if (options.method == 'GET' && uri.host == 'jw.ahu.edu.cn') {
          return ResponseBody.fromString(
            '<html>Welcome</html>',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/html; charset=utf-8'],
            },
          );
        }
        return ResponseBody.fromString('Not found', 404);
      });

      final client = CasNativeClient(cookieJar: cookieJar, dio: dio);

      final result = await client.login(
        loginUri: Uri.parse(
          'https://one.ahu.edu.cn/cas/login?service=https%3A%2F%2Fjw.ahu.edu.cn%2Fstudent%2Fsso%2Flogin',
        ),
        username: '20230001',
        password: 'correct_password',
        trustDevice: true,
      );

      expect(result.finalUri.host, 'jw.ahu.edu.cn');
      expect(
        result.observedUris.any(
          (u) => u.queryParameters['ticket'] == 'ST-mock-ticket-123',
        ),
        isTrue,
      );
    });
  });
}
