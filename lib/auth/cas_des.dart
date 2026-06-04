class CasDes {
  CasDes._();

  static String encrypt(String data) {
    final firstKey = _getKeyBytes('1');
    final secondKey = _getKeyBytes('2');
    final thirdKey = _getKeyBytes('3');
    final buffer = StringBuffer();

    for (var offset = 0; offset < data.length; offset += 4) {
      var block = _strToBt(
        data.substring(
          offset,
          offset + 4 > data.length ? data.length : offset + 4,
        ),
      );
      for (final key in firstKey) {
        block = _enc(block, key);
      }
      for (final key in secondKey) {
        block = _enc(block, key);
      }
      for (final key in thirdKey) {
        block = _enc(block, key);
      }
      buffer.write(_bt64ToHex(block));
    }
    return buffer.toString();
  }

  static List<List<int>> _getKeyBytes(String key) {
    final bytes = <List<int>>[];
    for (var offset = 0; offset < key.length; offset += 4) {
      bytes.add(
        _strToBt(
          key.substring(
            offset,
            offset + 4 > key.length ? key.length : offset + 4,
          ),
        ),
      );
    }
    return bytes;
  }

  static List<int> _strToBt(String str) {
    final bits = List<int>.filled(64, 0);
    for (var i = 0; i < str.length && i < 4; i++) {
      final code = str.codeUnitAt(i);
      for (var j = 0; j < 16; j++) {
        bits[16 * i + j] = (code ~/ (1 << (15 - j))) % 2;
      }
    }
    return bits;
  }

  static String _bt64ToHex(List<int> byteData) {
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      final value =
          byteData[i * 4] * 8 +
          byteData[i * 4 + 1] * 4 +
          byteData[i * 4 + 2] * 2 +
          byteData[i * 4 + 3];
      buffer.write(value.toRadixString(16).toUpperCase());
    }
    return buffer.toString();
  }

  static List<int> _enc(List<int> dataByte, List<int> keyByte) {
    final keys = _generateKeys(keyByte);
    final ipByte = _initPermute(dataByte);
    final ipLeft = ipByte.sublist(0, 32);
    var ipRight = ipByte.sublist(32, 64);

    for (var i = 0; i < 16; i++) {
      final tempLeft = ipLeft.toList();
      for (var j = 0; j < 32; j++) {
        ipLeft[j] = ipRight[j];
      }
      ipRight = _xor(
        _pPermute(_sBoxPermute(_xor(_expandPermute(ipRight), keys[i]))),
        tempLeft,
      );
    }

    final finalData = <int>[...ipRight, ...ipLeft];
    return _finallyPermute(finalData);
  }

  static List<int> _initPermute(List<int> originalData) {
    final ipByte = List<int>.filled(64, 0);
    for (var i = 0, m = 1, n = 0; i < 4; i++, m += 2, n += 2) {
      for (var j = 7, k = 0; j >= 0; j--, k++) {
        ipByte[i * 8 + k] = originalData[j * 8 + m];
        ipByte[i * 8 + k + 32] = originalData[j * 8 + n];
      }
    }
    return ipByte;
  }

  static List<int> _expandPermute(List<int> rightData) {
    final epByte = List<int>.filled(48, 0);
    for (var i = 0; i < 8; i++) {
      epByte[i * 6] = i == 0 ? rightData[31] : rightData[i * 4 - 1];
      epByte[i * 6 + 1] = rightData[i * 4];
      epByte[i * 6 + 2] = rightData[i * 4 + 1];
      epByte[i * 6 + 3] = rightData[i * 4 + 2];
      epByte[i * 6 + 4] = rightData[i * 4 + 3];
      epByte[i * 6 + 5] = i == 7 ? rightData[0] : rightData[i * 4 + 4];
    }
    return epByte;
  }

  static List<int> _xor(List<int> one, List<int> two) {
    return List<int>.generate(one.length, (i) => one[i] ^ two[i]);
  }

  static List<int> _sBoxPermute(List<int> expandByte) {
    final sBoxByte = List<int>.filled(32, 0);
    for (var m = 0; m < 8; m++) {
      final i = expandByte[m * 6] * 2 + expandByte[m * 6 + 5];
      final j =
          expandByte[m * 6 + 1] * 8 +
          expandByte[m * 6 + 2] * 4 +
          expandByte[m * 6 + 3] * 2 +
          expandByte[m * 6 + 4];
      final value = _sBoxes[m][i][j];
      sBoxByte[m * 4] = (value >> 3) & 1;
      sBoxByte[m * 4 + 1] = (value >> 2) & 1;
      sBoxByte[m * 4 + 2] = (value >> 1) & 1;
      sBoxByte[m * 4 + 3] = value & 1;
    }
    return sBoxByte;
  }

  static List<int> _pPermute(List<int> sBoxByte) {
    return _pPermuteTable.map((index) => sBoxByte[index]).toList();
  }

  static List<int> _finallyPermute(List<int> endByte) {
    return _finallyPermuteTable.map((index) => endByte[index]).toList();
  }

  static List<List<int>> _generateKeys(List<int> keyByte) {
    final key = List<int>.filled(56, 0);
    final keys = List.generate(16, (_) => List<int>.filled(48, 0));
    const loop = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];

    for (var i = 0; i < 7; i++) {
      for (var j = 0, k = 7; j < 8; j++, k--) {
        key[i * 8 + j] = keyByte[8 * k + i];
      }
    }

    for (var i = 0; i < 16; i++) {
      for (var j = 0; j < loop[i]; j++) {
        final tempLeft = key[0];
        final tempRight = key[28];
        for (var k = 0; k < 27; k++) {
          key[k] = key[k + 1];
          key[28 + k] = key[29 + k];
        }
        key[27] = tempLeft;
        key[55] = tempRight;
      }
      for (var m = 0; m < 48; m++) {
        keys[i][m] = key[_keyPermuteTable[m]];
      }
    }
    return keys;
  }

  static const _pPermuteTable = [
    15,
    6,
    19,
    20,
    28,
    11,
    27,
    16,
    0,
    14,
    22,
    25,
    4,
    17,
    30,
    9,
    1,
    7,
    23,
    13,
    31,
    26,
    2,
    8,
    18,
    12,
    29,
    5,
    21,
    10,
    3,
    24,
  ];

  static const _finallyPermuteTable = [
    39,
    7,
    47,
    15,
    55,
    23,
    63,
    31,
    38,
    6,
    46,
    14,
    54,
    22,
    62,
    30,
    37,
    5,
    45,
    13,
    53,
    21,
    61,
    29,
    36,
    4,
    44,
    12,
    52,
    20,
    60,
    28,
    35,
    3,
    43,
    11,
    51,
    19,
    59,
    27,
    34,
    2,
    42,
    10,
    50,
    18,
    58,
    26,
    33,
    1,
    41,
    9,
    49,
    17,
    57,
    25,
    32,
    0,
    40,
    8,
    48,
    16,
    56,
    24,
  ];

  static const _keyPermuteTable = [
    13,
    16,
    10,
    23,
    0,
    4,
    2,
    27,
    14,
    5,
    20,
    9,
    22,
    18,
    11,
    3,
    25,
    7,
    15,
    6,
    26,
    19,
    12,
    1,
    40,
    51,
    30,
    36,
    46,
    54,
    29,
    39,
    50,
    44,
    32,
    47,
    43,
    48,
    38,
    55,
    33,
    52,
    45,
    41,
    49,
    35,
    28,
    31,
  ];

  static const _sBoxes = [
    [
      [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7],
      [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8],
      [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
      [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13],
    ],
    [
      [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10],
      [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5],
      [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15],
      [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9],
    ],
    [
      [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8],
      [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1],
      [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7],
      [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12],
    ],
    [
      [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15],
      [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9],
      [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4],
      [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14],
    ],
    [
      [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9],
      [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6],
      [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
      [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3],
    ],
    [
      [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11],
      [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8],
      [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6],
      [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13],
    ],
    [
      [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1],
      [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6],
      [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2],
      [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12],
    ],
    [
      [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7],
      [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
      [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
      [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11],
    ],
  ];
}
