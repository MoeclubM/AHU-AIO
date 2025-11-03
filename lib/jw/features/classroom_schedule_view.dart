// ignore_for_file: avoid_print, prefer_final_fields, prefer_for_elements_to_map_fromiterable, unnecessary_brace_in_string_interps, unnecessary_non_null_assertion, unnecessary_string_interpolations, unnecessary_type_check, unused_element
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../globals.dart' as globals;
import '../api/sendrequest.dart';
import '../utils/api_debug_helper.dart';

/// 教室课表查询页面（原版系统风格）
class ClassroomSchedulePage extends StatefulWidget {
  const ClassroomSchedulePage({super.key});

  @override
  State<ClassroomSchedulePage> createState() => _ClassroomSchedulePageState();
}

class _ClassroomSchedulePageState extends State<ClassroomSchedulePage> {
  List<Map<String, dynamic>> _classrooms = [];
  List<Map<String, dynamic>> _filteredClassrooms = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedSemester = '2025-2026-1';

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoading = true;
    });

    // 获取教室列表数据 - 使用正确的API URL
    final response = await _sendRequest(
      'https://jwapp.ahu.edu.cn/eams-room-course-table-app/api/room/list',
      globals.idToken ?? '',
    );

    setState(() {
      if (response?['statusCode'] == 200) {
        final data = response!['body'] is String ? jsonDecode(response!['body']) : response!['body'];
        _classrooms = (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
        _filteredClassrooms = List.from(_classrooms);

        // 调试信息
        print('教室数据加载成功，共${_classrooms.length}个教室');
        if (_classrooms.isNotEmpty) {
          print('第一个教室: ${_classrooms.first}');
        }
      } else {
        _error = '请求失败: ${response?['statusCode']}';
        print('教室数据加载失败: $_error, 响应: $response');
      }
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _sendRequest(String url, String token) async {
    // 获取教室列表的真实API请求
    final response = await sendRequest(url, token);

    if (response != null && response.statusCode == 200) {
      return {
        'statusCode': 200,
        'body': response.body,
      };
    } else {
      return {
        'statusCode': response?.statusCode ?? 500,
        'body': '{"data": []}',
      };
    }
  }

  // 获取教室课表数据
  Future<Map<String, dynamic>?> _getClassroomSchedule(String roomId) async {
    final url = 'https://jwapp.ahu.edu.cn/eams-room-course-table-app/api/room/schedule?roomId=$roomId';
    final response = await sendRequest(url, globals.idToken ?? '');

    if (response != null && response.statusCode == 200) {
      return {
        'statusCode': 200,
        'body': response.body,
      };
    } else {
      return {
        'statusCode': response?.statusCode ?? 500,
        'body': '{"data": []}',
      };
    }
  }

  void _filterClassrooms() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredClassrooms = List.from(_classrooms);
      } else {
        _filteredClassrooms = _classrooms.where((classroom) {
          final name = (classroom['roomName'] ?? '').toLowerCase();
          final code = (classroom['roomCode'] ?? '').toLowerCase();
          final building = (classroom['buildingName'] ?? '').toLowerCase();
          final campus = (classroom['campusName'] ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();

          return name.contains(query) ||
                 code.contains(query) ||
                 building.contains(query) ||
                 campus.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '教室课表',
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
                Colors.cyan.shade600,
                Colors.cyan.shade700,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadClassrooms,
            icon: const Icon(Icons.refresh),
          ),
          ApiDebugButton(
            apiName: '教室列表',
            apiUrl: 'https://jwapp.ahu.edu.cn/eams-room-course-table-app/api/room/list',
          ),
        ],
      ),
      body: Column(
        children: [
          // 学期选择
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  '当前学期: $_selectedSemester',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // 搜索框
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '请输入教室名称搜索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _filterClassrooms();
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (_) => _filterClassrooms(),
            ),
          ),

          // 筛选按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterDialog,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('筛选'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _filterClassrooms,
                    icon: const Icon(Icons.search),
                    label: const Text('搜索'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 教室列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildClassroomList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomList() {
    if (_filteredClassrooms.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredClassrooms.length,
      itemBuilder: (context, index) {
        final classroom = _filteredClassrooms[index];
        return _buildClassroomCard(classroom);
      },
    );
  }

  Widget _buildClassroomCard(Map<String, dynamic> classroom) {
    final roomName = classroom['roomName']?.toString() ?? '';
    final roomCode = classroom['roomCode']?.toString() ?? '';
    final isVirtual = classroom['isVirtual'] == true;
    final campusName = classroom['campusName']?.toString() ?? '';
    final buildingName = classroom['buildingName']?.toString() ?? '';
    final floor = classroom['floor']?.toString() ?? '';
    final roomType = classroom['roomType']?.toString() ?? '';
    final capacity = classroom['capacity']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isVirtual ? Colors.purple.shade100 : Colors.cyan.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isVirtual ? Icons.computer : Icons.meeting_room,
            color: isVirtual ? Colors.purple.shade600 : Colors.cyan.shade600,
            size: 24,
          ),
        ),
        title: Text(
          roomName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildInfoChip('编号', roomCode),
                const SizedBox(width: 8),
                if (isVirtual)
                  _buildInfoChip('类型', '虚拟教室', Colors.purple)
                else
                  _buildInfoChip('类型', roomType),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildInfoChip('校区', campusName),
                const SizedBox(width: 8),
                if (buildingName.isNotEmpty)
                  _buildInfoChip('楼栋', buildingName),
                const SizedBox(width: 8),
                _buildInfoChip('楼层', floor),
              ],
            ),
            const SizedBox(height: 4),
            _buildInfoChip('容量', '${capacity}人座'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.cyan.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$capacity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade700,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showClassroomDetail(classroom),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey.shade200).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  void _showClassroomDetail(Map<String, dynamic> classroom) {
    final roomId = classroom['roomId']?.toString() ?? '';
    final roomName = classroom['roomName']?.toString() ?? '教室';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassroomScheduleDetailPage(
          roomId: roomId,
          roomName: roomName,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选条件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 这里可以添加更多筛选选项
            const Text('筛选功能开发中...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '未找到教室',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试调整搜索条件',
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
            onPressed: _loadClassrooms,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 教室课表详情页面
class ClassroomScheduleDetailPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ClassroomScheduleDetailPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ClassroomScheduleDetailPage> createState() => _ClassroomScheduleDetailPageState();
}

class _ClassroomScheduleDetailPageState extends State<ClassroomScheduleDetailPage> {
  Map<String, dynamic> _scheduleData = {};
  bool _isLoading = false;
  String? _error;
  String _selectedWeek = '第5周';

  @override
  void initState() {
    super.initState();
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
    });

    // 获取教室课表数据
    final response = await sendRequest(
      'https://jwapp.ahu.edu.cn/eams-room-course-table-app/api/room/schedule?roomId=${widget.roomId}&week=$_selectedWeek',
      globals.idToken ?? '',
    );

    setState(() {
      if (response != null && response.statusCode == 200) {
        try {
          final dynamic decoded = jsonDecode(response.body);
          _scheduleData = decoded is Map<String, dynamic>
              ? decoded
              : <String, dynamic>{'schedule': decoded};
          _error = null;
        } catch (e) {
          _error = '数据解析失败';
        }
      } else {
        _error = '请求失败: ${response?.statusCode}';
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          '${widget.roomName} - 课表',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
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
                Colors.cyan.shade600,
                Colors.cyan.shade700,
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadScheduleData,
        child: Column(
          children: [
            // 周次选择
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Text('当前周次：', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedWeek,
                    items: List.generate(20, (index) => '第${index + 1}周')
                        .map((week) => DropdownMenuItem(
                              value: week,
                              child: Text(week),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedWeek = value;
                        });
                        _loadScheduleData();
                      }
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _loadScheduleData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('刷新'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ApiDebugButton(
                    apiName: '教室课表',
                    apiUrl: 'https://jwapp.ahu.edu.cn/eams-room-course-table-app/api/room/schedule?roomId=${widget.roomId}&week=$_selectedWeek',
                  ),
                ],
              ),
            ),

            // 课表内容
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorWidget()
                      : _buildScheduleGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleGrid() {
    // 构建课表网格
    final timeSlots = ['第1节', '第2节', '第3节', '第4节', '第5节', '第6节', '第7节', '第8节', '第9节', '第10节', '第11节', '第12节', '第13节'];
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: {
          0: const FixedColumnWidth(60), // 时间列
          ...Map.fromIterable(
            weekdays,
            key: (day) => day,
            value: (day) => const FlexColumnWidth(),
          ),
        },
        children: [
          // 表头
          TableRow(
            decoration: BoxDecoration(color: Colors.cyan.shade50),
            children: [
              const TableCell(child: Center(child: Text('时间'))),
              ...weekdays.map((day) => TableCell(
                child: Center(child: Text(day)),
              )),
            ],
          ),
          // 时间行
          ...timeSlots.asMap().entries.map((entry) {
            final timeIndex = entry.key;
            final timeSlot = entry.value;

            return TableRow(
              children: [
                TableCell(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      timeSlot,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // 每天的课程格子
                ...weekdays.asMap().entries.map((dayEntry) {
                  final dayIndex = dayEntry.key;
                  return TableCell(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      height: 60,
                      child: _buildCourseCell(timeIndex, dayIndex),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCourseCell(int timeIndex, int dayIndex) {
    // 这里应该根据实际的课表数据来显示课程
    // 暂时显示空格子
    final schedule = _scheduleData['schedule'] as List<dynamic>? ?? [];

    for (var item in schedule) {
      if (item['dayIndex'] == dayIndex && item['timeIndex'] == timeIndex) {
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.cyan.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['courseName']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item['teacherName']?.toString().isNotEmpty == true)
                Text(
                  item['teacherName']?.toString() ?? '',
                  style: const TextStyle(fontSize: 8),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      }
    }

    return const SizedBox.shrink();
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
            onPressed: _loadScheduleData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
