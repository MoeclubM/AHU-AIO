// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import '../api/api_manager.dart';
import '../utils/api_debug_helper.dart';
import '../../globals.dart' as globals;

/// 通知公告页面
class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = false;
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
    });

    // 获取通知公告数据
    final data = await ApiManager.getNotices(globals.idToken!);

    setState(() {
      // 根据真实API返回格式解析数据
      if (data['noticeShowVms'] != null && data['noticeShowVms'] is List) {
        _notices = (data['noticeShowVms'] as List).cast<Map<String, dynamic>>();
      } else if (data['data'] != null && data['data'] is List) {
        _notices = (data['data'] as List).cast<Map<String, dynamic>>();
      } else if (data['notices'] != null && data['notices'] is List) {
        _notices = (data['notices'] as List).cast<Map<String, dynamic>>();
      } else {
        _notices = [];
      }

      // 调试信息：打印通知数据结构
      if (_notices.isNotEmpty) {
        print('第一个通知的数据结构: ${_notices.first}');
        print('read字段值: ${_notices.first['read']}');
        print('未读通知数量: ${_notices.where((n) => (n['read'] ?? false) == false).length}');
        print('已读通知数量: ${_notices.where((n) => (n['read'] ?? false) == true).length}');
      }

      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredNotices {
    if (_isUnreadTab) {
      // 返回未读通知
      return _notices.where((notice) {
        final isRead = notice['read'] ?? false;
        return isRead != true;
      }).toList();
    } else {
      // 返回已读通知
      return _notices.where((notice) {
        final isRead = notice['read'] ?? false;
        return isRead == true;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '通知公告',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade600,
                Colors.orange.shade600,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadNotices,
            icon: const Icon(Icons.refresh),
          ),
          ApiDebugButton(
            apiName: '通知公告',
            apiUrl: 'https://jwapp.ahu.edu.cn/eams-door/api/v1/protal-notice/get-notices',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab切换栏
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _isUnreadTab = index == 0;
                });
              },
              indicatorColor: Colors.orange.shade600,
              labelColor: Colors.orange.shade600,
              unselectedLabelColor: Colors.grey.shade600,
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

  Widget _buildNoticeCard(Map<String, dynamic> notice, int index) {
    final title = notice['title']?.toString() ?? '无标题';
    final content = _removeHtmlTags(notice['content']?.toString() ?? '');
    final publishTime = notice['sendDateTime']?.toString() ?? '';
    final publisher = notice['publisher']?.toString() ?? '教务处';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatTime(publishTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
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
        onTap: () => _showNoticeDetail(notice),
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
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下拉刷新获取最新通知',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotices,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _showNoticeDetail(Map<String, dynamic> notice) {
    final title = notice['title']?.toString() ?? '无标题';
    final content = _removeHtmlTags(notice['content']?.toString() ?? '');
    final publishTime = notice['sendDateTime']?.toString() ?? '';
    final publisher = notice['publisher']?.toString() ?? '教务处';

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
                Row(
                  children: [
                    const Text('发布者：'),
                    Text(publisher),
                  ],
                ),
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

  // 移除HTML标签的简单函数
  String _removeHtmlTags(String htmlString) {
    // 使用正则表达式移除HTML标签
    final plainText = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    // 移除多余的空白字符
    return plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
