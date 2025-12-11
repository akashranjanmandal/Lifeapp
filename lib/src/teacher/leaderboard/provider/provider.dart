import 'package:flutter/material.dart';
import '../services/services.dart';
import '../model/model.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _service;

  List<LeaderboardEntry> teachers = [];
  List<LeaderboardEntry> schools = [];

  bool isLoadingTeachers = false;
  bool isLoadingSchools = false;

  bool isLoadMoreTeachers = false;
  bool isLoadMoreSchools = false;

  int teacherPage = 1;
  int schoolPage = 1;
  final int limit = 20;

  String currentFilter = 'monthly';

  bool hasMoreTeachers = true;
  bool hasMoreSchools = true;

  String? errorTeachers;
  String? errorSchools;

  LeaderboardProvider(String token) : _service = LeaderboardService(token);

  void setFilter(String filter) {
    currentFilter = _normalizeFilter(filter);
    teacherPage = 1;
    schoolPage = 1;
    hasMoreTeachers = true;
    hasMoreSchools = true;
    teachers.clear();
    schools.clear();
    notifyListeners();
  }

  String _normalizeFilter(String filter) {
    switch (filter.toLowerCase()) {
      case 'monthly':
        return 'monthly';
      case '3 months':
      case 'quarterly':
        return 'quarterly';
      case '6 months':
      case 'halfyearly':
        return 'halfyearly';
      case '1 year':
      case 'yearly':
        return 'yearly';
      default:
        return 'monthly';
    }
  }

  Future<void> loadTeacherLeaderboard({bool loadMore = false}) async {
    if (loadMore && !hasMoreTeachers) return;

    if (!loadMore) {
      teacherPage = 1;
      hasMoreTeachers = true;
      teachers.clear();
      isLoadingTeachers = true;
    } else {
      isLoadMoreTeachers = true;
      teacherPage++;
    }

    errorTeachers = null;
    notifyListeners();

    try {
      final result = await _service.fetchTeacherLeaderboard(
        filter: currentFilter,
        page: teacherPage,
        limit: limit,
      );

      if (result.isEmpty) {
        hasMoreTeachers = false;
      } else {
        if (loadMore) {
          teachers.addAll(result);
        } else {
          teachers = result;
        }
      }
    } catch (e) {
      errorTeachers = e.toString();
      if (loadMore) {
        teacherPage--;
      }
    } finally {
      isLoadingTeachers = false;
      isLoadMoreTeachers = false;
      notifyListeners();
    }
  }

  Future<void> loadSchoolLeaderboard({bool loadMore = false}) async {
    if (loadMore && !hasMoreSchools) return;

    if (!loadMore) {
      schoolPage = 1;
      hasMoreSchools = true;
      schools.clear();
      isLoadingSchools = true;
    } else {
      isLoadMoreSchools = true;
      schoolPage++;
    }

    errorSchools = null;
    notifyListeners();

    try {
      final result = await _service.fetchSchoolLeaderboard(
        filter: currentFilter,
        page: schoolPage,
        limit: limit,
      );

      if (result.isEmpty) {
        hasMoreSchools = false;
      } else {
        if (loadMore) {
          schools.addAll(result);
        } else {
          schools = result;
        }
      }
    } catch (e) {
      errorSchools = e.toString();
      if (loadMore) {
        schoolPage--;
      }
    } finally {
      isLoadingSchools = false;
      isLoadMoreSchools = false;
      notifyListeners();
    }
  }
}