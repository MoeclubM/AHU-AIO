import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bloom stroke shader produces visible pixels', () async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/bloom_stroke.frag',
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400.0, 200.0);

    final shader = program.fragmentShader();
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, 16.0)
      ..setFloat(3, 2.0)
      ..setFloat(4, 6.0)
      ..setFloat(5, 1.0)
      ..setFloat(6, 0.0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);

    final image = await recorder.endRecording().toImage(400, 200);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final data = bytes.buffer.asUint8List();
    var visible = 0;
    for (var i = 0; i < data.length; i += 4) {
      if (data[i + 3] > 0) visible++;
    }
    debugPrint('visible(alpha>0) pixels=$visible total=${data.length ~/ 4}');
    expect(
      visible,
      greaterThan(0),
      reason: 'shader should draw visible highlight',
    );
  });
}
