import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ahu_aio/miuix/liquid_glass_layer.dart';

/// 液态玻璃着色器的回归测试。
///
/// 折射走 `ImageFilter.shader`（只有 Impeller 支持，测试环境是软件后端），
/// 因此这里验证的是**着色器本身**：能否编译、uniform 布局是否与 Dart 侧一致、
/// 以及边缘高光的 SDF 数学是否正确。
///
/// 高光用 `Paint.shader` 绘制，与后端无关，所以可以逐像素验证。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ui.Image> render(void Function(Canvas canvas) draw, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    draw(canvas);
    return recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
  }

  double luminance(Uint8List rgba, int width, int x, int y) {
    final int i = (y * width + x) * 4;
    return (0.2126 * rgba[i] + 0.7152 * rgba[i + 1] + 0.0722 * rgba[i + 2]) /
        255.0;
  }

  group('着色器可编译且 uniform 布局正确', () {
    test('折射 shader 能编译，且所有参数可按名字绑定', () async {
      final ui.FragmentProgram program =
          await loadLiquidGlassRefractionProgram();
      final ui.FragmentShader shader = program.fragmentShader();
      addTearDown(shader.dispose);

      // 按名字取槽位：名字写错会直接抛错，比魔数索引可靠。
      // u_size 由 ImageFilter.shader 的引擎侧写入，Dart 侧不设置。
      expect(
        () {
          shader.getUniformVec2('u_origin').set(48, 1800);
          shader.getUniformVec2('u_region_size').set(680, 300);
          shader.getUniformFloat('u_dpr').set(2.75);
          shader.getUniformVec4('u_radius').set(32, 32, 32, 32);
          shader.getUniformFloat('u_refraction_height').set(24);
          shader.getUniformFloat('u_refraction_amount').set(24);
          shader.getUniformFloat('u_depth_effect').set(0);
          shader.getUniformFloat('u_dispersion').set(0.5);
        },
        returnsNormally,
        reason: 'shader 里的 uniform 名字必须与 Dart 侧一致',
      );
    });

    test('高光 shader 能编译，且所有参数可按名字绑定', () async {
      await preloadLiquidGlassShaders();
      final ui.FragmentProgram? program = liquidGlassHighlightProgram;
      expect(program, isNotNull, reason: '高光 shader 应能加载');
      final ui.FragmentShader shader = program!.fragmentShader();
      addTearDown(shader.dispose);
      expect(() {
        shader.getUniformVec2('u_size').set(200, 64);
        shader.getUniformFloat('u_pad').set(0);
        shader.getUniformFloat('u_radius').set(32);
        shader.getUniformFloat('u_angle').set(0.785);
        shader.getUniformFloat('u_falloff').set(1);
        shader.getUniformVec4('u_color').set(1, 1, 1, 1);
      }, returnsNormally);
    });

    test('折射 shader 声明了采样器（ImageFilter.shader 的硬性要求）', () async {
      final ui.FragmentProgram program =
          await loadLiquidGlassRefractionProgram();
      // 能取到采样器槽位即说明声明存在；ImageFilter.shader 缺采样器会抛错。
      expect(program.fragmentShader(), isNotNull);
    });
  });

  group('折射区域的屏幕空间几何', () {
    testWidgets('区域原点取屏幕绝对位置（设备像素），而不是局部坐标', (tester) async {
      const double dpr = 2.5;
      const double pad = 24;
      // 把玻璃层放在一个已知的屏幕位置：左侧 40、顶部 100（逻辑像素）。
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: dpr),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                Positioned(
                  left: 40,
                  top: 100,
                  width: 300,
                  height: 64,
                  child: Builder(
                    builder: (context) => SizedBox.expand(
                      child: LiquidGlassLayer(
                        cornerRadius: 32,
                        padding: pad,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final RenderBox box =
          tester.renderObject(find.byType(LiquidGlassLayer)) as RenderBox;
      final Offset origin = liquidGlassRegionOrigin(box, pad: pad, dpr: dpr);

      // 区域 = 形状左上角往左上各偏 pad，再换算成设备像素。
      expect(origin.dx, closeTo((40 - pad) * dpr, 0.01));
      expect(origin.dy, closeTo((100 - pad) * dpr, 0.01));
      // 关键：不是 (0,0) 或局部坐标——那正是导致形状画到屏幕中央的错误。
      expect(origin.dx, isNot(closeTo(0, 0.01)));
      expect(origin, isNot(const Offset(0, 0)));
    });

    testWidgets('Transform.scale 下 pad 也跟着缩放，不得再全局减 pad', (
      tester,
    ) async {
      const double dpr = 1.0;
      const double pad = 24;
      const double scale = 1.25;
      // 布局盒 200×64，放在 (100, 200)，再整体放大 1.25（中心缩放）。
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: dpr),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 200,
                  width: 200,
                  height: 64,
                  child: Transform.scale(
                    scale: scale,
                    child: const _OriginProbe(pad: pad),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final RenderBox box = tester.renderObject(
        find.byType(_OriginProbe),
      ) as RenderBox;
      final Offset origin = liquidGlassRegionOrigin(box, pad: pad, dpr: dpr);

      // 正确值：把 (-pad,-pad) 变换到屏幕。中心缩放时不能用
      // localToGlobal(0) - pad（那是未缩放的 pad，会偏 24*(1.25-1)=6）。
      final Offset expected = box.localToGlobal(const Offset(-pad, -pad)) * dpr;
      expect(origin.dx, closeTo(expected.dx, 0.01));
      expect(origin.dy, closeTo(expected.dy, 0.01));

      // 与错误公式区分：全局减 pad 在 scale≠1 时会偏。
      final Offset wrong =
          (box.localToGlobal(Offset.zero) - const Offset(pad, pad)) * dpr;
      expect(
        (origin - wrong).distance,
        greaterThan(0.5),
        reason: 'scale≠1 时两种公式必须可区分，否则测不到错位回归',
      );

      final geo = liquidGlassRegionGeometry(box, pad: pad, dpr: dpr);
      expect(geo.visualScale, closeTo(scale, 0.02));
    });

    testWidgets('非 Impeller 平台不做折射，退化为纯模糊', (tester) async {
      // 测试环境是软件后端，ImageFilter.shader 不可用。
      expect(LiquidGlassLayer.isRefractionSupported, isFalse);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 64,
              child: LiquidGlassLayer(
                cornerRadius: 32,
                blurSigma: 4,
                refractionHeight: 24,
                refractionAmount: 24,
                padding: 24,
                child: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 只能有模糊滤镜，绝不能挂上 shader（不支持时会直接抛错）。
      final BackdropFilter backdrop = tester.widget<BackdropFilter>(
        find.byType(BackdropFilter),
      );
      expect(backdrop.filter.toString(), contains('blur'));
      expect(backdrop.filter.toString(), isNot(contains('shader')));
    });
  });

  group('边缘高光', () {
    /// 直接调用生产代码的高光绘制函数，避免测试与实现各写一份。
    Future<ui.Image> renderHighlight({
      required Size size,
      required double radius,
      required double width,
      required Color color,
      double falloff = 1,
    }) async {
      await preloadLiquidGlassShaders();
      return render((canvas) {
        canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
        paintLiquidGlassHighlight(
          canvas,
          size,
          radius: radius,
          width: width,
          angleDegrees: 45,
          falloff: falloff,
          color: color,
        );
      }, size);
    }

    test('高光只出现在边缘：边缘比中心亮', () async {
      const Size size = Size(200, 64);
      final ui.Image image = await renderHighlight(
        size: size,
        radius: 32,
        width: 1.5,
        color: const Color(0xFFFFFFFF),
      );
      final ByteData data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final Uint8List rgba = data.buffer.asUint8List();
      final int w = image.width;
      image.dispose();

      // 顶部边缘（胶囊中段的正上方）对比正中心。
      final double edge = luminance(rgba, w, 100, 1);
      final double center = luminance(rgba, w, 100, 32);
      debugPrint('高光：边缘=$edge 中心=$center');

      expect(edge, greaterThan(center + 0.05), reason: '高光应该是贴边的一圈细线');
      expect(edge, greaterThan(0.01), reason: '边缘必须真的有高光');
    });

    test('falloff 控制高光的衰减强度', () async {
      const Size size = Size(200, 64);
      Future<double> rimPeak(double falloff) async {
        final ui.Image image = await renderHighlight(
          size: size,
          radius: 32,
          width: 2,
          color: const Color(0xFFFFFFFF),
          falloff: falloff,
        );
        final ByteData data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final Uint8List rgba = data.buffer.asUint8List();
        final int w = image.width;
        image.dispose();
        // 沿顶部边缘中段取一条竖线，取峰值（避开描边的抗锯齿边缘）。
        double best = 0;
        for (int y = 0; y < 6; y++) {
          final double value = luminance(rgba, w, 100, y);
          if (value > best) best = value;
        }
        return best;
      }

      final double soft = await rimPeak(1);
      final double sharp = await rimPeak(4);
      debugPrint('高光峰值：falloff=1 → $soft，falloff=4 → $sharp');

      expect(soft, greaterThan(0.01), reason: 'falloff=1 时应有可见高光');
      expect(
        sharp,
        lessThan(soft),
        reason: 'falloff 越大强度衰减越快，高光应更暗（验证 uniform 生效）',
      );
    });

    test('高光不越出形状（四角保持透明）', () async {
      const Size size = Size(200, 64);
      final ui.Image image = await renderHighlight(
        size: size,
        radius: 32,
        width: 2,
        color: const Color(0xFFFFFFFF),
      );
      final ByteData data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final Uint8List rgba = data.buffer.asUint8List();
      final int w = image.width;
      image.dispose();

      // 胶囊的圆角处（四个角）在形状之外，高光必须被裁掉。
      for (final (int x, int y) in <(int, int)>[
        (1, 1),
        (198, 1),
        (1, 62),
        (198, 62),
      ]) {
        expect(
          luminance(rgba, w, x, y),
          lessThan(0.02),
          reason: '形状外的 ($x,$y) 不应有高光',
        );
      }
    });
  });
}

/// 仅用于测量屏幕几何的空玻璃壳。
class _OriginProbe extends StatelessWidget {
  const _OriginProbe({required this.pad});

  final double pad;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      cornerRadius: 32,
      padding: pad,
      showHighlight: false,
      child: const SizedBox.expand(),
    );
  }
}
