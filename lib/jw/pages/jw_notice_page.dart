import 'package:flutter/material.dart';
import '../api/jw_api.dart';

class JwNoticePage extends StatefulWidget {
  const JwNoticePage({super.key});

  @override
  State<JwNoticePage> createState() => _JwNoticePageState();
}

class _JwNoticePageState extends State<JwNoticePage> {
  final _api = JwApi();
  List<dynamic> _notices = [];
  Map<String, dynamic>? _counts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getNoticeCounts(),
        _api.getNotifications(),
      ]);
      final countData = results[0];
      final notifData = results[1];

      setState(() {
        _counts = countData['noticeCount'] as Map<String, dynamic>?;
        _notices = (notifData['data'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _counts?['noReadCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('通知公告 ($unread)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotices,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : _notices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    unread > 0
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(unread > 0 ? '有 $unread 条未读通知' : '暂无通知'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notices.length,
              itemBuilder: (ctx, i) => _buildNoticeCard(_notices[i]),
            ),
    );
  }

  Widget _buildNoticeCard(dynamic notice) {
    if (notice is! Map) return const SizedBox();
    final n = notice as Map<String, dynamic>;
    final title = n['title']?.toString() ?? '无标题';
    final content = n['content']?.toString() ?? '';
    final sender = n['sender']?.toString() ?? '';
    final sendTime =
        n['sendTime']?.toString() ?? n['createDateTime']?.toString() ?? '';
    final isRead = n['isRead'] == true || n['read'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(title, content, sender, sendTime),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (sendTime.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sendTime,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(String title, String content, String sender, String time) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sender.isNotEmpty)
                Text(
                  '发送人: $sender',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              if (time.isNotEmpty)
                Text(
                  '时间: $time',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              const SizedBox(height: 12),
              Text(content.isNotEmpty ? content : '暂无详细内容'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
