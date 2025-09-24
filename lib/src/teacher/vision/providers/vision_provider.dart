import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';
import '../models/vision_model.dart';
import '../services/vision_services.dart';

class VisionProvider with ChangeNotifier {
  final TeacherVisionAPIService _apiService = TeacherVisionAPIService();

  // ----------------- Video Lists -----------------
  final List<TeacherVisionVideo> _allVideos = [];
  final List<TeacherVisionVideo> _assignedVideos = [];
  List<TeacherVisionVideo> filteredNonAssignedVideos = [];
  List<TeacherVisionVideo> filteredAssignedVideos = [];
  // ----------------- Filters -----------------
  final String _gradeId;
  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _allLevelsData = [];
  List<Map<String, dynamic>> _subjects = [];

  String? _selectedChapterId;
  String? _selectedLevelId;
  String? _selectedSubjectId;
  String? _selectedSubjectTitle;
  String _searchQuery = '';
  bool _isSubjectsLoading = false;
  bool get isSubjectsLoading => _isSubjectsLoading;

  // ----------------- Loading & Pagination -----------------
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMoreAllVideos = true;
  bool _hasMoreAssignedVideos = true;

  int _searchPage = 1;
  bool _hasMoreSearchVideos = true;

  List<String> _availableLevels = [];

  // ----------------- Getters -----------------
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get subjects => _subjects;
  List<Map<String, dynamic>> get chapters => _chapters;
  bool get hasMoreAllVideos => _hasMoreAllVideos;
  bool get hasMoreAssignedVideos => _hasMoreAssignedVideos;
  List<String> get availableLevels => _availableLevels;
  List<Map<String, dynamic>> getAvailableSubjects() => _subjects;
  String? get selectedSubjectTitle => _selectedSubjectTitle;

  // ----------------- Constructor -----------------
  VisionProvider({required String gradeId}) : _gradeId = gradeId {
    _initializeData();
  }

  // ----------------- Initialization -----------------
  Future<void> _initializeData() async {
    await _fetchSubjects();
    await _fetchLevels();
    await fetchChapters();

    final hasCache = await _loadCachedVideos();
    if (!hasCache) {
      await _fetchVideos();
    } else {
      _applyFilters();
    }
  }

  // ----------------- Fetch Subjects -----------------
  Future<void> _fetchSubjects() async {
    _isSubjectsLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    try {
      _subjects = await _apiService.getSubjects();
      await prefs.setString('cached_subjects', jsonEncode(_subjects));
    } catch (_) {
      final cached = prefs.getString('cached_subjects');
      if (cached != null) {
        _subjects = List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    }

    _isSubjectsLoading = false;
    notifyListeners();
  }

  List<String> getAvailableSubjectTitles() {
    return _subjects
        .map((s) => (s['name'] ?? s['title'] ?? '').toString())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  // ----------------- Fetch Levels -----------------
  Future<void> _fetchLevels() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _allLevelsData = await _apiService.getAllLevels();
      await prefs.setString('cached_levels', jsonEncode(_allLevelsData));

      _availableLevels = _allLevelsData
          .map((level) => level['title']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      _availableLevels.sort();
    } catch (_) {
      final cached = prefs.getString('cached_levels');
      if (cached != null) {
        _allLevelsData = List<Map<String, dynamic>>.from(jsonDecode(cached));
        _availableLevels = _allLevelsData
            .map((level) => level['title']?.toString() ?? '')
            .toList();
      }
    }
    notifyListeners();
  }

  // ----------------- Fetch Chapters -----------------
  Future<void> fetchChapters() async {
    try {
      _chapters = await _apiService.getChapters(
        gradeId: _gradeId,
        subjectId: _selectedSubjectId,
      );
    } catch (_) {
      _chapters = [];
    }
    notifyListeners();
  }

  // ----------------- Cached Videos -----------------
  Future<bool> _loadCachedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedAll = prefs.getString('cached_all_videos');
    final cachedAssigned = prefs.getString('cached_assigned_videos');

    if (cachedAll != null) {
      _allVideos.clear();
      _allVideos.addAll(
        (jsonDecode(cachedAll) as List)
            .map((e) => TeacherVisionVideo.fromJson(e)),
      );
    }

    if (cachedAssigned != null) {
      _assignedVideos.clear();
      _assignedVideos.addAll(
        (jsonDecode(cachedAssigned) as List)
            .map((e) => TeacherVisionVideo.fromJson(e)),
      );
    }

    notifyListeners();
    return cachedAll != null || cachedAssigned != null;
  }

  // ----------------- Auth Helper -----------------
  Future<String> _getAuthToken() async => StorageUtil.getString(StringHelper.token);

  // ----------------- Fetch Videos -----------------
  Future<void> _fetchVideos({bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (loadMore && !_hasMoreAllVideos) return;

    if (!loadMore) {
      _isLoading = true;
      _currentPage = 1;
      _allVideos.clear();
      _assignedVideos.clear();
    } else {
      _isLoadingMore = true;
      _currentPage++;
    }
    notifyListeners();

    try {
      // Find level ID from selectedLevel title
      final levelId = _selectedLevelId != null
          ? _allLevelsData.firstWhere(
              (lvl) => lvl['title'] == _selectedLevelId,
          orElse: () => {})['id']
          ?.toString()
          : null;

      final newAll = await _apiService.getAllVisionVideos(
        subjectId: _selectedSubjectId,
        levelId: levelId,
        chapterId: _selectedChapterId,
        page: _currentPage,
        perPage: _perPage,
      );

      final newAssigned = await _apiService.getAssignedVideos(
        subjectId: _selectedSubjectId,
        levelId: levelId,
        chapterId: _selectedChapterId,
      ).then((list) => list.map((v) {
        v.teacherAssigned = true;
        return v;
      }).toList());

      _allVideos.addAll(newAll);
      _assignedVideos.addAll(newAssigned);

      _hasMoreAllVideos = newAll.length >= _perPage;
      _hasMoreAssignedVideos = newAssigned.length >= _perPage;

      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to fetch videos: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ----------------- Search -----------------
  Future<void> _fetchSearchVideos({bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (loadMore && !_hasMoreSearchVideos) return;

    if (!loadMore) {
      _isLoading = true;
      _searchPage = 1;
      _hasMoreSearchVideos = true;
      _allVideos.clear();
    } else {
      _isLoadingMore = true;
      _searchPage++;
    }

    try {
      final authToken = await _getAuthToken();

      final levelId = _selectedLevelId != null
          ? _allLevelsData.firstWhere(
              (lvl) => lvl['title'] == _selectedLevelId,
          orElse: () => {})['id']
          ?.toString()
          : null;

      final results = await _apiService.searchVisionVideos(
        subjectId: _selectedSubjectId,
        levelId: levelId,
        chapterId: _selectedChapterId,
        searchTitle: _searchQuery,
        page: _searchPage,
        perPage: _perPage,
        authToken: authToken,
      );

      _allVideos.addAll(results);
      _hasMoreSearchVideos = results.length >= _perPage;
      _applyFilters();
    } catch (_) {}
    finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ----------------- Filters -----------------
  void setSubjectFilter(String? subjectTitle) {
    if (subjectTitle == null || subjectTitle.isEmpty) {
      _selectedSubjectId = null;
      _selectedSubjectTitle = null;
      _selectedChapterId = null;
      _currentPage = 1;
      _allVideos.clear();
      _assignedVideos.clear();
      _fetchVideos();
      return;
    }

    _selectedSubjectTitle = subjectTitle.trim();

    // Normalize subject names for matching (ignore case, parentheses, spaces)
    final normalizedSubject = subjectTitle.replaceAll(RegExp(r'\([^)]*\)'), '').trim().toLowerCase();

    final match = _subjects.firstWhere(
          (s) {
        final name = (s['name'] ?? s['title'] ?? '').toString();
        final normalizedName = name.replaceAll(RegExp(r'\([^)]*\)'), '').trim().toLowerCase();
        return normalizedName == normalizedSubject;
      },
      orElse: () => <String, dynamic>{}, // empty map if no match
    );

    _selectedSubjectId = match['id']?.toString();

    debugPrint('Selected Subject: $_selectedSubjectTitle, ID: $_selectedSubjectId');

    // Reset dependent filters
    _selectedChapterId = null;
    _currentPage = 1;
    _allVideos.clear();
    _assignedVideos.clear();

    fetchChapters(); // refresh chapters based on subject
    _fetchVideos();
  }

  void setLevelFilter(String? levelTitle) {
    _selectedLevelId = levelTitle; // store title for dropdown
    _currentPage = 1;
    _fetchVideos();
  }

  void setChapterFilter(String? chapterId) {
    _selectedChapterId = chapterId;
    _currentPage = 1;
    _fetchVideos();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _fetchVideos();
    } else {
      _fetchSearchVideos();
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedSubjectId = null;
    _selectedChapterId = null; // ← important
    _currentPage = 1;
    _hasMoreAllVideos = true;
    _hasMoreAssignedVideos = true;
    _allVideos.clear();
    _assignedVideos.clear();
    _fetchVideos();
  }

  // ----------------- Apply Filters -----------------
  void _applyFilters() {
    debugPrint('--- Applying filters ---');
    debugPrint('SubjectID: $_selectedSubjectId, LevelID: $_selectedLevelId, ChapterID: $_selectedChapterId, Search: $_searchQuery');

    filteredNonAssignedVideos = _allVideos.where((video) {
      final videoSubjectId = video.subjectInfo?.id?.toString() ?? '';
      final videoLevelId = video.level.toString() ?? '';
      final videoTitle = video.title.toLowerCase();
      final videoDescription = video.description.toLowerCase();
      final videoChapterIds = video.chapters?.map((c) => c.id.toString()).toList() ?? [];

      final matchesSubject = _selectedSubjectId == null || _selectedSubjectId!.isEmpty || videoSubjectId == _selectedSubjectId;
      final matchesLevel = _selectedLevelId == null || _selectedLevelId!.isEmpty || videoLevelId == _selectedLevelId;
      final matchesChapter = _selectedChapterId == null || _selectedChapterId!.isEmpty || videoChapterIds.contains(_selectedChapterId);
      final matchesSearch = _searchQuery.isEmpty || videoTitle.contains(_searchQuery.toLowerCase()) || videoDescription.contains(_searchQuery.toLowerCase());

      final include = !video.teacherAssigned && matchesSubject && matchesLevel && matchesChapter && matchesSearch;

      debugPrint('Video: ${video.title} | SubjectID: $videoSubjectId, LevelID: $videoLevelId, Chapters: $videoChapterIds | Include: $include');
      return include;
    }).toList();

    filteredAssignedVideos = _assignedVideos.where((video) {
      final videoSubjectId = video.subjectInfo?.id?.toString() ?? '';
      final videoLevelId = video.level.toString() ?? '';
      final videoTitle = video.title.toLowerCase();
      final videoDescription = video.description.toLowerCase();
      final videoChapterIds = video.chapters?.map((c) => c.id.toString()).toList() ?? [];

      final matchesSubject = _selectedSubjectId == null || _selectedSubjectId!.isEmpty || videoSubjectId == _selectedSubjectId;
      final matchesLevel = _selectedLevelId == null || _selectedLevelId!.isEmpty || videoLevelId == _selectedLevelId;
      final matchesChapter = _selectedChapterId == null || _selectedChapterId!.isEmpty || videoChapterIds.contains(_selectedChapterId);
      final matchesSearch = _searchQuery.isEmpty || videoTitle.contains(_searchQuery.toLowerCase()) || videoDescription.contains(_searchQuery.toLowerCase());

      final include = video.teacherAssigned && matchesSubject && matchesLevel && matchesChapter && matchesSearch;

      debugPrint('Assigned Video: ${video.title} | SubjectID: $videoSubjectId, LevelID: $videoLevelId, Chapters: $videoChapterIds | Include: $include');
      return include;
    }).toList();

    debugPrint('Filtered videos count: nonAssigned=${filteredNonAssignedVideos.length}, assigned=${filteredAssignedVideos.length}');
    notifyListeners();
  }

  // ----------------- Video Access -----------------
  TeacherVisionVideo? getVideoById(String videoId) {
    try {
      return _allVideos.firstWhere(
            (v) => v.id == videoId,
        orElse: () => _assignedVideos.firstWhere((v) => v.id == videoId),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadMoreVideos() async =>
      _searchQuery.isEmpty ? _fetchVideos(loadMore: true) : _fetchSearchVideos(loadMore: true);
  Future<void> refreshVideos() async => _fetchVideos();
  // ----------------- Assignment -----------------
  Future<bool> assignVideoToStudents(String videoId, List<String> studentIds, {String? dueDate}) async {
    try {
      final success = await _apiService.assignVideoToStudents(videoId: videoId, studentIds: studentIds, dueDate: dueDate);
      if (success) await _fetchVideos();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unassignVideo(String assignmentId) async {
    try {
      final success = await _apiService.unassignVision(assignmentId);
      if (success) await _fetchVideos();
      return success;
    } catch (_) {
      return false;
    }
  }

  // ----------------- Other API Helpers -----------------
  Future<List<Map<String, dynamic>>> getVisionParticipants(String visionId, String selectedClassFilter) async {
    try {
      return await _apiService.getVisionParticipants(visionId, selectedClassFilter);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsForAssignment(Map<String, dynamic> data) async {
    try {
      return await _apiService.getStudentsForAssignment(data);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStudentProgress(String assignmentId) async {
    try {
      return await _apiService.getStudentProgress(assignmentId);
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getVisionDetails(String visionId) async {
    try {
      return await _apiService.getVisionDetails(visionId);
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getSubmissionStatus(String visionCompleteId, dynamic newStatus) async {
    try {
      return await _apiService.getSubmissionStatus(visionCompleteId, newStatus);
    } catch (_) {
      return {};
    }
  }
}
