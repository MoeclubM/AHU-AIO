import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/getallsemesters.dart';
import '../../globals.dart' as globals;

class SemesterConfig {
  static CurrentSemesterInfo? _currentSemester;
  static List<SemesterInfo>? _allSemesters;

  /// 磁盘缓存 key：内存缓存只在进程内有效，杀进程后离线冷启动
  /// 也必须能拿到学期信息，否则按学期 ID 存取的课表缓存读不出来。
  static const String _currentSemesterDiskKey =
      'jwapp_current_semester_disk_cache';
  static const String _allSemestersDiskKey = 'jwapp_all_semesters_disk_cache';

  /// 获取当前学期信息
  static Future<CurrentSemesterInfo?> getCurrentSemesterInfo() async {
    if (_currentSemester != null) {
      return _currentSemester;
    }

    CurrentSemesterInfo? fetched;
    try {
      fetched = await getCurrentSemester(globals.idToken ?? '');
    } catch (e) {
      fetched = null;
    }

    if (fetched != null) {
      _currentSemester = fetched;
      _persist(_currentSemesterDiskKey, jsonEncode(fetched.toJson()));
      return _currentSemester;
    }

    // 网络失败时回退磁盘缓存
    return _currentSemester = await _readCurrentSemesterFromDisk();
  }

  /// 获取当前学期ID
  static Future<String?> getCurrentSemesterId() async {
    final semester = await getCurrentSemesterInfo();
    return semester?.id.toString();
  }

  /// 获取当前学期名称
  static Future<String> getCurrentSemesterName() async {
    final semester = await getCurrentSemesterInfo();
    return semester?.nameZh ?? '未知学期';
  }

  /// 获取所有学期信息
  static Future<List<SemesterInfo>?> getAllSemesters() async {
    if (_allSemesters != null) {
      return _allSemesters;
    }

    List<SemesterInfo>? fetched;
    try {
      fetched = await getAllSemestersApi(globals.idToken ?? '');
    } catch (e) {
      fetched = null;
    }

    if (fetched != null && fetched.isNotEmpty) {
      _allSemesters = fetched;
      _persist(
        _allSemestersDiskKey,
        jsonEncode(fetched.map((s) => s.toJson()).toList()),
      );
      return _allSemesters;
    }

    // 网络失败时回退磁盘缓存
    return _allSemesters = await _readAllSemestersFromDisk();
  }

  /// 根据ID获取学期信息
  static Future<SemesterInfo?> getSemesterById(int id) async {
    final semesters = await getAllSemesters();
    if (semesters != null) {
      try {
        return semesters.firstWhere((semester) => semester.id == id);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<CurrentSemesterInfo?> _readCurrentSemesterFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currentSemesterDiskKey);
      if (raw == null || raw.isEmpty) return null;
      return CurrentSemesterInfo.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<List<SemesterInfo>?> _readAllSemestersFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_allSemestersDiskKey);
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => SemesterInfo.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> _persist(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      // 持久化失败不影响本次返回
    }
  }
}
