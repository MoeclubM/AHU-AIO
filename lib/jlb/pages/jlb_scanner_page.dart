import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../adaptive_ui.dart';
import '../../miuix/adaptive_top_app_bar.dart';

/// 近邻宝离线二维码与条码扫描页面（优化高灵敏度与即时反馈）
class JlbScannerPage extends StatefulWidget {
  const JlbScannerPage({super.key});

  @override
  State<JlbScannerPage> createState() => _JlbScannerPageState();
}

class _JlbScannerPageState extends State<JlbScannerPage>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
  late final Animation<double> _scanLineAnimation;

  bool _isTorchOn = false;
  bool _isProcessing = false;
  String? _lastScannedText;
  DateTime _lastScanTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // 关键修复 1：使用 normal 灵敏度与 200ms 快速检测，支持全格式与针对性优化
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 200,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
      ],
      returnImage: false,
    );

    // 扫描激光线上下浮动动画，提供直观的扫描活跃状态反馈
    _animController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 摄像头检测到条形码/二维码时的回调
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final now = DateTime.now();
    // 节流避免过于频繁重复触发弹窗
    if (now.difference(_lastScanTime).inMilliseconds < 400) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue?.trim() ?? '';
      if (rawValue.isEmpty) continue;

      _lastScanTime = now;
      _handleScannedResult(rawValue);
      break;
    }
  }

  /// 核心结果处理逻辑
  void _handleScannedResult(String rawText) {
    if (_isProcessing) return;

    // 1. 尝试直接智能提取 Session ID
    final extractedSession = _extractSessionId(rawText);

    if (extractedSession != null && extractedSession.isNotEmpty) {
      // 成功精确匹配到近邻宝凭证
      _isProcessing = true;
      HapticFeedback.heavyImpact(); // 强震动反馈
      _controller.stop();
      Navigator.of(context).pop(extractedSession);
      return;
    }

    // 2. 如果扫出的文本不是标准凭据格式（比如是纯网址、快递单号或其它文本）
    // 不能静默忽略！必须提供即时震动与用户交互弹窗，让用户知晓已成功识别
    if (rawText != _lastScannedText) {
      _lastScannedText = rawText;
      HapticFeedback.lightImpact();
      _showUnrecognizedResultSheet(rawText);
    }
  }

  /// 智能从各种二维码格式中提取近邻宝 Session
  String? _extractSessionId(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    // 模式 1: 专用协议头 jlb://auth?session=xxxx 或 jlb://...
    if (clean.startsWith('jlb://')) {
      final uri = Uri.tryParse(clean);
      if (uri != null) {
        final sid =
            uri.queryParameters['session'] ??
            uri.queryParameters['sessionId'] ??
            uri.queryParameters['session_id'] ??
            uri.queryParameters['sid'];
        if (sid != null && sid.isNotEmpty) return sid.trim();
      }
    }

    // 模式 2: JSON 格式 (例如 {"session_id": "xxx"} 或 {"sessionId": "xxx"})
    if (clean.startsWith('{') && clean.endsWith('}')) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(clean);
        final sid =
            jsonMap['session_id'] ??
            jsonMap['sessionId'] ??
            jsonMap['sid'] ??
            jsonMap['session'];
        if (sid != null) return sid.toString().trim();
      } catch (_) {}
    }

    // 模式 3: HTTP/HTTPS 链接包含 session 参数
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final uri = Uri.tryParse(clean);
      if (uri != null) {
        final sid =
            uri.queryParameters['session'] ??
            uri.queryParameters['sessionId'] ??
            uri.queryParameters['session_id'] ??
            uri.queryParameters['sid'];
        if (sid != null && sid.isNotEmpty) return sid.trim();
      }
    }

    // 模式 4: 正则匹配形如 sessionId: xxx 或 session_id=xxx
    final match = RegExp(
      r'(?:sessionId|session_id|session|sid)[:=]\s*([a-zA-Z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(clean);
    if (match != null) {
      return match.group(1);
    }

    // 模式 5: 纯 24~64 位字符令牌（无空白、无换行）
    if (clean.length >= 24 &&
        clean.length <= 64 &&
        !clean.contains(' ') &&
        !clean.contains('\n') &&
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clean)) {
      return clean;
    }

    return null;
  }

  /// 扫描到非标准内容时的用户确认抽屉
  void _showUnrecognizedResultSheet(String content) {
    setState(() => _isProcessing = true);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Text(
                    '已成功识别二维码内容',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                      },
                      child: const Text('继续扫描'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        Navigator.of(context).pop(content.trim());
                      },
                      child: const Text('以此作为凭据导入'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  /// 从剪贴板粘贴
  void _manualPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      final sid = _extractSessionId(text) ?? text;
      if (mounted) {
        Navigator.of(context).pop(sid);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('剪贴板中无内容'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AdaptiveTopAppBar(
        title: const Text('扫描近邻宝授权码', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            tooltip: '手电筒',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.paste_rounded, color: Colors.white),
            tooltip: '从剪贴板粘贴',
            onPressed: _manualPaste,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '相机启动异常: ${error.errorCode}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请确认已在手机系统设置中授予 AHU-AIO 相机权限',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.paste),
                        label: const Text('使用剪贴板导入凭据'),
                        onPressed: _manualPaste,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 自定义取景框与扫描激光线
          _buildScanOverlay(context),

          // 底部操作与提示
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    '请将电脑屏幕上的近邻宝授权二维码对准取景框\n（支持任何二维码与剪贴板识别）',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.content_paste_go, size: 18),
                  label: const Text('剪贴板快速导入凭证'),
                  onPressed: _manualPaste,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.72;

    return Center(
      child: Container(
        width: scanBoxSize,
        height: scanBoxSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: Stack(
          children: [
            // 四个高亮角标
            Positioned(
              left: -1,
              top: -1,
              child: _buildCorner(isTop: true, isLeft: true),
            ),
            Positioned(
              right: -1,
              top: -1,
              child: _buildCorner(isTop: true, isLeft: false),
            ),
            Positioned(
              left: -1,
              bottom: -1,
              child: _buildCorner(isTop: false, isLeft: true),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: _buildCorner(isTop: false, isLeft: false),
            ),

            // 动态扫描激光线
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  top: scanBoxSize * _scanLineAnimation.value,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withValues(alpha: 0.1),
                          Colors.blueAccent,
                          Colors.cyanAccent,
                          Colors.blueAccent,
                          Colors.blueAccent.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    const double length = 22.0;
    const double thickness = 3.5;
    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.blueAccent, width: thickness)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.blueAccent, width: thickness)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.blueAccent, width: thickness)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.blueAccent, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }
}
