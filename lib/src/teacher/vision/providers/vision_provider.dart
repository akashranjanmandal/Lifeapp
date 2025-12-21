import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';
import '../models/vision_model.dart';
import '../services/vision_services.dart';

class TeacherVisionProvider with ChangeNotifier {
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
  List<Map<String, dynamic>> _boards = [];

  String? _selectedChapterId;
  String? _selectedLevelId;
  String? _selectedSubjectId;
  String? _selectedSubjectTitle;
  String? _selectedBoardId;
  String? _selectedBoardTitle;
  String _searchQuery = '';

  // ----------------- Loading States -----------------
  bool _isSubjectsLoading = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingChapters = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ----------------- Pagination -----------------
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
  bool get isSubjectsLoading => _isSubjectsLoading;
  bool get isLoadingChapters => _isLoadingChapters;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get subjects => _subjects;
  List<Map<String, dynamic>> get chapters => _chapters;
  List<Map<String, dynamic>> get boards => _boards;
  bool get hasMoreAllVideos => _hasMoreAllVideos;
  bool get hasMoreAssignedVideos => _hasMoreAssignedVideos;
  List<String> get availableLevels => _availableLevels;
  List<Map<String, dynamic>> getAvailableSubjects() => _subjects;
  String? get selectedSubjectTitle => _selectedSubjectTitle;
  String? get selectedBoardId => _selectedBoardId;
  String? get selectedBoardTitle => _selectedBoardTitle;

  // ----------------- Constructor -----------------
  TeacherVisionProvider({required String gradeId}) : _gradeId = gradeId {
    _initializeData();
  }

  // ----------------- Initialization -----------------
  Future<void> _initializeData() async {
    try {
      // Load cached data first for immediate display
      await _loadCachedVideos();

      // Fetch boards, subjects, levels in parallel
      await Future.wait([
        _fetchBoards().catchError((e) => debugPrint('❌ Boards fetch failed: $e')),
        _fetchSubjects().catchError((e) => debugPrint('❌ Subjects fetch failed: $e')),
        _fetchLevels().catchError((e) => debugPrint('❌ Levels fetch failed: $e')),
      ], eagerError: false);

      // Fetch fresh videos BEFORE marking as initialized
      await _fetchVideos();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing data: $e');
      _errorMessage = 'Failed to initialize some data, but you can still browse videos';
      _isInitialized = true;
      notifyListeners();
    }
  }
  // ----------------- Fetch Boards -----------------
  Future<void> _fetchBoards() async {
    try {
      _boards = await _apiService.getBoards();
      debugPrint('✅ Successfully fetched ${_boards.length} boards');
    } catch (e) {
      debugPrint('❌ Error fetching boards: $e');
      _boards = [];
    }
  }

  // ----------------- Fetch Subjects -----------------
  Future<void> _fetchSubjects() async {
    _isSubjectsLoading = true;
    notifyListeners();

    try {
      _subjects = await _apiService.getSubjects();
    } catch (e) {
      debugPrint('❌ Error fetching subjects: $e');
      _subjects = [];
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
    try {
      _allLevelsData = await _apiService.getAllLevels();
      _availableLevels = _allLevelsData
          .map((level) => level['title']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      _availableLevels.sort();
    } catch (e) {
      debugPrint('❌ Error fetching levels: $e');
      _allLevelsData = [];
      _availableLevels = [];
    }
  }

  // ----------------- Fetch Chapters -----------------
  Future<void> fetchChapters() async {
    if (_isLoadingChapters || _selectedBoardTitle == null) return;

    _isLoadingChapters = true;
    notifyListeners();

    try {
      _chapters = await _apiService.getChapters(
        gradeId: _gradeId,
        boardId: _selectedBoardId,
        subjectId: _selectedSubjectId,
      );
      debugPrint('✅ Fetched ${_chapters.length} chapters');
    } catch (e) {
      debugPrint('❌ Error fetching chapters: $e');
      _chapters = [];
    } finally {
      _isLoadingChapters = false;
      notifyListeners();
    }
  }

  // ----------------- Cached Videos -----------------
  Future<void> _loadCachedVideos() async {
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

    _applyFilters();
  }

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

      // Fetch all videos - this is the main content
      final newAll = await _apiService.getAllVisionVideos(
        subjectId: _selectedSubjectId,
        levelId: levelId,
        chapterId: _selectedChapterId,
        page: _currentPage,
        perPage: _perPage,
      );

      // Add to main videos list
      _allVideos.addAll(newAll);
      _hasMoreAllVideos = newAll.length >= _perPage;

      // Try to fetch assigned videos separately - if it fails, continue without them
      try {
        final newAssigned = await _apiService.getAssignedVideos(
          subjectId: _selectedSubjectId,
          levelId: levelId,
          chapterId: _selectedChapterId,
        );

        // Mark assigned videos and add them
        final assignedVideosWithFlag = newAssigned.map((v) {
          v.teacherAssigned = true;
          return v;
        }).toList();

        _assignedVideos.addAll(assignedVideosWithFlag);
        _hasMoreAssignedVideos = newAssigned.length >= _perPage;

        debugPrint("✅ Successfully loaded ${newAssigned.length} assigned videos");

      } catch (assignedError) {
        // If assigned videos fail, log but continue
        debugPrint("⚠️ Assigned videos failed, but continuing with regular videos: $assignedError");
        // You could optionally show a subtle toast here if needed
        // Fluttertoast.showToast(msg: "Assigned videos temporarily unavailable", toastLength: Toast.LENGTH_SHORT);
      }

      _applyFilters();

      // Cache videos
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_all_videos', jsonEncode(_allVideos.map((v) => v.toJson()).toList()));
      await prefs.setString('cached_assigned_videos', jsonEncode(_assignedVideos.map((v) => v.toJson()).toList()));

      debugPrint("✅ Successfully loaded ${newAll.length} regular videos");

    } catch (e) {
      _errorMessage = 'Failed to fetch videos: $e';
      debugPrint('❌ Error in _fetchVideos: $e');

      // Even if there's an error, try to load cached videos
      await _loadCachedVideos();
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
      final authToken = await StorageUtil.getString(StringHelper.token);

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

      debugPrint("✅ Search found ${results.length} videos");

    } catch (e) {
      debugPrint('❌ Error in _fetchSearchVideos: $e');
      // Even on search error, try to show cached results
      _applyFilters();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  // ----------------- Filters -----------------
  void setBoardFilter(String? boardTitle) {
    if (boardTitle == null || boardTitle.isEmpty) {
      _selectedBoardId = null;
      _selectedBoardTitle = null;
    } else {
      _selectedBoardTitle = boardTitle.trim();
      final match = _boards.firstWhere(
            (b) {
          final name = (b['name'] ?? b['title'] ?? '').toString().trim();
          return name.toLowerCase() == boardTitle.toLowerCase();
        },
        orElse: () => <String, dynamic>{},
      );
      _selectedBoardId = match['id']?.toString();
    }

    _selectedChapterId = null;

    // Fetch chapters in background without blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchChapters();
    });
  }

  void setSubjectFilter(String? subjectTitle) {
    if (subjectTitle == null || subjectTitle.isEmpty) {
      _selectedSubjectId = null;
      _selectedSubjectTitle = null;
    } else {
      _selectedSubjectTitle = subjectTitle.trim();
      final normalizedSubject = subjectTitle.replaceAll(RegExp(r'\([^)]*\)'), '').trim().toLowerCase();
      final match = _subjects.firstWhere(
            (s) {
          final name = (s['name'] ?? s['title'] ?? '').toString();
          final normalizedName = name.replaceAll(RegExp(r'\([^)]*\)'), '').trim().toLowerCase();
          return normalizedName == normalizedSubject;
        },
        orElse: () => <String, dynamic>{},
      );
      _selectedSubjectId = match['id']?.toString();
    }

    _selectedChapterId = null;
    _currentPage = 1;

    // Fetch in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchChapters();
      _fetchVideos();
    });
  }

  void setLevelFilter(String? levelTitle) {
    _selectedLevelId = levelTitle;
    _currentPage = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVideos();
    });
  }

  void setChapterFilter(String? chapterId) {
    _selectedChapterId = chapterId;
    _currentPage = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVideos();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchQuery.isEmpty) {
        _fetchVideos();
      } else {
        _fetchSearchVideos();
      }
    });
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedSubjectId = null;
    _selectedSubjectTitle = null;
    _selectedBoardId = null;
    _selectedBoardTitle = null;
    _selectedChapterId = null;
    _selectedLevelId = null;
    _currentPage = 1;
    _hasMoreAllVideos = true;
    _hasMoreAssignedVideos = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVideos();
    });
  }

  // ----------------- Apply Filters -----------------
  void _applyFilters() {
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

      return !video.teacherAssigned && matchesSubject && matchesLevel && matchesChapter && matchesSearch;
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

      return video.teacherAssigned && matchesSubject && matchesLevel && matchesChapter && matchesSearch;
    }).toList();

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
// Add this to TeacherVisionProvider class
  Future<TeacherVisionVideo?> getTeacherVisionVideoDirectly(String visionId) async {
    try {
      debugPrint('🎯 === DEEP LINK: Fetching teacher vision video directly ===');
      debugPrint('📱 Vision ID from deep link: "$visionId"');

      // First, check if we already have the video in our cached lists
      final cachedVideo = getVideoById(visionId);
      if (cachedVideo != null) {
        debugPrint('✅ SUCCESS: Video found in cache: "${cachedVideo.title}"');
        return cachedVideo;
      }

      debugPrint('🔄 Video not in cache, fetching directly from API...');

      // Fetch video directly from API (same pattern as student provider)
      final video = await _apiService.getVisionVideoById(visionId);

      if (video != null) {
        debugPrint('✅ SUCCESS: Video fetched from API: "${video.title}"');

        // Add to current videos list if not already present (same as student provider)
        if (!_allVideos.any((v) => v.id == video.id)) {
          _allVideos.add(video);
          _applyFilters();

          // Update cache for future use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'cached_all_videos',
              jsonEncode(_allVideos.map((v) => v.toJson()).toList())
          );

          debugPrint('💾 Video added to cache for future use');
        }

        return video;
      } else {
        debugPrint('❌ FAILED: Video not found with ID: "$visionId"');

        // Fallback: Try to search through existing videos
        debugPrint('🔄 Trying fallback: searching through existing videos...');
        return await _findVideoWithFallback(visionId);
      }
    } catch (e, stackTrace) {
      debugPrint('💥 ERROR in getTeacherVisionVideoDirectly: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

// Enhanced fallback method
  Future<TeacherVisionVideo?> _findVideoWithFallback(String visionId) async {
    try {
      // Clear filters and fetch fresh data
      _searchQuery = '';
      _selectedSubjectId = null;
      _selectedSubjectTitle = null;
      _selectedLevelId = null;
      _selectedChapterId = null;
      _selectedBoardId = null;
      _selectedBoardTitle = null;
      _currentPage = 1;

      debugPrint('🔄 Fetching fresh videos without filters...');
      await _fetchVideos();

      // Check again after fresh fetch
      final freshVideo = getVideoById(visionId);
      if (freshVideo != null) {
        debugPrint('✅ SUCCESS: Video found after fresh fetch: "${freshVideo.title}"');
        return freshVideo;
      }

      debugPrint('❌ Video still not found after fallback');
      return null;
    } catch (e) {
      debugPrint('❌ Fallback method failed: $e');
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