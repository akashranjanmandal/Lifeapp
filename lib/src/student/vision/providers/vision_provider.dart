import 'package:flutter/foundation.dart';
import '../services/vision_services.dart';
import '../models/vision_video.dart';

class VisionProvider with ChangeNotifier {
  final VisionAPIService _apiService = VisionAPIService();

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalVideos = 0;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;
  int _perPage = 10;

  // Search state
  String _searchQuery = '';
  bool _isSearching = false;
  List<VisionVideo> _searchResults = [];
  int _searchCurrentPage = 1;
  int _searchTotalPages = 1;
  int _searchTotalVideos = 0;
  bool _hasNextSearchPage = false;
  bool _isLoadingMoreSearch = false;

  // Filter state
  String _currentFilter = '';
  bool _isFiltering = false;
  List<VisionVideo> _filteredResults = [];
  int _filterCurrentPage = 1;
  int _filterTotalPages = 1;
  int _filterTotalVideos = 0;
  bool _hasNextFilterPage = false;
  bool _isLoadingMoreFilter = false;

  // Existing state
  Map<String, dynamic>? _currentQuestions;
  bool _isLoadingQuestions = false;
  String _questionsError = '';
  List<VisionVideo> _videos = [];
  bool _isLoading = false;
  String _error = '';
  String _searchText = '';
  String? _currentSubjectId;
  String? _currentLevelId;
  Map<String, bool> _activeFilters = {
    'all': false,
    'teacher_assigned': false,
    'skipped': false,
    'pending': false,
    'completed': false,
    'submitted': false,
  };

  // Getters
  Map<String, dynamic>? get currentQuestions => _currentQuestions;
  bool get isLoadingQuestions => _isLoadingQuestions;
  String get questionsError => _questionsError;
  List<VisionVideo> get videos => _videos;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchText => _searchText;
  Map<String, bool> get activeFilters => _activeFilters;

  // Pagination getters
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalVideos => _totalVideos;
  bool get hasNextPage => _hasNextPage;
  bool get isLoadingMore => _isLoadingMore;
  bool get canLoadMore => _hasNextPage && !_isLoadingMore;
  int get perPage => _perPage;

  // Search getters
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  List<VisionVideo> get searchResults => _searchResults;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get canLoadMoreSearch => _hasNextSearchPage && !_isLoadingMoreSearch;
  int get searchTotalVideos => _searchTotalVideos;

  // Filter getters - FIXED NAMES
  String get currentFilter => _currentFilter;
  bool get isFiltering => _isFiltering;
  List<VisionVideo> get filteredResults => _filteredResults;
  bool get hasFilterResults => _filteredResults.isNotEmpty;
  bool get canLoadMoreFilter => _hasNextFilterPage && !_isLoadingMoreFilter;
  int get filterTotalVideos => _filterTotalVideos;

  List<VisionVideo> get filteredVideos {
    // If we have active API filter, return filter results
    if (_currentFilter.isNotEmpty && _isFiltering) {
      return _filteredResults;
    }

    // If we have active API filter results, return them with client-side search
    if (_currentFilter.isNotEmpty && _filteredResults.isNotEmpty) {
      var filtered = _filteredResults;

      // Apply client-side search to filter results
      if (_searchText.isNotEmpty) {
        filtered = filtered.where((video) =>
        video.title.toLowerCase().contains(_searchText.toLowerCase()) ||
            video.description.toLowerCase().contains(_searchText.toLowerCase())
        ).toList();
      }

      return filtered;
    }

    // If we're actively searching or have search results, return search results
    if (_searchQuery.isNotEmpty) {
      return _searchResults;
    }

    // Otherwise, use the original client-side filtering
    var filtered = _videos;

    // Apply client-side search
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((video) =>
      video.title.toLowerCase().contains(_searchText.toLowerCase()) ||
          video.description.toLowerCase().contains(_searchText.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  Future<void> initWithSubject(String subjectId, String? levelId) async {
    _currentSubjectId = subjectId;
    _currentLevelId = levelId;
    _videos = [];
    _searchText = '';
    _searchQuery = '';
    _searchResults = [];
    _currentFilter = '';
    _filteredResults = [];
    _activeFilters = {
      'all': false,
      'teacher_assigned': false,
      'skipped': false,
      'pending': false,
      'completed': false,
      'submitted': false,
    };
    _error = '';
    _currentQuestions = null;
    _questionsError = '';

    // Reset pagination
    _currentPage = 1;
    _totalPages = 1;
    _totalVideos = 0;
    _hasNextPage = false;
    _isLoadingMore = false;

    // Reset search
    _isSearching = false;
    _searchCurrentPage = 1;
    _searchTotalPages = 1;
    _searchTotalVideos = 0;
    _hasNextSearchPage = false;
    _isLoadingMoreSearch = false;

    // Reset filter
    _isFiltering = false;
    _filterCurrentPage = 1;
    _filterTotalPages = 1;
    _filterTotalVideos = 0;
    _hasNextFilterPage = false;
    _isLoadingMoreFilter = false;

    notifyListeners();
    await fetchVideos();
  }

  Future<void> fetchVideos({bool loadMore = false}) async {
    if (_currentSubjectId == null || _currentSubjectId!.isEmpty) {
      _error = 'No subject selected';
      notifyListeners();
      return;
    }

    if (loadMore) {
      if (!_hasNextPage || _isLoadingMore) return;
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _videos = [];
      _error = '';
      _currentFilter = ''; // Clear filter when fetching all videos
    }

    notifyListeners();

    try {
      final response = await _apiService.getVisionVideos(
        _currentSubjectId!,
        _currentLevelId!,
        page: loadMore ? _currentPage + 1 : 1,
        perPage: _perPage,
      );

      if (loadMore) {
        _videos.addAll(response.videos);
        _currentPage = response.currentPage;
      } else {
        _videos = response.videos;
        _currentPage = response.currentPage;
      }

      _totalPages = response.totalPages;
      _totalVideos = response.totalVideos;
      _hasNextPage = response.hasNextPage;
      _error = '';

      debugPrint('✅ Successfully loaded ${response.videos.length} videos (page $_currentPage/$_totalPages)');
    } catch (e) {
      if (!loadMore) {
        _error = _formatErrorMessage(e);
      }
      debugPrint('❌ Error fetching videos: $e');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter(String filter, {bool loadMore = false}) async {
    if (_currentSubjectId == null || _currentSubjectId!.isEmpty) {
      _error = 'No subject selected';
      notifyListeners();
      return;
    }

    if (loadMore) {
      if (!_hasNextFilterPage || _isLoadingMoreFilter) return;
      _isLoadingMoreFilter = true;
    } else {
      _isFiltering = true;
      _filterCurrentPage = 1;
      _filteredResults = [];
      _currentFilter = filter;
      _error = '';
    }

    notifyListeners();

    try {
      final response = await _apiService.getFilteredVisionVideos(
        _currentSubjectId!,
        _currentLevelId!,
        filter,
        page: loadMore ? _filterCurrentPage + 1 : 1,
        perPage: _perPage,
      );

      if (loadMore) {
        _filteredResults.addAll(response.videos);
        _filterCurrentPage = response.currentPage;
      } else {
        _filteredResults = response.videos;
        _filterCurrentPage = response.currentPage;
      }

      _filterTotalPages = response.totalPages;
      _filterTotalVideos = response.totalVideos;
      _hasNextFilterPage = response.hasNextPage;
      _error = '';

      debugPrint('✅ Filter "$filter" applied: ${response.videos.length} results');
    } catch (e) {
      if (!loadMore) {
        _error = _formatErrorMessage(e);
      }
      debugPrint('❌ Error applying filter "$filter": $e');
    } finally {
      _isFiltering = false;
      _isLoadingMoreFilter = false;
      notifyListeners();
    }
  }

  Future<void> searchVideos(String searchText, {bool loadMore = false}) async {
    if (_currentSubjectId == null || _currentSubjectId!.isEmpty) {
      _error = 'No subject selected';
      notifyListeners();
      return;
    }

    // If search text is empty, clear search and show all videos
    if (searchText.isEmpty) {
      _clearSearch();
      await fetchVideos();
      return;
    }

    if (loadMore) {
      if (!_hasNextSearchPage || _isLoadingMoreSearch) return;
      _isLoadingMoreSearch = true;
    } else {
      _isSearching = true;
      _searchCurrentPage = 1;
      _searchResults = [];
      _searchQuery = searchText;
      _error = '';
    }

    notifyListeners();

    try {
      final response = await _apiService.searchVisionVideos(
        _searchQuery,
        _currentSubjectId!,
        _currentLevelId!,
        page: loadMore ? _searchCurrentPage + 1 : 1,
        perPage: _perPage,
      );

      if (loadMore) {
        _searchResults.addAll(response.videos);
        _searchCurrentPage = response.currentPage;
      } else {
        _searchResults = response.videos;
        _searchCurrentPage = response.currentPage;
      }

      _searchTotalPages = response.totalPages;
      _searchTotalVideos = response.totalVideos;
      _hasNextSearchPage = response.hasNextPage;
      _error = '';

      debugPrint('✅ Search successful: ${response.videos.length} results for "$searchText"');
    } catch (e) {
      if (!loadMore) {
        _error = _formatErrorMessage(e);
      }
      debugPrint('❌ Error searching videos: $e');
    } finally {
      _isSearching = false;
      _isLoadingMoreSearch = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreVideos() async {
    if (!_hasNextPage || _isLoadingMore) return;
    await fetchVideos(loadMore: true);
  }

  Future<void> loadMoreSearchResults() async {
    if (!_hasNextSearchPage || _isLoadingMoreSearch) return;
    await searchVideos(_searchQuery, loadMore: true);
  }

  // ADD THIS MISSING METHOD
  Future<void> loadMoreFilterResults() async {
    if (!_hasNextFilterPage || _isLoadingMoreFilter) return;
    await applyFilter(_currentFilter, loadMore: true);
  }

  Future<void> refreshVideos() async {
    if (_currentFilter.isNotEmpty) {
      await applyFilter(_currentFilter);
    } else if (_searchQuery.isNotEmpty) {
      await searchVideos(_searchQuery);
    } else {
      _currentPage = 1;
      await fetchVideos(loadMore: false);
    }
  }

  void setSearchText(String value) {
    _searchText = value;

    // Trigger API search if text is not empty
    if (value.isNotEmpty) {
      // Add a small delay to avoid too many API calls while typing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchText == value) { // Only search if text hasn't changed
          searchVideos(value);
        }
      });
    } else {
      // Clear search if text is empty
      clearSearch();
    }

    notifyListeners();
  }

  void setFilters(Map<String, bool> filters) {
    _activeFilters = Map.from(filters);

    // Find the first active filter and apply it
    final activeFilter = _getActiveApiFilter();
    if (activeFilter.isNotEmpty) {
      applyFilter(activeFilter);
    } else {
      // If no API filter is active, clear filter and show all videos
      _clearFilter();
      fetchVideos();
    }

    notifyListeners();
  }

  String _getActiveApiFilter() {
    if (_activeFilters['all'] == true) return 'all';
    if (_activeFilters['teacher_assigned'] == true) return 'teacher_assigned';
    if (_activeFilters['skipped'] == true) return 'skipped';
    if (_activeFilters['pending'] == true) return 'pending';
    if (_activeFilters['completed'] == true) return 'completed';
    if (_activeFilters['submitted'] == true) return 'submitted';
    return '';
  }

  void clearSearch() {
    _searchText = '';
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    _searchCurrentPage = 1;
    _searchTotalPages = 1;
    _searchTotalVideos = 0;
    _hasNextSearchPage = false;
    _isLoadingMoreSearch = false;
    notifyListeners();
  }

  void clearFilters() {
    _activeFilters = {
      'all': false,
      'teacher_assigned': false,
      'skipped': false,
      'pending': false,
      'completed': false,
      'submitted': false,
    };
    _clearFilter();
    fetchVideos();
    notifyListeners();
  }

  void _clearFilter() {
    _currentFilter = '';
    _filteredResults = [];
    _isFiltering = false;
    _filterCurrentPage = 1;
    _filterTotalPages = 1;
    _filterTotalVideos = 0;
    _hasNextFilterPage = false;
    _isLoadingMoreFilter = false;
  }

  void _clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults = [];
    _searchCurrentPage = 1;
    _searchTotalPages = 1;
    _searchTotalVideos = 0;
    _hasNextSearchPage = false;
    _isLoadingMoreSearch = false;
  }

  bool isCurrentLevelCompleted() {
    if (_currentLevelId == null || _currentLevelId!.isEmpty) return false;
    final levelVideos = _videos.where((v) => v.levelId.toString() == _currentLevelId).toList();
    if (levelVideos.isEmpty) return false;
    return levelVideos.every((v) => v.isCompleted);
  }

  String? get currentLevel => _currentLevelId;

  Future<void> fetchQuizQuestions(String visionId) async {
    _isLoadingQuestions = true;
    _questionsError = '';
    _currentQuestions = null;
    notifyListeners();

    try {
      final questions = await _apiService.getVisionQuestions(visionId);
      _currentQuestions = questions;
      debugPrint('Points from API: ${questions['image_question']?['level']?['vision_text_image_points']}');
      debugPrint('✅ Successfully loaded quiz questions for vision: $visionId');
    } catch (e) {
      _questionsError = _formatErrorMessage(e);
      debugPrint('❌ Error fetching quiz questions: $e');
    } finally {
      _isLoadingQuestions = false;
      notifyListeners();
    }
  }

  int get currentVisionPoints {
    if (_currentQuestions == null) return 0;
    final imagePoints = _currentQuestions!['image_question']?['level']?['vision_text_image_points'];
    if (imagePoints != null) return imagePoints as int;
    final mcqPoints = _currentQuestions!['mcq_questions']?[0]?['level']?['vision_text_image_points'];
    if (mcqPoints != null) return mcqPoints as int;
    return 0;
  }

  void clearQuizQuestions() {
    _currentQuestions = null;
    _questionsError = '';
    notifyListeners();
  }

  Future<Map<String, dynamic>?> submitAnswersAndGetResult(
      String visionId, List<Map<String, dynamic>> answers) async {
    try {
      final sanitizedAnswers = answers.map((answer) {
        final sanitized = <String, dynamic>{};
        answer.forEach((key, value) {
          final stringKey = key.toString();
          if (value is int && (key.toLowerCase().contains('id'))) {
            sanitized[stringKey] = value.toString();
          } else {
            if (key == 'answer') {
              sanitized[stringKey] = value ?? '';
            } else {
              sanitized[stringKey] = value;
            }
          }
        });
        return sanitized;
      }).toList();

      final result = await _apiService.submitVideoAnswersAndGetResult(visionId, sanitizedAnswers);

      if (result == null) {
        throw Exception('No response from server');
      }

      if (result['submission_successful'] != true) {
        throw Exception(result['error'] ?? 'Submission failed');
      }

      debugPrint('✅ Successfully submitted answers for vision: $visionId');
      await fetchVideos();
      clearQuizQuestions();
      return result;
    } catch (e) {
      debugPrint('❌ Error submitting answers: $e');
      _questionsError = _formatErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQuizResult(String visionId) async {
    try {
      final result = await _apiService.getQuizResult(visionId);
      debugPrint('✅ Successfully retrieved quiz result for vision: $visionId');
      return result;
    } catch (e) {
      debugPrint('❌ Error getting quiz result: $e');
      throw Exception(_formatErrorMessage(e));
    }
  }

  Future<bool> skipQuiz(String visionId) async {
    try {
      final success = await _apiService.skipQuiz(visionId);
      if (success) {
        debugPrint('✅ Successfully skipped quiz for vision: $visionId');
        await fetchVideos();
        clearQuizQuestions();
        return true;
      }
      throw Exception('Failed to skip quiz');
    } catch (e) {
      debugPrint('❌ Error skipping quiz: $e');
      throw Exception(_formatErrorMessage(e));
    }
  }

  Future<bool> markQuizPending(String visionId) async {
    try {
      final success = await _apiService.markQuizPending(visionId);
      if (success) {
        debugPrint('✅ Successfully marked quiz pending for vision: $visionId');
        await fetchVideos();
        clearQuizQuestions();
        return true;
      }
      throw Exception('Failed to mark quiz pending');
    } catch (e) {
      debugPrint('❌ Error marking quiz pending: $e');
      throw Exception(_formatErrorMessage(e));
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is VisionNotFoundException) {
      return 'Vision not found. Please try another quiz.';
    } else if (error is VisionInactiveException) {
      return 'This quiz is no longer available.';
    } else {
      return error.toString();
    }
  }

  bool get hasActiveFilters => _activeFilters.values.any((filter) => filter);
  int get filteredVideoCount => filteredVideos.length;

  bool hasVideo(String visionId) {
    return _videos.any((video) => video.id.toString() == visionId);
  }

  VisionVideo? getVideoById(String visionId) {
    try {
      return _videos.firstWhere((video) => video.id.toString() == visionId);
    } catch (e) {
      return null;
    }
  }

  Future<VisionVideo?> getVisionVideoDirectly(String visionId) async {
    try {
      debugPrint('🔄 Fetching vision video directly by ID: $visionId');

      final video = await _apiService.getVisionVideoById(visionId);

      if (video != null) {
        debugPrint('✅ Successfully fetched vision video: ${video.title}');

        // Add to current videos list if not already present
        if (!_videos.any((v) => v.id == video.id)) {
          _videos.add(video);
          notifyListeners();
        }

        return video;
      } else {
        debugPrint('❌ Vision video not found with ID: $visionId');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Error fetching vision video directly: $e');
      return null;
    }
  }
}