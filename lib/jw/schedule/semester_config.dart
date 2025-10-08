import '../api/getcurrentsemester.dart';
import '../api/getallsemesters.dart';
import '../../globals.dart' as globals;

class SemesterConfig {
  static CurrentSemesterInfo? _currentSemester;
  static List<SemesterInfo>? _allSemesters;

  /// 获取当前学期信息
  static Future<CurrentSemesterInfo?> getCurrentSemesterInfo() async {
    if (_currentSemester == null) {
      try {
        _currentSemester = await getCurrentSemester(globals.idToken ?? '');
      } catch (e) {
        return null;
      }
    }
    return _currentSemester;
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
    if (_allSemesters == null) {
      try {
        _allSemesters = await getAllSemestersApi(globals.idToken ?? '');
      } catch (e) {
        return null;
      }
    }
    return _allSemesters;
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
}