import 'package:flutter/material.dart';
import '../../globals.dart' as globals;
import '../api/sendrequest.dart';

/// API调试辅助工具
class ApiDebugHelper {
  static void showApiDebugDialog(BuildContext context, String apiName, String apiUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('API调试 - $apiName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('API名称', apiName),
              _buildInfoRow('请求URL', apiUrl),
              _buildInfoRow('Token', globals.idToken?.substring(0, 20) ?? '无' + '...'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _testApi(context, apiName, apiUrl),
                icon: const Icon(Icons.play_arrow),
                label: const Text('测试API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _testApi(BuildContext context, String apiName, String apiUrl) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('正在测试API...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final response = await sendRequest(apiUrl, globals.idToken ?? '');

      String result;
      if (response != null) {
        if (response.statusCode == 200) {
          result = '✅ 请求成功 (${response.statusCode})\n\n';
          result += '响应头:\n${response.headers}\n\n';
          result += '响应体:\n${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}';
        } else {
          result = '❌ 请求失败 (${response.statusCode})\n\n';
          result += '错误信息: ${response.reasonPhrase ?? "未知错误"}\n\n';
          result += '响应体:\n${response.body}';
        }
      } else {
        result = '❌ 请求失败: 无响应';
      }

      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('API测试结果 - $apiName'),
            content: SingleChildScrollView(
              child: Text(
                result,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('API测试出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// API调试按钮组件
class ApiDebugButton extends StatelessWidget {
  final String apiName;
  final String apiUrl;

  const ApiDebugButton({
    super.key,
    required this.apiName,
    required this.apiUrl,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => ApiDebugHelper.showApiDebugDialog(context, apiName, apiUrl),
      icon: const Icon(Icons.bug_report),
      tooltip: 'API调试',
      color: Colors.white,
    );
  }
}