import 'package:flutter/material.dart';
import '../api/jw_api.dart';
import '../models/jw_models.dart';

class JwSchedulePage extends StatefulWidget {
  const JwSchedulePage({super.key});

  @override
  State<JwSchedulePage> createState() => _JwSchedulePageState();
}

class _JwSchedulePageState extends State<JwSchedulePage> {
  final _api = JwApi();
  CourseTableData? _tableData;
  int _currentWeek = 1;
  bool _isLoading = true;
  String? _error;

  static const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _maxSlots = 11;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final weekRaw = await _api.getCurrentTeachWeek();
      final weekInfo = TeachWeekInfo.fromJson(weekRaw);
      _currentWeek = weekInfo.weekIndex ?? 1;

      // 从成绩 API 获取学期列表，匹配当前学期名
      final semList = await _api.getSemesters();
      final currentName = weekInfo.currentSemester ?? '';
      int? semId;
      for (final s in semList) {
        if (s['nameZh']?.toString() == currentName ||
            s['nameEn']?.toString() == currentName) {
          semId = toInt(s['id']);
          break;
        }
      }
      // 降级：使用最大 ID 的学期（通常是最新的）
      semId ??= semList.isNotEmpty ? toInt(semList.last['id']) : null;

      if (semId != null) {
        final raw = await _api.getCourseTablePrintData(semId);
        setState(() {
          _tableData = CourseTableData.fromJson(raw);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = '无法获取当前学期';
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  List<CourseActivity> _activitiesForSlot(int weekday, int slot) {
    if (_tableData == null) return [];
    return _tableData!.activities.where((a) {
      if (a.weekday != weekday) return false;
      if (a.startUnit == null || a.endUnit == null) return false;
      return a.startUnit! <= slot && a.endUnit! >= slot;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的课表')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _tableData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                ],
              ),
            )
          : _buildSchedule(),
    );
  }

  Widget _buildSchedule() {
    final activities =
        _tableData?.activities
            .where((a) => a.weekIndexes.contains(_currentWeek))
            .toList() ??
        [];

    return Column(
      children: [
        _buildWeekSelector(),
        _buildStudentInfo(),
        Expanded(child: _buildGrid(activities)),
      ],
    );
  }

  Widget _buildStudentInfo() {
    final t = _tableData;
    if (t == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${t.studentName ?? ''}  ${t.major ?? ''}  ${t.adminclass ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (t.totalCredits != null)
            Text(
              '已修 ${t.totalCredits} 学分',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: _currentWeek > 1
                ? () => setState(() => _currentWeek--)
                : null,
          ),
          Expanded(
            child: Text(
              '第 $_currentWeek 周',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _currentWeek < 20
                ? () => setState(() => _currentWeek++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<CourseActivity> weekActivities) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间列
            Column(
              children: [
                const SizedBox(
                  width: 46,
                  height: 32,
                  child: Center(
                    child: Text(
                      '节次',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...List.generate(_maxSlots, (i) {
                  return Container(
                    width: 46,
                    height: 56,
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  );
                }),
              ],
            ),
            // 每天列
            ...List.generate(7, (dayIdx) {
              final wd = dayIdx + 1;
              return Column(
                children: [
                  SizedBox(
                    width: 90,
                    height: 32,
                    child: Center(
                      child: Text(
                        _weekdays[wd],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(_maxSlots, (slotIdx) {
                    final slot = slotIdx + 1;
                    final slotActs = _activitiesForSlot(wd, slot);
                    // 只在开始节次绘制卡片
                    final startActs = slotActs
                        .where((a) => a.startUnit == slot)
                        .toList();

                    return Container(
                      width: 90,
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: startActs.isNotEmpty
                          ? _buildActivityCard(startActs.first)
                          : slotActs.isNotEmpty
                          ? null // 中间节次不绘制
                          : null,
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(CourseActivity a) {
    // 根据课程名生成不同颜色
    final colors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.orange.shade50,
      Colors.purple.shade50,
      Colors.cyan.shade50,
      Colors.pink.shade50,
    ];
    final colorIdx = a.courseName.hashCode.abs() % colors.length;

    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors[colorIdx],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            a.courseName ?? '',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (a.room != null)
            Text(
              a.room!,
              style: const TextStyle(fontSize: 7, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (a.teacherStr.isNotEmpty)
            Text(
              a.teacherStr,
              style: const TextStyle(fontSize: 7, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
