import 'package:flutter/material.dart';

/// 原生 Code128-B 条形码绘制器，用于一卡通付款码/身份码展示。
class Code128Barcode extends StatelessWidget {
  final String data;
  final double height;

  const Code128Barcode({super.key, required this.data, this.height = 96});

  @override
  Widget build(BuildContext context) {
    if (!_Code128Painter.canEncode(data)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '当前码值包含 Code128-B 不支持的字符，请复制码值或刷新后重试。',
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CustomPaint(painter: _Code128Painter(data)),
    );
  }
}

class _Code128Painter extends CustomPainter {
  final String data;

  _Code128Painter(this.data);

  static bool canEncode(String value) {
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 32 || code > 127) return false;
    }
    return value.isNotEmpty;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final codes = <int>[104];
    for (var i = 0; i < data.length; i++) {
      codes.add(data.codeUnitAt(i) - 32);
    }
    var checksum = 104;
    for (var i = 1; i < codes.length; i++) {
      checksum += codes[i] * i;
    }
    codes
      ..add(checksum % 103)
      ..add(106);

    final modules = StringBuffer();
    for (final code in codes) {
      modules.write(_patterns[code]);
    }

    final bits = modules.toString();
    final moduleWidth = size.width / (bits.length + 20);
    final paint = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    var x = moduleWidth * 10;
    for (var i = 0; i < bits.length; i++) {
      if (bits.codeUnitAt(i) == 49) {
        canvas.drawRect(Rect.fromLTWH(x, 0, moduleWidth, size.height), paint);
      }
      x += moduleWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _Code128Painter oldDelegate) {
    return oldDelegate.data != data;
  }
}

const _patterns = [
  '11011001100',
  '11001101100',
  '11001100110',
  '10010011000',
  '10010001100',
  '10001001100',
  '10011001000',
  '10011000100',
  '10001100100',
  '11001001000',
  '11001000100',
  '11000100100',
  '10110011100',
  '10011011100',
  '10011001110',
  '10111001100',
  '10011101100',
  '10011100110',
  '11001110010',
  '11001011100',
  '11001001110',
  '11011100100',
  '11001110100',
  '11101101110',
  '11101001100',
  '11100101100',
  '11100100110',
  '11101100100',
  '11100110100',
  '11100110010',
  '11011011000',
  '11011000110',
  '11000110110',
  '10100011000',
  '10001011000',
  '10001000110',
  '10110001000',
  '10001101000',
  '10001100010',
  '11010001000',
  '11000101000',
  '11000100010',
  '10110111000',
  '10110001110',
  '10001101110',
  '10111011000',
  '10111000110',
  '10001110110',
  '11101110110',
  '11010001110',
  '11000101110',
  '11011101000',
  '11011100010',
  '11011101110',
  '11101011000',
  '11101000110',
  '11100010110',
  '11101101000',
  '11101100010',
  '11100011010',
  '11101111010',
  '11001000010',
  '11110001010',
  '10100110000',
  '10100001100',
  '10010110000',
  '10010000110',
  '10000101100',
  '10000100110',
  '10110010000',
  '10110000100',
  '10011010000',
  '10011000010',
  '10000110100',
  '10000110010',
  '11000010010',
  '11001010000',
  '11110111010',
  '11000010100',
  '10001111010',
  '10100111100',
  '10010111100',
  '10010011110',
  '10111100100',
  '10011110100',
  '10011110010',
  '11110100100',
  '11110010100',
  '11110010010',
  '11011011110',
  '11011110110',
  '11110110110',
  '10101111000',
  '10100011110',
  '10001011110',
  '10111101000',
  '10111100010',
  '11110101000',
  '11110100010',
  '10111011110',
  '10111101110',
  '11101011110',
  '11110101110',
  '11010000100',
  '11010010000',
  '11010011100',
  '1100011101011',
];
