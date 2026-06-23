import 'package:flutter/material.dart';
import '../api/jw_api.dart';

class JwNoticePage extends StatefulWidget {
  final bool embed;
  const JwNoticePage({super.key, this.embed = false});

  @override
  State<JwNoticePage> createState() => _JwNoticePageState();
}

class _JwNoticePageState extends State<JwNoticePage>
    with SingleTickerProviderStateMixin {
  final _api = JwApi();
  List<dynamic> _notices = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isUnreadTab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      final notifData = results[1];

      setState(() {
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

  List<dynamic> get _filteredNotices {
    if (_isUnreadTab) {
      return _notices.where((notice) {
        if (notice is! Map) return false;
        final isRead = notice['isRead'] == true || notice['read'] == true;
        return !isRead;
      }).toList();
    } else {
      return _notices.where((notice) {
        if (notice is! Map) return false;
        final isRead = notice['isRead'] == true || notice['read'] == true;
        return isRead;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(
              title: const Text('通知公告'),
              actions: [
                IconButton(
                  onPressed: _loadNotices,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
      body: Column(
        children: [
          // Tab切换栏
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _isUnreadTab = index == 0;
                });
              },
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('未读'),
                      SizedBox(width: 4),
                      Icon(Icons.notifications_active, size: 16),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('已读'),
                      SizedBox(width: 4),
                      Icon(Icons.notifications_none, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 内容区域
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotices,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorWidget()
                  : _buildNoticesList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesList() {
    final filteredNotices = _filteredNotices;

    if (filteredNotices.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotices.length,
      itemBuilder: (context, index) {
        final notice = filteredNotices[index];
        return _buildNoticeCard(notice, index);
      },
    );
  }

  Widget _buildNoticeCard(dynamic notice, int index) {
    if (notice is! Map) return const SizedBox();
    final n = notice as Map<String, dynamic>;
    final title = n['title']?.toString() ?? '无标题';
    final content = _removeHtmlTags(n['content']?.toString() ?? '');
    final publisher =
        n['sender']?.toString() ?? n['publisher']?.toString() ?? '教务处';
    final publishTime =
        n['sendTime']?.toString() ?? n['createDateTime']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (content.isNotEmpty)
              Text(
                content,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  publisher,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatTime(publishTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
        trailing: _isUnreadTab
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _showNoticeDetail(n),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isUnreadTab ? Icons.notifications_off : Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _isUnreadTab ? '暂无未读通知' : '暂无已读通知',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '下拉刷新获取最新通知',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadNotices, child: const Text('重试')),
        ],
      ),
    );
  }

  void _showNoticeDetail(Map<String, dynamic> notice) {
    final title = notice['title']?.toString() ?? '无标题';
    final content = _removeHtmlTags(notice['content']?.toString() ?? '');
    final publisher =
        notice['sender']?.toString() ??
        notice['publisher']?.toString() ??
        '教务处';
    final publishTime =
        notice['sendTime']?.toString() ??
        notice['createDateTime']?.toString() ??
        '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.isNotEmpty) ...[
                  const Text(
                    '内容：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(content),
                  const SizedBox(height: 16),
                ],
                Row(children: [const Text('发布者：'), Text(publisher)]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('发布时间：'),
                    Text(_formatTime(publishTime)),
                  ],
                ),
              ],
            ),
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

  String _formatTime(String timeString) {
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  String _removeHtmlTags(String htmlString) {
    final plainText = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    return plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
