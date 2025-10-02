import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'schedule_logic.dart';
import 'schedule_service.dart';
import 'semester_config.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String? _selectedSemester;
  String? _selectedMonth;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 初始化ScheduleLogic
    Get.put(ScheduleLogic());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialized = false;
    });
    
    final logic = Get.find<ScheduleLogic>();
    await logic.refreshData();
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果数据还未初始化，显示加载界面
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            '课程表',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue.shade600,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '正在加载课表信息...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GetBuilder<ScheduleLogic>(
      builder: (logic) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              '课程表',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blue.shade600,
            elevation: 0,
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 学期和周数选择区域
              _buildSelectionArea(),
              // 课表内容区域
              Expanded(
                child: _buildScheduleContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleContent() {
    return GetBuilder<ScheduleLogic>(
      builder: (logic) {
        if (logic.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '正在加载课表...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '学期：$_selectedSemester',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (logic.scheduleData.isEmpty || logic.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无课表数据',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        logic.errorMessage.isNotEmpty 
                            ? logic.errorMessage.value
                            : '请检查网络连接或稍后重试',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final logic = Get.find<ScheduleLogic>();
                          await logic.refreshData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新加载'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return _buildScheduleTable(logic);
      },
    );
  }

  Widget _buildScheduleTable(ScheduleLogic logic) {
    // 从scheduleData中获取课程数据
    final classes = logic.scheduleData['classes'] as List<dynamic>? ?? [];
    final processedClasses = logic.processClasses(classes);
    
    // 如果没有课程数据，显示空状态
    if (processedClasses.isEmpty) {
      return Center(
        child: Text(
          '暂无课程数据',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    final timeKeys = processedClasses.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  columnWidths: isMobile 
                      ? {
                          0: const FixedColumnWidth(80.0), // 时间段列稍窄
                          1: const FlexColumnWidth(1.0),   // 周一
                          2: const FlexColumnWidth(1.0),   // 周二
                          3: const FlexColumnWidth(1.0),   // 周三
                          4: const FlexColumnWidth(1.0),   // 周四
                          5: const FlexColumnWidth(1.0),   // 周五
                          6: const FlexColumnWidth(1.0),   // 周六
                          7: const FlexColumnWidth(1.0),   // 周日
                        }
                      : {
                          0: const FixedColumnWidth(100.0), // 时间段列
                          1: const FlexColumnWidth(1.0),    // 周一
                          2: const FlexColumnWidth(1.0),    // 周二
                          3: const FlexColumnWidth(1.0),    // 周三
                          4: const FlexColumnWidth(1.0),    // 周四
                          5: const FlexColumnWidth(1.0),    // 周五
                          6: const FlexColumnWidth(1.0),    // 周六
                          7: const FlexColumnWidth(1.0),    // 周日
                        },
                  children: [
                    // 表头
                    TableRow(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade500, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      children: [
                        _buildHeaderCell('时间段'),
                        _buildHeaderCell('周一'),
                        _buildHeaderCell('周二'),
                        _buildHeaderCell('周三'),
                        _buildHeaderCell('周四'),
                        _buildHeaderCell('周五'),
                        _buildHeaderCell('周六'),
                        _buildHeaderCell('周日'),
                      ],
                    ),
                    // 课程行
                    ...timeKeys.map((timeKey) {
                      final weekdays = processedClasses[timeKey]!;
                      return TableRow(
                        children: [
                          _buildTimeCell(timeKey),
                          ...List.generate(7, (index) {
                            final weekday = '周${index + 1}';
                            final classes = weekdays[weekday] ?? [];
                            return _buildClassCell(classes, logic, context);
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String text) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCell(String timeSlot) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: Text(
            timeSlot,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildClassCell(List<Map<String, dynamic>> classes, ScheduleLogic logic, BuildContext context) {
    return TableCell(
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(4),
        child: classes.isEmpty
            ? Container()
            : Column(
                children: classes.take(2).map((classItem) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _showClassDetails(context, classItem, logic),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              classItem['courseName'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (classItem['roomName'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                classItem['roomName'],
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  void _showClassDetails(BuildContext context, Map<String, dynamic> classItem, ScheduleLogic logic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            classItem['courseName'] ?? '课程详情',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(Icons.person, '教师', classItem['teacherName'] ?? '未知'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, '教室', classItem['roomName'] ?? '未知'),
                const SizedBox(height: 12),
                if (classItem['details'] != null && classItem['details'].isNotEmpty) ...[
                  Text(
                    '时间安排:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...classItem['details'].map<Widget>((detail) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${logic.formatTime(detail['startTime'])} - ${logic.formatTime(detail['endTime'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // 构建学期和周数选择区域
  Widget _buildSelectionArea() {
    return GetBuilder<ScheduleLogic>(
      builder: (logic) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 学期选择
              Row(
                children: [
                  const Icon(Icons.school, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '学期：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (logic.allSemesters.isEmpty) {
                        return const Text('加载中...');
                      }
                      return DropdownButton<int>(
                        value: logic.selectedSemester.value?.id,
                        isExpanded: true,
                        underline: Container(),
                        items: logic.allSemesters.map((semester) {
                          return DropdownMenuItem<int>(
                            value: semester.id,
                            child: Text(semester.nameZh),
                          );
                        }).toList(),
                        onChanged: (int? semesterId) {
                          if (semesterId != null) {
                            final semester = logic.allSemesters.firstWhereOrNull(
                              (s) => s.id == semesterId,
                            );
                            if (semester != null) {
                              logic.selectSemester(semester);
                            }
                          }
                        },
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 周数选择
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '周数：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (logic.availableWeeks.isEmpty) {
                        return const Text('暂无周数信息');
                      }
                      return DropdownButton<int>(
                        value: logic.selectedWeek.value,
                        isExpanded: true,
                        underline: Container(),
                        items: logic.availableWeeks.map((week) {
                          return DropdownMenuItem<int>(
                            value: week,
                            child: Text('第 $week 周'),
                          );
                        }).toList(),
                        onChanged: (int? week) {
                          if (week != null) {
                            logic.selectWeek(week);
                          }
                        },
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}