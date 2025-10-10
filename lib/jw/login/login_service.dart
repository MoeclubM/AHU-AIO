import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

class LoginService {
  // 公钥
  static const String _publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCFY5N+9UX+0BF+xz1svFguI4CIDvmQTfINkOZ1HOO3ltBNHGQTUirUPQTyEph/+q/l8b16YYw3I2fyTH6y15s3tHf5jMei+R/20jFRGo5udwVJUwq/RozKQIRzCtPYkXG4YWBnHKhXalZ5K2fhd5i/QtB016nVugH/7eiBDWbKVwIDAQAB
-----END PUBLIC KEY-----
''';

  static Future<String?> login({
    required String username,
    required String password,
  }) async {
    try {
      final String encryptedPassword =
          _encryptWithPublicKey(password, _publicKeyPem);

      // 拼接 URL 查询参数
      final Uri url =
          Uri.parse('https://jwapp.ahu.edu.cn/token/password/passwordLogin')
              .replace(queryParameters: {
        'username': username,
        'password': encryptedPassword,
        'appId': 'DEVICE_ID',
        'deviceId': 'DEVICE_ID',
        'osType': 'web',
        'geo': '',
      });

      final Map<String, String> headers = {
        'accept': 'application/json',
        'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'cache-control': 'no-cache',
        'content-type': 'application/x-www-form-urlencoded',
        'origin': 'https://jwapp.ahu.edu.cn',
        'referer': 'https://jwapp.ahu.edu.cn/uniapp/',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
        'sec-ch-ua': '"Chromium";v="140", "Not=A?Brand";v="24", "Google Chrome";v="140"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
      };

      final response = await http.post(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['code'] == 0) {
          return responseData['data']['idToken'];
        } else {
          throw Exception('登录失败，错误代码：${responseData['code']}，消息：${responseData['msg'] ?? '未知错误'}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('登录失败，错误信息：用户名或密码错误');
      } else {
        throw Exception('服务器错误，状态码：${response.statusCode}');
      }
    } catch (e) {
      throw Exception('登录失败，错误信息：$e');
    }
  }

  // 使用公钥加密数据，采用 PKCS#1 填充
  static String _encryptWithPublicKey(String data, String publicKeyPem) {
    final RSAPublicKey publicKey = _parsePublicKeyFromPem(publicKeyPem);

    // 使用 PKCS#1 填充加密
    final AsymmetricBlockCipher cipher = RSAEngine();
    final PKCS1Encoding pkcs1 = PKCS1Encoding(cipher);
    pkcs1.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    // 加密数据
    final Uint8List encryptedData =
        pkcs1.process(Uint8List.fromList(utf8.encode(data)));

    // 返回 Base64 编码后的加密数据
    return base64Encode(encryptedData);
  }

  // 解析 PEM 格式公钥
  static RSAPublicKey _parsePublicKeyFromPem(String pem) {
    final lines = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .trim();

    final asn1Parser = ASN1Parser(base64Decode(lines));
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
    final publicKeyAsn1Parser = ASN1Parser(publicKeyBitString.contentBytes());
    final publicKeySeq = publicKeyAsn1Parser.nextObject() as ASN1Sequence;

    final modulus = publicKeySeq.elements[0] as ASN1Integer;
    final exponent = publicKeySeq.elements[1] as ASN1Integer;

    return RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
  }
}
