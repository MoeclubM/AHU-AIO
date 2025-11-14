import 'package:flutter/material.dart';
import '../api/getroom.dart';
import '../models/room_model.dart';
import '../../globals.dart' as globals;

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  List<CampusModel> _campuses = [];
  List<BuildingModel> _buildings = [];
  List<RoomModel> _rooms = [];
  CampusModel? _selectedCampus;
  BuildingModel? _selectedBuilding;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    try {
      final campusesData = await RoomApi.getCampuses(globals.idToken!);
      final campuses = campusesData
          .map((data) => CampusModel.fromJson(data))
          .toList();

      setState(() {
        _campuses = campuses;
        if (campuses.isNotEmpty) {
          _selectedCampus = campuses.first;
          _loadBuildings(campuses.first.id);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadBuildings(String campusId) async {
    try {
      final buildingsData = await RoomApi.getBuildings(globals.idToken!, campusAssoc: campusId);
      final buildings = buildingsData
          .map((data) => BuildingModel.fromJson(data))
          .toList();

      setState(() {
        _buildings = buildings;
        _selectedBuilding = buildings.isNotEmpty ? buildings.first : null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _searchRooms() async {
    if (_selectedCampus == null || _selectedBuilding == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filter = RoomFilter(
        campusId: _selectedCampus!.id,
        buildingId: _selectedBuilding!.id,
        date: DateTime.now().toString().substring(0, 10),
      );

      final roomsData = await RoomApi.getRooms(globals.idToken!, filter.toJson());
      final rooms = (roomsData['rooms'] as List? ?? [])
          .map((data) => RoomModel.fromJson(data))
          .toList();

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('空闲教室查询'),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildRoomsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _searchRooms,
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                '校区：',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<CampusModel>(
                  value: _selectedCampus,
                  hint: const Text('选择校区'),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _campuses.map((campus) {
                    return DropdownMenuItem<CampusModel>(
                      value: campus,
                      child: Text(campus.name),
                    );
                  }).toList(),
                  onChanged: (campus) {
                    if (campus != null) {
                      setState(() {
                        _selectedCampus = campus;
                        _rooms.clear();
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
              const Text(
                '建筑：',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<BuildingModel>(
                  value: _selectedBuilding,
                  hint: const Text('选择建筑'),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _buildings.map((building) {
                    return DropdownMenuItem<BuildingModel>(
                      value: building,
                      child: Text(building.name),
                    );
                  }).toList(),
                  onChanged: (building) {
                    if (building != null) {
                      setState(() {
                        _selectedBuilding = building;
                        _rooms.clear();
                      });
                    }
                  },
                ),
              ),
            ],
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
            const Text(
              '请点击搜索按钮查询空闲教室',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final availableSlots = room.getAvailableTimeSlots();
    final isAvailable = availableSlots.isNotEmpty;

    return Card.filled(
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
                    color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.meeting_room,
                    color: isAvailable ? Colors.green.shade600 : Colors.red.shade600,
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
                        '${room.roomType} | 容量: ${room.capacity}人',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAvailable ? '空闲' : '占用',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 12),
              const Text(
                '空闲时段：',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: availableSlots.take(3).map((slot) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}