import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'jw/models/jw_models.dart';
import 'jwapp/schedule/semester_config.dart';

/// Parses persisted schedule data before schedule tabs are first opened.
class ScheduleCacheBootstrap {
  static Future<void>? _loading;
  static final Map<int, List<dynamic>> jwappSchedules = {};
  static final Map<int, JwScheduleData> jwSchedules = {};
  static List<JwSemesterInfo>? jwSemesters;
  static int? jwSelectedSemesterId;
  static int? jwSelectedWeek;
  static int? jwCurrentSemesterId;

  static Future<void> preload() => _loading ??= _preload();

  static Future<void> _preload() async {
    await SemesterConfig.loadDiskCache();
    final prefs = await SharedPreferences.getInstance();

    for (final key in prefs.getKeys()) {
      if (key.startsWith('jwapp_schedule_cache_')) {
        final id = int.tryParse(key.substring('jwapp_schedule_cache_'.length));
        final raw = prefs.getString(key);
        if (id == null || raw == null) continue;
        try {
          jwappSchedules[id] = jsonDecode(raw) as List<dynamic>;
        } catch (_) {}
      } else if (key.startsWith('jw_sys_schedule_cache_')) {
        final id = int.tryParse(key.substring('jw_sys_schedule_cache_'.length));
        final raw = prefs.getString(key);
        if (id == null || raw == null) continue;
        try {
          jwSchedules[id] = JwScheduleData.fromJson(jsonDecode(raw));
        } catch (_) {}
      }
    }

    final semestersRaw = prefs.getString('jw_sys_semesters_cache');
    if (semestersRaw != null) {
      try {
        final seen = <int>{};
        jwSemesters = (jsonDecode(semestersRaw) as List)
            .whereType<Map>()
            .map(
              (item) =>
                  JwSemesterInfo.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((semester) => seen.add(semester.id))
            .toList();
      } catch (_) {}
    }

    jwSelectedSemesterId = prefs.getInt('jw_sys_selected_sem_id');
    jwSelectedWeek = prefs.getInt('jw_sys_selected_week');
    jwCurrentSemesterId = prefs.getInt('jw_sys_current_sem_id');
  }
}
