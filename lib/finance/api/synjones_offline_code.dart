import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class SynjonesOfflineCode {
  SynjonesOfflineCode._();

  static String build({
    required String barcode,
    required Map<String, dynamic> payment,
    required Map<String, dynamic> offlineParams,
    required String privateKey,
  }) {
    final offlineUserData = offlineParams['offline_userdata'].toString();
    final userHashKey = _decryptUserHashKey(
      offlineParams['userhashkey'].toString(),
      privateKey,
    );
    final payaccTlv = _payaccTlv(payment['payacc'].toString(), '01');
    final version = int.parse(offlineParams['version'].toString());
    final effectiveTime = int.parse(
      offlineParams['offline_effective_time'].toString(),
    );
    final payloadLength =
        13 + ((offlineUserData.length + payaccTlv.length) ~/ 2) + 1;

    final header = List<int>.filled(33, 0);
    for (var i = 0; i < barcode.length; i++) {
      header[i] = barcode.codeUnitAt(i);
    }
    header[20] = 83;
    header[21] = 80;
    header[22] = payloadLength ~/ 256;
    header[23] = payloadLength % 256;
    header[24] = version;
    header[25] = 0;
    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    header[26] = seconds & 255;
    header[27] = (seconds >> 8) & 255;
    header[28] = (seconds >> 16) & 255;
    header[29] = (seconds >> 24) & 255;
    header[30] = 1;
    header[31] = effectiveTime;
    header[32] = 1;

    final headerTail = _hex(header).substring(48);
    final payaccTlvLength = _hexLength(payaccTlv);
    final digest = sha1
        .convert(
          utf8.encode(
            '$headerTail$offlineUserData$payaccTlvLength$payaccTlv$userHashKey',
          ),
        )
        .toString()
        .substring(0, 8)
        .toUpperCase();
    final payload = _hexToBytes(
      '$offlineUserData$payaccTlvLength$payaccTlv$digest',
    );
    final bytes = Uint8List.fromList([...header, ...payload]);
    return '${barcode}SP${base64Encode(bytes.sublist(22))}';
  }

  static String _decryptUserHashKey(String value, String privateKey) {
    final cipher = PKCS1Encoding(RSAEngine())
      ..init(
        false,
        PrivateKeyParameter<RSAPrivateKey>(_parsePrivateKey(privateKey)),
      );
    final decrypted = cipher.process(_hexToBytes(value));
    return ascii.decode(decrypted.sublist(0, 32));
  }

  static RSAPrivateKey _parsePrivateKey(String pem) {
    final normalized = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s+'), '');
    final topLevel =
        ASN1Parser(base64Decode(normalized)).nextObject() as ASN1Sequence;
    final privateKey = topLevel.elements[2];
    final rsa =
        ASN1Parser(privateKey.contentBytes()).nextObject() as ASN1Sequence;
    final modulus = rsa.elements[1] as ASN1Integer;
    final privateExponent = rsa.elements[3] as ASN1Integer;
    final p = rsa.elements[4] as ASN1Integer;
    final q = rsa.elements[5] as ASN1Integer;
    return RSAPrivateKey(
      modulus.valueAsBigInteger,
      privateExponent.valueAsBigInteger,
      p.valueAsBigInteger,
      q.valueAsBigInteger,
    );
  }

  static String _payaccTlv(String payacc, String pid) {
    var payaccHex = '';
    for (var i = 0; i < payacc.length; i++) {
      payaccHex += payacc.codeUnitAt(i).toRadixString(16).toUpperCase();
    }
    payaccHex = _even(payaccHex);
    final payaccField = '84${_hexLength(payaccHex)}$payaccHex';
    final pidHex = _even(pid.toUpperCase());
    final pidField = '85${_hexLength(pidHex)}$pidHex';
    final body = '$payaccField$pidField';
    return '6F${_hexLength(body)}$body';
  }

  static String _hexLength(String hex) {
    return _even((hex.length ~/ 2).toRadixString(16).toUpperCase());
  }

  static String _even(String value) {
    return value.length.isOdd ? '0$value' : value;
  }

  static String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }

  static Uint8List _hexToBytes(String value) {
    final bytes = Uint8List(value.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(value.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
