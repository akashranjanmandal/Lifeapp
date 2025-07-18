import 'package:flutter/material.dart';
import '../services/services.dart';
import '../model/model.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _service;

  List<LeaderboardEntry> teachers = [];
  List<LeaderboardEntry> schools = [];

  bool isLoadingTeachers = false;
  bool isLoadingSchools = false;

  bool hasMoreTeachers = true;
  bool hasMoreSchools = true;

  int _teacherPage = 1;
  int _schoolPage = 1;

  String? errorTeachers;
  String? errorSchools;

  LeaderboardProvider(String token) : _service = LeaderboardService(token);

  Future<void> loadTeacherLeaderboard({bool loadMore = false}) async {
    if (loadMore && !hasMoreTeachers) return;

    if (!loadMore) {
      _teacherPage = 1;
      hasMoreTeachers = true;
      teachers.clear();
    }

    isLoadingTeachers = true;
    errorTeachers = null;
    notifyListeners();

    try {
      final result = await _service.fetchTeacherLeaderboard(page: _teacherPage);
      if (result.isEmpty) {
        hasMoreTeachers = false;
      } else {
        teachers.addAll(result);
        _teacherPage++;
      }
    } catch (e) {
      errorTeachers = e.toString();
    } finally {
      isLoadingTeachers = false;
      notifyListeners();
    }
  }

  Future<void> loadSchoolLeaderboard({bool loadMore = false}) async {
    if (loadMore && !hasMoreSchools) return;

    if (!loadMore) {
      _schoolPage = 1;
      hasMoreSchools = true;
      schools.clear();
    }

    isLoadingSchools = true;
    errorSchools = null;
    notifyListeners();

    try {
      final result = await _service.fetchSchoolLeaderboard(page: _schoolPage);
      if (result.isEmpty) {
        hasMoreSchools = false;
      } else {
        schools.addAll(result);
        _schoolPage++;
      }
    } catch (e) {
      errorSchools = e.toString();
    } finally {
      isLoadingSchools = false;
      notifyListeners();
    }
  }
}
