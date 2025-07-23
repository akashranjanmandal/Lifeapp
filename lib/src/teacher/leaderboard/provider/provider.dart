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

  String? errorTeachers;
  String? errorSchools;

  LeaderboardProvider(String token) : _service = LeaderboardService(token);

  Future<void> loadTeacherLeaderboard({bool loadMore = false}) async {
    if (loadMore && !hasMoreTeachers) return;

    if (!loadMore) {
      hasMoreTeachers = true;
      teachers.clear();
    }

    isLoadingTeachers = true;
    errorTeachers = null;
    notifyListeners();

    try {
      final result = await _service.fetchTeacherLeaderboard();
      if (result.isEmpty) {
        hasMoreTeachers = false;
      } else {
        teachers.addAll(result);
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
      hasMoreSchools = true;
      schools.clear();
    }

    isLoadingSchools = true;
    errorSchools = null;
    notifyListeners();

    try {
      final result = await _service.fetchSchoolLeaderboard();
      if (result.isEmpty) {
        hasMoreSchools = false;
      } else {
        schools.addAll(result);
      }
    } catch (e) {
      errorSchools = e.toString();
    } finally {
      isLoadingSchools = false;
      notifyListeners();
    }
  }
}
