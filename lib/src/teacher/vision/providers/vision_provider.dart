import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';
import '../models/vision_model.dart';
import '../services/vision_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisionProvider with ChangeNotifier {
  final TeacherVisionAPIService _apiService = TeacherVisionAPIService();

  final List<TeacherVisionVideo> _allVideos = [];
  final List<TeacherVisionVideo> _assignedVideos = [];

  List<TeacherVisionVideo> filteredNonAssignedVideos = [];
  List<TeacherVisionVideo> filteredAssignedVideos = [];

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _allLevelsData = [];
  String? _selectedLevelId;
  String _subjectFilter = '';
  String _levelFilter = '';
  String _searchQuery = '';
  String? _selectedSubjectId;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  final int _perPage = 10;

  bool _hasMoreAllVideos = true;
  bool _hasMoreAssignedVideos = true;

  bool _hasLoadedFromCache = false;

  List<String> _availableLevels = [];

  // --- NEW for backend search ---
  int _searchPage = 1;
  bool _hasMoreSearchVideos = true;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get subjects => _subjects;
  bool get hasMoreAllVideos => _hasMoreAllVideos;
  bool get hasMoreAssignedVideos => _hasMoreAssignedVideos;
  List<String> get availableLevels => _availableLevels;

  VisionProvider() {
    _initializeData();
  }

  // Initialization: load subjects, load cached videos or fetch fresh
  Future<void> _initializeData() async {
    await _fetchSubjects();
    await _fetchLevels(); // Load levels from the dedicated endpoint

    if (!_hasLoadedFromCache) {
      final hasCache = await _loadCachedVideos();
      _hasLoadedFromCache = true;
      if (!hasCache) {
        await _fetchVideos();
      } else {
        _applyFilters();
      }
    } else {
      await _fetchVideos();
    }
}
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching levels: $e');
      final cached = prefs.getString('cached_levels');
      if (cached != null) {
        _allLevelsData = List<Map<String, dynamic>>.from(jsonDecode(cached));
        _availableLevels = _allLevelsData
            .map((level) => level['title']?.toString() ?? '')
            .toList();
        notifyListeners();
      }
    }
  }
  // Load cached videos if any
  Future<bool> _loadCachedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedAll = prefs.getString('cached_all_videos');
    final cachedAssigned = prefs.getString('cached_assigned_videos');

    if (cachedAll != null) {
      final List<dynamic> jsonData = jsonDecode(cachedAll);
      _allVideos.clear();
      _allVideos.addAll(jsonData.map((e) => TeacherVisionVideo.fromJson(e)));
    }

    if (cachedAssigned != null) {
      final List<dynamic> jsonData = jsonDecode(cachedAssigned);
      _assignedVideos.clear();
      _assignedVideos.addAll(jsonData.map((e) => TeacherVisionVideo.fromJson(e)));
    }

    notifyListeners();
    return cachedAll != null || cachedAssigned != null;
  }

  // Fetch subjects from API or fallback to cache
  Future<void> _fetchSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _subjects = await _apiService.getSubjects();
      await prefs.setString('cached_subjects', jsonEncode(_subjects));
    } catch (e) {
      debugPrint('❌ Error fetching subjects: $e');
      final cached = prefs.getString('cached_subjects');
      if (cached != null) {
        _subjects = List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    }
    notifyListeners();
  }

  // --- UPDATED _fetchVideos ---
  Future<void> _fetchVideos({bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (loadMore && (_isLoadingMore || (!_hasMoreAllVideos && !_hasMoreAssignedVideos))) return;

    if (!loadMore) {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreAllVideos = true;
      _hasMoreAssignedVideos = true;
      _allVideos.clear();
      _assignedVideos.clear();
    } else {
      _isLoadingMore = true;
      _currentPage++;
    }
    notifyListeners();

    try {
      debugPrint('🔄 Fetching all videos...');
      final newAllVideos = await _fetchAllVideosPage();
      debugPrint('✅ Fetched ${newAllVideos.length} all videos');

      debugPrint('🔄 Fetching assigned videos...');
      final newAssignedVideos = await _fetchAssignedVideosPage();
      debugPrint('✅ Fetched ${newAssignedVideos.length} assigned videos');

      // Mark all assigned videos explicitly
      final markedAssignedVideos = newAssignedVideos.map((v) {
        v.teacherAssigned = true;
        return v;
      }).toList();

      _allVideos.addAll(newAllVideos);
      _assignedVideos.addAll(markedAssignedVideos);

      _hasMoreAllVideos = newAllVideos.length >= _perPage;
      _hasMoreAssignedVideos = markedAssignedVideos.length >= _perPage;

      debugPrint('📊 Total videos after merge:');
      debugPrint('- All videos: ${_allVideos.length}');
      debugPrint('- Assigned videos: ${_assignedVideos.length}');

      _applyFilters();
    } catch (e) {
      debugPrint('❌ Error in _fetchVideos: $e');
      _errorMessage = 'Failed to load videos. Please try again.';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  Future<String> _getAuthToken() async {
    return StorageUtil.getString(StringHelper.token);
  }
  Future<void> fetchAllLevels() async {
    try {
      // 1. Get levels from API
      _allLevelsData = await _apiService.getAllLevels();

      // 2. Extract level names (using 'title' field from API response)
      _availableLevels = _allLevelsData
          .map((level) => level['title']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      // 3. Sort alphabetically
      _availableLevels.sort();

      debugPrint('Loaded ${_availableLevels.length} fixed levels from API');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading fixed levels: $e');
      // Fallback empty list
      _availableLevels = [];
      notifyListeners();
    }
  }

  Future<void> _fetchSearchVideos({bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (loadMore && (_isLoadingMore || !_hasMoreSearchVideos)) return;

    if (!loadMore) {
      _isLoading = true;
      _searchPage = 1;
      _hasMoreSearchVideos = true;
      _allVideos.clear();
    } else {
      _isLoadingMore = true;
      _searchPage++;
    }
    notifyListeners();

    try {
      final authToken = await _getAuthToken();

      final searchResults = await _apiService.searchVisionVideos(
        subjectId: _selectedSubjectId,
        levelId: _levelFilter,
        searchTitle: _searchQuery,
        page: _searchPage,
        perPage: _perPage,
        authToken: authToken,
      );

      _allVideos.addAll(searchResults);
      _hasMoreSearchVideos = searchResults.length >= _perPage;
      _applyFilters();
    } catch (e) {
      debugPrint('❌ Error searching videos: $e');
      _errorMessage = 'Search failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Fetch one page of all videos, filtered by subject & level if any
  Future<List<TeacherVisionVideo>> _fetchAllVideosPage() async {
    if (!_hasMoreAllVideos && _currentPage > 1) return [];
    List<TeacherVisionVideo> videos;

    if (_selectedSubjectId != null) {
      videos = await _apiService.getVisionVideosBySubject(
        _selectedSubjectId!,
        levelId: _selectedLevelId,
        page: _currentPage,
        perPage: _perPage,
      );
    } else {
      videos = await _apiService.getAllVisionVideos(
        levelId: _selectedLevelId,
        page: _currentPage,
        perPage: _perPage,
      );
    }

    debugPrint('[_fetchAllVideosPage] SubjectId: $_selectedSubjectId, Videos fetched: ${videos.length}');
    return videos;
  }

  // Fetch one page of assigned videos (if API supports filtering by subject and level)
  Future<List<TeacherVisionVideo>> _fetchAssignedVideosPage() async {
    if (!_hasMoreAssignedVideos && _currentPage > 1) return [];
    return await _apiService.getAssignedVideos(
      subjectId: _selectedSubjectId,
      levelId: _levelFilter.isNotEmpty ? _levelFilter : null,
    );
  }

  // Load more videos pagination
  Future<void> loadMoreVideos() async {
    await _fetchVideos(loadMore: true);
  }
// Fetch all available levels independently of selected subject

  // Filter and search applied here, called after every fetch or filter change
  void _applyFilters() {
    // Filter non-assigned videos
    filteredNonAssignedVideos = _allVideos.where((video) {
      // Convert all strings to lowercase for case-insensitive comparison
      final videoSubject = video.subject?.toLowerCase() ?? '';
      final videoLevel = video.level?.toLowerCase() ?? '';
      final videoTitle = video.title.toLowerCase();
      final videoDescription = video.description.toLowerCase();

      final subjectFilter = _subjectFilter.toLowerCase();
      final levelFilter = _levelFilter.toLowerCase();
      final searchQuery = _searchQuery.toLowerCase();

      // Check subject match
      final matchesSubject = _subjectFilter.isEmpty ||
          videoSubject.contains(subjectFilter);

      // Check level match
      final matchesLevel = _levelFilter.isEmpty ||
          videoLevel.contains(levelFilter);

      // Check search text match
      final matchesSearch = _searchQuery.isEmpty ||
          videoTitle.contains(searchQuery) ||
          videoDescription.contains(searchQuery);

      // Must be non-assigned AND match all active filters
      return !video.teacherAssigned &&
          matchesSubject &&
          matchesLevel &&
          matchesSearch;
    }).toList();

    // Filter assigned videos
    filteredAssignedVideos = _assignedVideos.where((video) {
      final videoSubject = video.subject?.toLowerCase() ?? '';
      final videoLevel = video.level?.toLowerCase() ?? '';
      final videoTitle = video.title.toLowerCase();
      final videoDescription = video.description.toLowerCase();

      final subjectFilter = _subjectFilter.toLowerCase();
      final levelFilter = _levelFilter.toLowerCase();
      final searchQuery = _searchQuery.toLowerCase();

      final matchesSubject = _subjectFilter.isEmpty ||
          videoSubject.contains(subjectFilter);

      final matchesLevel = _levelFilter.isEmpty ||
          videoLevel.contains(levelFilter);

      final matchesSearch = _searchQuery.isEmpty ||
          videoTitle.contains(searchQuery) ||
          videoDescription.contains(searchQuery);

      // Must be assigned AND match all active filters
      return video.teacherAssigned &&
          matchesSubject &&
          matchesLevel &&
          matchesSearch;
    }).toList();

    // IMPORTANT: We don't modify _availableLevels here
    // The levels dropdown maintains its complete list
    notifyListeners();
  }

  // Set subject filter by display name, convert to subject id internally
  void setSubjectFilter(String subject) {
    // Normalize the subject name by removing parentheses and trimming
    String normalizedSubject = subject.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

    debugPrint('Setting subject filter: Original: "$subject", Normalized: "$normalizedSubject"');

    // 1. Update subject filter with normalized name
    _subjectFilter = normalizedSubject;

    // 2. Find matching subject ID (case insensitive and ignoring parentheses)
    _selectedSubjectId = _subjects.firstWhere(
          (s) {
        final name = (s['name'] ?? s['title'])?.toString() ?? '';
        final normalizedName = name.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
        return normalizedName.toLowerCase() == normalizedSubject.toLowerCase();
      },
      orElse: () => {},
    )['id']?.toString();

    debugPrint('Selected Subject ID: $_selectedSubjectId for "$subject"');

    // 3. Reset level selection
    _levelFilter = '';
    _selectedLevelId = null;

    // 4. Refresh videos
    _currentPage = 1;
    _hasMoreAllVideos = true;
    _fetchVideos();
  }  // Set level filter by string
  void setLevelFilter(String levelName) {
    _levelFilter = levelName; // Keep the name for UI display

    // Find the corresponding level ID from _allLevelsData
    final levelData = _allLevelsData.firstWhere(
          (level) => level['title'] == levelName,
      orElse: () => {},
    );

    _selectedLevelId = levelData['id']?.toString();

    _currentPage = 1;
    _hasMoreAllVideos = true;
    _hasMoreAssignedVideos = true;
    _fetchVideos();
  }

  // --- UPDATED setSearchQuery ---
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _fetchVideos();
    } else {
      _fetchSearchVideos();  // Call search API when query is non-empty
    }
  }


  // Clear all filters and refetch
  void clearFilters() {
    _subjectFilter = '';
    _levelFilter = '';
    _searchQuery = '';
    _selectedSubjectId = null;
    _fetchVideos();
  }

  // Public refresh method to force refetch all data
  Future<void> refreshVideos() async {
    await _fetchVideos();
  }

  // Assign video to students
  Future<bool> assignVideoToStudents(String videoId, List<String> studentIds, {String? dueDate}) async {
    try {
      final success = await _apiService.assignVideoToStudents(
        videoId: videoId,
        studentIds: studentIds,
        dueDate: dueDate,
      );
      if (success) {
        await refreshVideos();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error assigning video: $e');
      return false;
    }
  }

  // Unassign a video assignment
  Future<bool> unassignVideo(String assignmentId) async {
    try {
      final success = await _apiService.unassignVision(assignmentId);
      if (success) {
        await refreshVideos();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error unassigning video: $e');
      return false;
    }
  }

  // Fetch participants of a vision
  Future<List<Map<String, dynamic>>> getVisionParticipants(String visionId, String selectedClassFilter) async {
    try {
      return await _apiService.getVisionParticipants(visionId, selectedClassFilter);
    } catch (e) {
      debugPrint('❌ Error fetching vision participants: $e');
      return [];
    }
  }

  // Fetch students for assignment filtering
  Future<List<Map<String, dynamic>>> getStudentsForAssignment(Map<String, dynamic> data) async {
    try {
      return await _apiService.getStudentsForAssignment(data);
    } catch (e) {
      debugPrint('❌ Error fetching students: $e');
      return [];
    }
  }

  // Fetch student progress by assignment id
  Future<Map<String, dynamic>> getStudentProgress(String assignmentId) async {
    try {
      return await _apiService.getStudentProgress(assignmentId);
    } catch (e) {
      debugPrint('❌ Error fetching student progress: $e');
      return {};
    }
  }

  // Fetch vision details by id
  Future<Map<String, dynamic>> getVisionDetails(String visionId) async {
    try {
      return await _apiService.getVisionDetails(visionId);
    } catch (e) {
      debugPrint('❌ Error fetching vision details: $e');
      return {};
    }
  }

  // Update submission status
  Future<Map<String, dynamic>> getSubmissionStatus(String visionCompleteId, dynamic newStatus) async {
    try {
      return await _apiService.getSubmissionStatus(visionCompleteId, newStatus);
    } catch (e) {
      debugPrint('❌ Error updating submission status: $e');
      return {};
    }
  }

  // Get subject name by id
  String getSubjectNameById(String? subjectId) {
    if (subjectId == null || _subjects.isEmpty) return '';
    try {
      final subject = _subjects.firstWhere(
            (s) => s['id']?.toString() == subjectId,
        orElse: () => <String, dynamic>{},
      );
      return subject['name']?.toString() ?? subject['title']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  // Get subject id by name
  String? getSubjectIdByName(String subjectName) {
    if (subjectName.isEmpty || _subjects.isEmpty) return null;
    try {
      final subject = _subjects.firstWhere(
            (s) {
          final name = s['name']?.toString() ?? s['title']?.toString() ?? '';
          return name.toLowerCase() == subjectName.toLowerCase();
        },
        orElse: () => <String, dynamic>{},
      );
      return subject['id']?.toString();
    } catch (e) {
      return null;
    }
  }

  // Get all available subject names for UI dropdowns
  List<String> getAvailableSubjects() {
    if (_subjects.isNotEmpty) {
      return _subjects
          .map((subject) => subject['name']?.toString() ?? subject['title']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
    }
    return _allVideos.map((video) => video.subject).toSet().toList();
  }
}
