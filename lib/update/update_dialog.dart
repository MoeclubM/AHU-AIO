import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../adaptive_ui.dart';
import '../jw/pages/jw_webview_page.dart';
import 'github_update_service.dart';

/// 将字节数格式化为可读大小。
String formatByteSize(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var i = 0;
  while (size >= 1024 && i < units.length - 1) {
    size /= 1024;
    i++;
  }
  final text = size >= 100 || i == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$text ${units[i]}';
}

/// 打开下载/发布页：复用应用内 WebView，避免额外 url_launcher 依赖。
Future<void> openUpdateUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => JwWebViewPage(title: '下载更新', url: url),
    ),
  );
}

/// 「发现新版本」对话框。
Future<void> showUpdateAvailableDialog(
  BuildContext context, {
  required AppUpdateInfo info,
  VoidCallback? onDismiss,
}) {
  return showAdaptiveAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final notes = info.releaseNotes.trim();
      final downloadLabel = info.hasDownload
          ? '下载 ${info.matchedAsset!.name}'
          : '前往 GitHub 下载';

      return AdaptiveAlertDialog(
        title: Text('发现新版本 ${info.version}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前版本 ${info.currentVersion.isEmpty ? "未知" : info.currentVersion}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              if (info.hasDownload) ...[
                const SizedBox(height: 4),
                Text(
                  '安装包 ${formatByteSize(info.matchedAsset!.size)}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Text('更新日志', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 6),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    notes.isEmpty ? '（本版本未提供更新说明）' : notes,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          AdaptiveTextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDismiss?.call();
            },
            child: const Text('忽略此版本'),
          ),
          AdaptiveTextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: info.htmlUrl));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('已复制 Release 链接')),
                );
              }
            },
            child: const Text('复制链接'),
          ),
          AdaptivePrimaryButton(
            minimumSize: const Size(100, 38),
            onPressed: () {
              Navigator.of(ctx).pop();
              final url = info.hasDownload
                  ? info.matchedAsset!.downloadUrl
                  : info.htmlUrl;
              openUpdateUrl(context, url);
            },
            child: Text(downloadLabel),
          ),
        ],
      );
    },
  );
}

/// 手动检查结果：已是最新。
Future<void> showUpToDateDialog(BuildContext context, String version) {
  return showAdaptiveAppDialog<void>(
    context: context,
    builder: (ctx) => AdaptiveAlertDialog(
      title: const Text('检查更新'),
      content: Text('当前已是最新版本（$version）'),
      actions: [
        AdaptivePrimaryButton(
          minimumSize: const Size(80, 38),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('好的'),
        ),
      ],
    ),
  );
}

/// 手动检查结果：失败。
Future<void> showUpdateErrorDialog(BuildContext context, String message) {
  return showAdaptiveAppDialog<void>(
    context: context,
    builder: (ctx) => AdaptiveAlertDialog(
      title: const Text('检查更新失败'),
      content: Text(message),
      actions: [
        AdaptiveTextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('关闭'),
        ),
        AdaptivePrimaryButton(
          minimumSize: const Size(100, 38),
          onPressed: () {
            Navigator.of(ctx).pop();
            openUpdateUrl(context, kGitHubReleasesPageUrl.toString());
          },
          child: const Text('打开 Releases'),
        ),
      ],
    ),
  );
}
