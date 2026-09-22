import 'dart:async';
import 'package:flutter/material.dart';
import '../adaptive_ui.dart';
import 'github_update_service.dart';

/// 顶部小巧更新提示条。
///
/// 规格：
/// - 弹出在屏幕顶部安全区下方，不遮挡状态栏；
/// - 体积小巧紧凑（微型悬浮胶囊），仅展示核心版本提示；
/// - 默认存在 2 秒后自动收起淡出；
/// - 支持手势向上、向左或向右直接划走（Dismissible）；
/// - 背景透明点击穿透，不阻断底层正常交互；
/// - 纯粹提示，不含任何自动下载逻辑。
void showTopUpdateBanner(
  BuildContext context, {
  required AppUpdateInfo info,
}) {
  final overlayState = Overlay.maybeOf(context, rootOverlay: true);
  if (overlayState == null) return;

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) {
      return _TopUpdateBannerWidget(
        info: info,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      );
    },
  );

  overlayState.insert(entry);
}

class _TopUpdateBannerWidget extends StatefulWidget {
  final AppUpdateInfo info;
  final VoidCallback onDismissed;

  const _TopUpdateBannerWidget({
    required this.info,
    required this.onDismissed,
  });

  @override
  State<_TopUpdateBannerWidget> createState() => _TopUpdateBannerWidgetState();
}

class _TopUpdateBannerWidgetState extends State<_TopUpdateBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();

    // 仅存在 2 秒后自动平滑关闭
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  void _onSwipeDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _autoDismissTimer?.cancel();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: true,
      bottom: false,
      left: false,
      right: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
          child: Dismissible(
            key: const ValueKey('top_update_banner_vertical'),
            direction: DismissDirection.up,
            onDismissed: (_) => _onSwipeDismiss(),
            child: Dismissible(
              key: const ValueKey('top_update_banner_horizontal'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _onSwipeDismiss(),
              child: SlideTransition(
                position: _offsetAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHighest.withOpacity(0.92)
                            : scheme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: scheme.outlineVariant.withOpacity(0.5),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.system_update_alt_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '发现新版本 ${widget.info.version}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
