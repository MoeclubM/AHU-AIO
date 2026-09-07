import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../globals.dart' as globals;
import '../api/jw_api.dart';
import '../login/jw_login_service.dart';
import '../../auth/unified_login_page.dart';
import '../models/jw_models.dart';
import '../utils/jw_retry.dart';
import '../pages/jw_grades_page.dart';
import '../pages/jw_schedule_page.dart';
import '../pages/jw_exam_page.dart';
import '../pages/jw_program_page.dart';
import '../pages/jw_student_info_page.dart';
import '../pages/jw_precaution_page.dart';
import '../pages/jw_course_select_page.dart';
import '../pages/jw_notice_page.dart';

/// 新教务系统首页
class JwHomePage extends StatefulWidget {
  final bool embed;
  const JwHomePage({super.key, this.embed = false});

  @override
  State<JwHomePage> createState() => _JwHomePageState();
}

class _JwHomePageState extends State<JwHomePage> {
  final _api = JwApi();
  Map<String, dynamic>? _teachWeek;
  Map<String, dynamic>? _notices;
  bool _isLoading = true;
  String? _error;
  bool _isCached = false;

  static const _cacheTeachWeekKey = 'jw_home_teach_week_cache';
  static const _cacheNoticesKey = 'jw_home_notices_cache';

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      await _api.init();
    } catch (_) {}
    _loadData();
  }

  Future<void> _loadData() async {
    // 先尝试读取缓存，避免网络抖动时白屏；缓存命中则先展示，再后台刷新
    Map<String, dynamic>? cachedWeek;
    Map<String, dynamic>? cachedNotices;
    try {
      final prefs = await SharedPreferences.getInstance();
      final w = prefs.getString(_cacheTeachWeekKey);
      final n = prefs.getString(_cacheNoticesKey);
      if (w != null) cachedWeek = jsonDecode(w) as Map<String, dynamic>;
      if (n != null) cachedNotices = jsonDecode(n) as Map<String, dynamic>;
    } catch (_) {}

    final hasCache = cachedWeek != null || cachedNotices != null;
    if (hasCache && _teachWeek == null && _notices == null) {
      setState(() {
        if (cachedWeek != null) _teachWeek = cachedWeek;
        if (cachedNotices != null) _notices = cachedNotices;
        _isCached = true;
        _isLoading = false;
        _error = null;
      });
    } else {
      setState(() {
        // 无缓存时展示 loading，有缓存时保持展示缓存并后台静默刷新
        _isLoading = hasCache ? false : true;
        _error = null;
        if (hasCache) _isCached = true;
      });
    }

    try {
      // 对瞬时抖动自动重试 3 次，认证类错误由 JwApi 拦截器重登录，不在此重试
      final weekRaw = await jwRetry<Map<String, dynamic>>(
        () => _api.getCurrentTeachWeek(),
      );
      final noticeRaw = await jwRetry<Map<String, dynamic>>(
        () => _api.getNoticeCounts(),
      );

      // 写入缓存
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheTeachWeekKey, jsonEncode(weekRaw));
        await prefs.setString(_cacheNoticesKey, jsonEncode(noticeRaw));
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _teachWeek = weekRaw;
        _notices = noticeRaw;
        _isLoading = false;
        _isCached = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (hasCache || _teachWeek != null || _notices != null) {
        // 全部重试失败但有缓存：保留缓存并在顶栏提醒
        setState(() {
          _isCached = true;
          _isLoading = false;
          _error = '网络波动，已重试多次仍失败，当前为本地缓存';
        });
      } else {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
          _isCached = false;
        });
      }
    }
  }

  void _logout() async {
    await JwLoginService.logout();
    if (!mounted) return;
    if (globals.onLoginStateChanged == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UnifiedLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 有缓存时即使 _error != null 也展示缓存 + 顶栏横幅，而非全屏错误
    final hasData = _teachWeek != null || _notices != null;
    final showCachedBanner = _isCached && _error != null && hasData;
    final showFullscreenError = _error != null && !hasData && !_isLoading;
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(
              title: const Text('安大教务'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: '退出登录',
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : showFullscreenError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 148),
                children: [
                  if (showCachedBanner) _buildCacheBanner(),
                  if (showCachedBanner) const SizedBox(height: 12),
                  _buildTeachWeekCard(),
                  const SizedBox(height: 16),
                  _buildNoticeCard(),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildCacheBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? '当前为本地缓存数据',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _loadData,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '重试',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachWeekCard() {
    final week = _teachWeek;
    if (week == null) return const SizedBox();
    // 使用 TeachWeekInfo 统一处理负周数/非学期越界
    final info = TeachWeekInfo.fromJson(week);
    final weekText = info.weekLabel;
    final statusText = info.statusLabel;
    final statusColor = info.isInSemester ? Colors.green : Colors.orange;
    final weekColor = info.isInSemester ? Colors.blue : Colors.grey;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              week['currentSemester'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              weekText,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: weekColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(fontSize: 14, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard() {
    final notices = _notices;
    if (notices == null) return const SizedBox();

    final noticeCount = notices['noticeCount'] ?? {};
    final noReadCount = noticeCount['noReadCount'] ?? 0;

    return Card(
      child: ListTile(
        leading: Icon(
          noReadCount > 0
              ? Icons.notifications_active
              : Icons.notifications_none,
          color: noReadCount > 0 ? Colors.orange : Colors.grey,
        ),
        title: const Text('通知公告'),
        subtitle: Text('未读 $noReadCount 条'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JwNoticePage()),
          );
        },
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _Feature('成绩查询', Icons.grade, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwGradesPage()),
        );
      }),
      _Feature('我的课表', Icons.schedule, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwSchedulePage()),
        );
      }),
      _Feature('考试安排', Icons.quiz, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwExamPage()),
        );
      }),
      _Feature('培养方案', Icons.menu_book, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwProgramPage()),
        );
      }),
      _Feature('学籍信息', Icons.badge, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwStudentInfoPage()),
        );
      }),
      _Feature('学业预警', Icons.warning, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwPrecautionPage()),
        );
      }),
      _Feature('选课系统', Icons.app_registration, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JwCourseSelectPage()),
        );
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return Card(
          child: InkWell(
            onTap: f.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(f.icon, size: 28, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  f.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _Feature(this.title, this.icon, this.onTap);
}
