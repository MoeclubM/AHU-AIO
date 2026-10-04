/// KernelSU Manager 风格组件（Flutter 移植）。
///
/// 视觉与交互对照 [KernelSU-Style-UI-Kit](https://github.com/chenaizhang/KernelSU-Style-UI-Kit)：
/// 警告卡、状态大卡、Expressive 开关、可编辑箭头行。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'miuix/miuix_components.dart';
import 'miuix/miuix_theme.dart';
import 'theme_manager.dart';

bool _isMiuix() => ThemeManager().isMiuix;

/// KernelSU 风格警告条：浅红底 + 红字，右侧可放操作按钮。
///
/// 对应 Compose `WarningCard`：动态取色用 `errorContainer`，否则
/// 浅色 `#F8E2E2` / 深色 `#310808`，文字 `#F72727`（动态取色时
/// `onErrorContainer`）。按压反馈为 Tilt。
class WarningCard extends StatelessWidget {
  const WarningCard({
    super.key,
    required this.message,
    this.action,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  final String message;
  final Widget? action;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final MiuixThemeData miuix = MiuixTheme.of(context);
    final bool dynamic = miuix.isDynamic;
    final Color bg = dynamic
        ? miuix.colors.errorContainer
        : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF310808)
              : const Color(0xFFF8E2E2));
    final Color fg = dynamic
        ? miuix.colors.onErrorContainer
        : const Color(0xFFF72727);

    final Widget row = Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, height: 1.35, color: fg),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );

    return MiuixCard(
      cornerRadius: 16,
      colors: MiuixCardColors(color: bg, contentColor: fg),
      onTap: onTap,
      pressFeedback: MiuixPressFeedback.tilt,
      child: row,
    );
  }
}

/// KernelSU 权限/状态大卡：色块 + 超大水印图标 + 标题摘要。
///
/// 对应首页 `PermissionCardMiuix`：通过时绿系，否则红系。
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.ok,
    required this.title,
    required this.summary,
    this.onTap,
    this.okIcon = Icons.check_circle_outline,
    this.badIcon = Icons.cancel_outlined,
    this.height = 140,
  });

  final bool ok;
  final String title;
  final String summary;
  final VoidCallback? onTap;
  final IconData okIcon;
  final IconData badIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color bg = ok ? const Color(0xFFDFFAE4) : const Color(0xFFF8E2E2);
    final Color iconColor = ok
        ? const Color(0xFF36D167)
        : const Color(0xFFF72727);
    const Color textColor = Color(0xFF111111);

    return MiuixCard(
      cornerRadius: 16,
      colors: MiuixCardColors(color: bg, contentColor: textColor),
      onTap: onTap,
      pressFeedback: MiuixPressFeedback.tilt,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            // 右下超大水印图标（对应参考实现 offset 后的 182dp 图标）。
            Positioned(
              right: -12,
              bottom: -18,
              child: Icon(
                ok ? okIcon : badIcon,
                size: height * 1.15,
                color: iconColor.withValues(alpha: 0.9),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: textColor.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// M3 Expressive 开关：拇指上带 ✓ / ✕ 图标（KernelSU `ExpressiveSwitch`）。
class ExpressiveSwitch extends StatelessWidget {
  const ExpressiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showThumbIcon = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final bool showThumbIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Switch(
      value: value,
      onChanged: enabled ? onChanged : null,
      thumbIcon: !showThumbIcon
          ? null
          : WidgetStatePropertyAll(
              Icon(
                value ? Icons.check_rounded : Icons.close_rounded,
                size: 16,
                color: value ? scheme.primary : scheme.surfaceContainerHighest,
              ),
            ),
    );
  }
}

/// 可编辑箭头行：点开对话框改数字/文本（KernelSU `SuperEditArrow`）。
class SuperEditArrow extends StatefulWidget {
  const SuperEditArrow({
    super.key,
    required this.title,
    required this.value,
    required this.onValueChange,
    this.summary,
    this.leading,
    this.keyboardType = TextInputType.number,
    this.suffix,
  });

  final String title;
  final String value;
  final ValueChanged<String> onValueChange;
  final String? summary;
  final Widget? leading;
  final TextInputType keyboardType;
  final String? suffix;

  @override
  State<SuperEditArrow> createState() => _SuperEditArrowState();
}

class _SuperEditArrowState extends State<SuperEditArrow> {
  Future<void> _edit() async {
    final controller = TextEditingController(text: widget.value);
    final String? next = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            maxLines: 1,
            decoration: InputDecoration(
              suffixText: widget.suffix,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (next == null || !mounted) return;
    HapticFeedback.selectionClick();
    widget.onValueChange(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_isMiuix()) {
      return MiuixSuperArrow(
        title: widget.title,
        summary: widget.summary,
        value: widget.value,
        startAction: widget.leading,
        onTap: _edit,
      );
    }
    return ListTile(
      leading: widget.leading,
      title: Text(widget.title),
      subtitle: widget.summary != null ? Text(widget.summary!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.value, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: _edit,
    );
  }
}
