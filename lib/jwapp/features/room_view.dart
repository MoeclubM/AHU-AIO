import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../adaptive_dropdown.dart';
import '../../adaptive_ui.dart';
import '../../miuix/adaptive_top_app_bar.dart';
import '../api/getroom.dart';
import '../models/room_model.dart';
import '../../globals.dart' as globals;

/// 空闲教室查询。
///
/// 与原始教务 Web 对齐：
/// 1. 校区 / 建筑走 `room/place/*`；
/// 2. 课节用 `room/system/course-units`（官方 1–13 节）；
/// 3. 教室列表 POST `room/place/rooms`，**按日期分页拉取**（服务端
///    `buildingId` 筛选无效，客户端过滤）；
/// 4. 占用来自响应内嵌 `roomOccupationInfoVms`，按 HHMM 与课节重叠判定。
class RoomPage extends StatefulWidget {
  final bool embed;
  const RoomPage({super.key, this.embed = false});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with AutomaticKeepAliveClientMixin {
  List<CampusModel> _campuses = [];
  List<BuildingModel> _buildings = [];
  List<CourseUnit> _units = [];
  List<RoomModel> _allRooms = [];
  List<RoomModel> _rooms = [];

  CampusModel? _selectedCampus;
  BuildingModel? _selectedBuilding;
  CourseUnit? _focusUnit;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingMeta = false;
  String? _error;
  String? _semesterLabel;
  String? _buildingName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _bootstrap() async {
    if (globals.idToken == null || globals.idToken!.isEmpty) {
      setState(() => _error = '尚未登录教务，请先登录后再查询空闲教室');
      return;
    }
    setState(() {
      _isLoadingMeta = true;
      _error = null;
    });
    try {
      await Future.wait([_loadSemester(), _loadUnits()]);
      await _loadCampuses();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingMeta = false);
    }
  }

  Future<void> _loadSemester() async {
    final token = globals.idToken!;
    try {
      final data = await RoomApi.getCurrentSemester(token);
      final dynamic inner = data['data'];
      final Map<String, dynamic> map = inner is Map
          ? Map<String, dynamic>.from(inner)
          : Map<String, dynamic>.from(data);
      final String name =
          map['nameZh']?.toString() ??
          map['name']?.toString() ??
          (map['schoolYear'] != null
              ? '${map['schoolYear']} ${map['season'] ?? ''}'
              : '');
      if (name.isNotEmpty) _semesterLabel = name;
    } catch (_) {
      // 学期信息失败不阻断查询。
    }
  }

  Future<void> _loadUnits() async {
    final list = await RoomApi.getCourseUnits(globals.idToken!);
    final units = list
        .map((e) => CourseUnit.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((u) => u.startTime > 0 && u.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.indexNo.compareTo(b.indexNo));
    if (!mounted) return;
    setState(() {
      _units = units;
      _focusUnit = units.isEmpty ? null : units.first;
    });
  }

  Future<void> _loadCampuses() async {
    final list = await RoomApi.getCampuses(globals.idToken!);
    final campuses = list
        .map((e) => CampusModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (!mounted) return;
    setState(() {
      _campuses = campuses;
      _selectedCampus = campuses.isNotEmpty ? campuses.first : null;
    });
    if (_selectedCampus != null) {
      await _loadBuildings(_selectedCampus!.id);
    }
  }

  Future<void> _loadBuildings(String campusId) async {
    final list = await RoomApi.getBuildings(
      globals.idToken!,
      campusAssoc: campusId,
    );
    final buildings = list
        .map((e) => BuildingModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (!mounted) return;
    setState(() {
      _buildings = buildings;
      _selectedBuilding = null;
      _rooms = [];
      _allRooms = [];
    });
  }

  Future<void> _searchRooms() async {
    if (globals.idToken == null || globals.idToken!.isEmpty) {
      setState(() => _error = '尚未登录教务');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_units.isEmpty) await _loadUnits();
      // 服务端 buildingId 无效：分页拉当日教室，再客户端过滤。
      final raw = await RoomApi.fetchRoomsPaged(
        globals.idToken!,
        date: _dateKey,
        pageSize: 500,
      );
      final all = raw
          .map((e) => RoomModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      String buildingId = _selectedBuilding?.id ?? '';
      // 无建筑选择时，若用户只选了校区，仍可展示该校区相关楼（buildingId 过滤）。
      final byBuilding = <RoomModel>[
        for (final r in all)
          if (buildingId.isEmpty || r.buildingId == buildingId) r,
      ];

      setState(() {
        _allRooms = all;
        _rooms = _applyFilters(byBuilding);
        _buildingName = _selectedBuilding?.name;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<RoomModel> _applyFilters(List<RoomModel> source) {
    final String q = _searchQuery.trim().toLowerCase();
    var list = source.where((r) => !r.virtualRoom).toList();
    if (q.isNotEmpty) {
      list = list.where((r) {
        return r.name.toLowerCase().contains(q) ||
            r.code.toLowerCase().contains(q) ||
            r.campusName.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      if (_selectedBuilding != null) {
        final String buildingId = _selectedBuilding!.id;
        _rooms = _applyFilters([
          for (final r in _allRooms)
            if (r.buildingId == buildingId) r,
        ]);
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
      // 日期变了需要重新拉占用。
      await _searchRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: widget.embed
          ? null
          : AdaptiveTopAppBar(
              title: const Text('空闲教室查询'),
              actions: [
                AdaptiveIconButton(
                  onPressed: _isLoading ? null : _searchRooms,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading || _isLoadingMeta
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _buildRoomsList(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: adaptiveBottomPadding(context)),
        child: AdaptiveFloatingActionButton(
          onPressed: _isLoading ? null : _searchRooms,
          child: const Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return AdaptiveCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_semesterLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '当前学期：$_semesterLabel',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text('校区', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: AdaptiveDropdown<CampusModel>(
                  value: _selectedCampus,
                  hint: '选择校区',
                  isExpanded: true,
                  items: _campuses
                      .map(
                        (campus) => AdaptiveDropdownItem<CampusModel>(
                          value: campus,
                          label: campus.name,
                        ),
                      )
                      .toList(),
                  onChanged: (campus) {
                    if (campus != null) {
                      setState(() {
                        _selectedCampus = campus;
                        _rooms = [];
                        _allRooms = [];
                        _selectedBuilding = null;
                      });
                      _loadBuildings(campus.id);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.business, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text('建筑', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: AdaptiveDropdown<BuildingModel>(
                  value: _selectedBuilding,
                  hint: '选择建筑',
                  isExpanded: true,
                  items: _buildings
                      .map(
                        (b) => AdaptiveDropdownItem<BuildingModel>(
                          value: b,
                          label: b.name,
                        ),
                      )
                      .toList(),
                  onChanged: (building) {
                    setState(() {
                      _selectedBuilding = building;
                      _rooms = [];
                      _allRooms = [];
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text('日期', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(_dateKey),
                  ),
                ),
              ),
            ],
          ),
          if (_units.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('课节', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: AdaptiveDropdown<CourseUnit>(
                    value: _focusUnit,
                    hint: '查看该节空闲',
                    isExpanded: true,
                    items: _units
                        .map(
                          (u) => AdaptiveDropdownItem<CourseUnit>(
                            value: u,
                            label: u.display,
                          ),
                        )
                        .toList(),
                    onChanged: (u) {
                      setState(() => _focusUnit = u);
                      if (_selectedBuilding != null) _searchRooms();
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SuperSearchField(
            controller: _searchController,
            hintText: '教室名称 / 编号',
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdaptiveOutlinedButton(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list),
                  child: const Text('更多筛选'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdaptivePrimaryButton(
                  minimumSize: const Size(80, 40),
                  onPressed: _isLoading ? null : _searchRooms,
                  icon: const Icon(Icons.search),
                  child: Text(_buildingName == null ? '查询空闲教室' : '查询 $_buildingName'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showAdaptiveAppDialog(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: const Text('筛选说明'),
        content: const Text(
          '服务端暂不支持按楼/容量过滤教室列表。\n'
          '应用会：\n'
          '1. 按所选日期分页拉取教室；\n'
          '2. 客户端按建筑过滤；\n'
          '3. 按官方课节计算空闲时段。\n\n'
          '虚拟教室已自动排除。',
        ),
        actions: [
          AdaptiveTextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              '查询失败',
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
            AdaptivePrimaryButton(
              minimumSize: const Size(120, 40),
              onPressed: _bootstrap,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _allRooms.isEmpty
                  ? '请选择建筑后点击查询'
                  : '该建筑下没有匹配的教室',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '日期：$_dateKey',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // 有聚焦课节时：优先展示该节空闲教室。
    final List<RoomModel> display;
    final CourseUnit? unit = _focusUnit;
    if (unit != null) {
      display = [
        ..._rooms.where((r) => !r.isOccupiedAt(unit)),
        ..._rooms.where((r) => r.isOccupiedAt(unit)),
      ];
    } else {
      display = _rooms;
    }

    return ListView.builder(
      padding: adaptivePagePadding(context, horizontal: 16, top: 16),
      itemCount: display.length,
      itemBuilder: (context, index) => _buildRoomCard(display[index], unit),
    );
  }

  Widget _buildRoomCard(RoomModel room, CourseUnit? focus) {
    final List<CourseUnit> free = room.freeUnits(_units);
    final List<CourseUnit> occupied = room.occupiedUnits(_units);
    final bool freeNow = focus == null
        ? room.isFreeDay
        : !room.isOccupiedAt(focus);
    final String statusText;
    if (focus != null) {
      statusText = freeNow ? '${focus.label}空闲' : '${focus.label}占用';
    } else {
      statusText = room.isFreeDay ? '当日空闲' : '当日有课';
    }

    return AdaptiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: freeNow
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.meeting_room,
                    color: freeNow
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        [
                          if (room.code.isNotEmpty) room.code,
                          if (room.campusName.isNotEmpty) room.campusName,
                          if (room.floor.isNotEmpty) '楼层 ${room.floor}',
                          if (room.capacity > 0) '容量 ${room.capacity}',
                        ].join(' | '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: freeNow ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (focus != null && room.hasOccupation) ...[
              const SizedBox(height: 12),
              const Text(
                '占用活动：',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              for (final occ in room.occupations.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${_hhmm(occ.startTime)}-${_hhmm(occ.endTime)}  ${occ.activityName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
            ] else if (free.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                focus == null ? '空闲课节：' : '其他空闲课节：',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final u in free.take(6))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        u.display,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _hhmm(int v) {
    final int h = v ~/ 100;
    final int m = v % 100;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

/// 搜索框（不依赖 ks_widgets，保持 feature 自洽）。
class SuperSearchField extends StatelessWidget {
  const SuperSearchField({
    super.key,
    required this.controller,
    this.hintText = '搜索',
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: '清空',
              onPressed: () {
                controller.clear();
                onChanged?.call('');
              },
            );
          },
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),
    );
  }
}
