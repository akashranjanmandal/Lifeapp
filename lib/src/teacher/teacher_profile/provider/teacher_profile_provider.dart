import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../common/helper/color_code.dart';
import '../../../common/helper/string_helper.dart';
import '../../../student/home/models/subject_model.dart';
import '../../../student/home/services/dashboard_services.dart';
import '../../../student/profile/services/profile_services.dart';
import '../../../student/sign_up/model/school_list_model.dart';
import '../../../student/sign_up/model/section_model.dart';
import '../../../student/sign_up/model/state_city_model.dart';
import '../../../student/sign_up/model/verify_school_model.dart';
import '../../../student/sign_up/services/sign_up_services.dart';
import '../../../utils/storage_utils.dart';
import '../../leaderboard/model/model.dart';
import '../../leaderboard/services/services.dart';
import '../../teacher_sign_up/model/board_model.dart';
import '../../teacher_sign_up/services/teacher_sign_up_services.dart';
import '../../teacher_dashboard/provider/teacher_dashboard_provider.dart';

class TeacherProfileProvider extends ChangeNotifier {
  // Models
  SchoolListModel? schoolListModel;
  SectionModel? sectionModel;
  BoardModel? boardModel;
  SubjectModel? subjectModel;
  VerifySchoolModel? verifySchoolModel;
  LeaderboardEntry? teacherRankEntry;
  LeaderboardEntry? schoolRankEntry;

  // Lists
  List<StateCityListModel> listOfLocation = [];
  List<StateCityListModel> searchListOfLocation = [];
  List<City> cityList = [];
  List<City> searchCityList = [];
  List<Map<String, dynamic>> gradeMapList = [];

  // Controllers
  TextEditingController teacherNameController = TextEditingController();
  TextEditingController schoolNameController = TextEditingController();
  TextEditingController boardNameController = TextEditingController();
  TextEditingController subjectController = TextEditingController();
  TextEditingController sectionController = TextEditingController();
  TextEditingController gradeController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateSearchCont = TextEditingController();
  TextEditingController citySearchCont = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController schoolCodeController = TextEditingController();

  // Data
  List<int> gradeList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  List<int> subjectIdList = [];
  int? boardId;
  String? boardName;
  int gender = 0;
  int? sectionId;
  bool isSchoolCodeValid = true;
  DateTime date = DateTime.now();

  // Performance optimization
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  Completer<void>? _initializationCompleter;
  final Map<String, dynamic> _apiCache = {};
  DateTime _lastFetchTime = DateTime.now();

  // Getters
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _isDisposed = true;

    // Dispose all controllers
    teacherNameController.dispose();
    schoolNameController.dispose();
    boardNameController.dispose();
    subjectController.dispose();
    sectionController.dispose();
    gradeController.dispose();
    stateController.dispose();
    cityController.dispose();
    stateSearchCont.dispose();
    citySearchCont.dispose();
    dobController.dispose();
    schoolCodeController.dispose();

    // Cancel any pending operations
    _initializationCompleter = null;

    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Main initialization method - Call this from your page
  Future<void> initializeProfileData({
    required BuildContext context,
    required int userId,
    required String schoolName,
    required dynamic user,
  }) async {
    // Prevent multiple initializations
    if (_initializationCompleter != null) {
      debugPrint("🔄 Returning existing initialization future");
      try {
        return await _initializationCompleter!.future;
      } catch (e) {
        // If previous initialization failed, reset and try again
        debugPrint("⚠️ Previous initialization failed, resetting...");
        _initializationCompleter = null;
        _isInitialized = false;
        _apiCache.clear();
      }
    }

    _initializationCompleter = Completer<void>();
    _isLoading = true;
    safeNotifyListeners();

    try {
      debugPrint("🚀 Starting profile initialization...");

      // Step 1: Process user data immediately (no API call needed)
      _processUserDataImmediately(user);

      // Step 2: Fetch all data in parallel for maximum speed
      await Future.wait([
        // Leaderboard data
        _fetchLeaderboardData(userId, schoolName),

        // Other data with proper error handling
        _fetchAllRequiredData(),
      ], eagerError: true);

      // Step 3: Post-process data after fetching
      _postProcessData(user);

      debugPrint("✅ Profile initialization complete");
      _initializationCompleter?.complete();
    } catch (e, stackTrace) {
      debugPrint("❌ Initialization error: $e");
      debugPrint("Stack trace: $stackTrace");

      // Even if there's an error, ensure we mark as initialized
      _isInitialized = true;
      _initializationCompleter?.completeError(e);

      // Show user-friendly error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: "Profile data loaded with some issues. You can still edit your profile.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        }
      });
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  void _processUserDataImmediately(dynamic user) {
    debugPrint("📝 Processing user data immediately");

    teacherNameController.text = user.name ?? "";
    schoolNameController.text = user.school?.name ?? "";
    sectionController.text = user.section?.name ?? "";
    sectionId = user.section?.id;
    dobController.text = user.dob ?? "";
    gradeController.text = user.grade?.name?.toString() ?? "";
    stateController.text = user.state ?? "";
    cityController.text = user.city ?? "";
    schoolCodeController.text = user.school?.code?.toString() ?? "";

    // Set DOB
    setInitialDOB(user.dob);

    // Initialize board from user data - FIXED: Use safe access
    final boardIdFromUser = user.la_board_id?.toString() ?? '';
    final boardNameFromUser = user.board_name?.toString() ?? '';

    if (boardIdFromUser.isNotEmpty && boardNameFromUser.isNotEmpty) {
      _setBoardFromUserData(boardIdFromUser, boardNameFromUser);
    }

    // Clear and initialize grade map list
    gradeMapList.clear();
    if (user.laTeacherGrades != null && user.laTeacherGrades!.isNotEmpty) {
      for (var element in user.laTeacherGrades!) {
        gradeMapList.add({
          "la_grade_id": element.grade?.id?.toString() ?? "",
          "la_section_id": element.section?.id?.toString() ?? "",
          "la_section_name": element.section?.name ?? "",
          "subjects": element.subject?.id?.toString() ?? "",
          "subject_name": element.subject?.title ?? ""
        });
      }
    } else {
      gradeMapList.add({
        "la_grade_id": "",
        "la_section_id": "",
        "la_section_name": "",
        "subjects": "",
        "subject_name": ""
      });
    }
  }

  Future<void> _fetchAllRequiredData() async {
    debugPrint("🌐 Fetching all required data in parallel...");

    try {
      // Fetch all data simultaneously
      await Future.wait([
        _getSchoolList(),
        _getSectionList(),
        _getBoardList(),
        _getSubjectList(),
        _getStateCityList(),
      ], eagerError: true);

      debugPrint("✅ All data fetched successfully");
    } catch (e) {
      debugPrint("⚠️ Some data fetches failed: $e");
      // Continue anyway - we have fallbacks
    }
  }

  void _postProcessData(dynamic user) {
    debugPrint("🔧 Post-processing data...");

    // FIXED: Use safe access without ! operator
    final boardIdFromUser = user.la_board_id?.toString() ?? '';
    final boardNameFromUser = user.board_name?.toString() ?? '';

    if (boardId == null && boardIdFromUser.isNotEmpty) {
      _setBoardFromUserData(boardIdFromUser, boardNameFromUser);
    }

    // Ensure we have at least one grade entry
    if (gradeMapList.isEmpty) {
      gradeMapList.add({
        "la_grade_id": "",
        "la_section_id": "",
        "la_section_name": "",
        "subjects": "",
        "subject_name": ""
      });
    }

    // Sync board with fetched list if we have board name
    if (boardNameController.text.isNotEmpty && boardId == null) {
      _syncBoardWithList();
    }

    _isInitialized = true;
  }

  // Optimized leaderboard fetch
  Future<void> _fetchLeaderboardData(int teacherId, String schoolName) async {
    try {
      final token = await StorageUtil.getString(StringHelper.token);
      if (token == null || token.isEmpty) {
        debugPrint("⚠️ No token available for leaderboard");
        return;
      }

      // Check cache first
      final cacheKey = "leaderboard_${teacherId}_${schoolName.hashCode}";
      final now = DateTime.now();
      if (_apiCache.containsKey(cacheKey) &&
          now.difference(_lastFetchTime).inMinutes < 10) {
        final cached = _apiCache[cacheKey];
        teacherRankEntry = cached['teacher'];
        schoolRankEntry = cached['school'];
        debugPrint("📊 Using cached leaderboard data");
        return;
      }

      debugPrint("📊 Fetching fresh leaderboard data...");
      final leaderboardService = LeaderboardService(token);

      // Fetch both in parallel
      final results = await Future.wait([
        leaderboardService.fetchTeacherLeaderboard(),
        leaderboardService.fetchSchoolLeaderboard(),
      ]);

      final teacherList = results[0];
      final schoolList = results[1];

      // Find teacher rank
      teacherRankEntry = teacherList.firstWhere(
            (entry) => entry.teacherId == teacherId,
        orElse: () => _createDefaultTeacherEntry(teacherId),
      );

      // Find school rank
      schoolRankEntry = schoolList.firstWhere(
            (entry) => _matchSchoolNames(entry.name ?? '', schoolName),
        orElse: () => _createDefaultSchoolEntry(schoolName),
      );

      // Cache the results
      _apiCache[cacheKey] = {
        'teacher': teacherRankEntry,
        'school': schoolRankEntry,
      };
      _lastFetchTime = DateTime.now();

      debugPrint("✅ Leaderboard data fetched");
    } catch (e, stackTrace) {
      debugPrint("❌ Leaderboard fetch error: $e");
      debugPrint("Stack trace: $stackTrace");

      // Set defaults on error
      teacherRankEntry = _createDefaultTeacherEntry(teacherId);
      schoolRankEntry = _createDefaultSchoolEntry(schoolName);
    }
  }

  bool _matchSchoolNames(String entryName, String schoolName) {
    if (entryName.isEmpty || schoolName.isEmpty) return false;

    final normalizedEntry = entryName.trim().toLowerCase();
    final normalizedSchool = schoolName.trim().toLowerCase();

    // Exact match
    if (normalizedEntry == normalizedSchool) return true;

    // Contains match
    if (normalizedEntry.contains(normalizedSchool) ||
        normalizedSchool.contains(normalizedEntry)) return true;

    return false;
  }

  LeaderboardEntry _createDefaultTeacherEntry(int teacherId) {
    return LeaderboardEntry(
      rank: 0,
      teacherId: teacherId,
      name: '',
      schoolName: '',
      totalEarnedCoins: 0,
      tScore: 0.0,
      sScore: 0.0,
      assignTaskCoins: 0,
      correctSubmissionCoins: 0,
      maxPossibleCoins: 0,
      studentCoins: 0,
      teacherCoins: 0,
      maxStudentCoins: 0,
      maxTeacherCoins: 0,
    );
  }

  LeaderboardEntry _createDefaultSchoolEntry(String schoolName) {
    return LeaderboardEntry(
      rank: 0,
      teacherId: null,
      name: schoolName,
      schoolName: '',
      totalEarnedCoins: 0,
      tScore: 0.0,
      sScore: 0.0,
      assignTaskCoins: 0,
      correctSubmissionCoins: 0,
      maxPossibleCoins: 0,
      studentCoins: 0,
      teacherCoins: 0,
      maxStudentCoins: 0,
      maxTeacherCoins: 0,
    );
  }

  // Optimized data fetching methods
  Future<void> _getSchoolList() async {
    try {
      final cacheKey = "school_list";
      if (_apiCache.containsKey(cacheKey)) {
        schoolListModel = _apiCache[cacheKey];
        return;
      }

      final response = await TeacherSignUpServices().getSchoolList();
      if (response?.statusCode == 200) {
        schoolListModel = SchoolListModel.fromJson(response!.data);
        _apiCache[cacheKey] = schoolListModel;
      }
    } catch (e) {
      debugPrint("⚠️ School list fetch error: $e");
    }
  }

  Future<void> _getSectionList() async {
    try {
      final cacheKey = "section_list";
      if (_apiCache.containsKey(cacheKey)) {
        sectionModel = _apiCache[cacheKey];
        return;
      }

      final response = await SignUpServices().getSectionList();
      if (response.statusCode == 200) {
        sectionModel = SectionModel.fromJson(response.data);
        _apiCache[cacheKey] = sectionModel;
      }
    } catch (e) {
      debugPrint("⚠️ Section list fetch error: $e");
    }
  }

  Future<void> _getBoardList() async {
    try {
      final cacheKey = "board_list";
      if (_apiCache.containsKey(cacheKey)) {
        boardModel = _apiCache[cacheKey];
        return;
      }

      final response = await TeacherSignUpServices().getBoard();
      if (response.statusCode == 200) {
        boardModel = BoardModel.fromJson(response.data);
        _apiCache[cacheKey] = boardModel;

        // Sync with user data if available
        if (boardNameController.text.isNotEmpty && boardId == null) {
          _syncBoardWithList();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Board list fetch error: $e");
    }
  }

  void _syncBoardWithList() {
    if (boardModel?.data?.boards != null && boardNameController.text.isNotEmpty) {
      final boardName = boardNameController.text.toLowerCase();

      // Use where instead of firstWhere to avoid null return type issue
      final matchingBoards = boardModel!.data!.boards!.where(
              (board) => (board.name ?? '').toLowerCase() == boardName
      ).toList();

      if (matchingBoards.isNotEmpty) {
        final existingBoard = matchingBoards.first;
        boardId = existingBoard.id;
        debugPrint("✅ Synced board: $boardId - ${existingBoard.name}");
      } else {
        debugPrint("⚠️ Board '$boardName' not found in list");
      }
    }
  }

  Future<void> _getSubjectList() async {
    try {
      final cacheKey = "subject_list";
      if (_apiCache.containsKey(cacheKey)) {
        subjectModel = _apiCache[cacheKey];
        return;
      }

      final response = await DashboardServices().getSubjectData();
      if (response != null && response.statusCode == 200) {
        subjectModel = SubjectModel.fromJson(response.data);
        _apiCache[cacheKey] = subjectModel;
      }
    } catch (e) {
      debugPrint("⚠️ Subject list fetch error: $e");
    }
  }

  Future<void> _getStateCityList() async {
    try {
      final cacheKey = "state_city_list";
      if (_apiCache.containsKey(cacheKey)) {
        final cached = _apiCache[cacheKey] as List<StateCityListModel>;
        listOfLocation = cached;
        searchListOfLocation = List.from(cached);
        return;
      }

      final response = await TeacherSignUpServices().getStateList();
      if (response?.statusCode == 200) {
        listOfLocation.clear();
        searchListOfLocation.clear();

        for (var i in response!.data) {
          final data = StateCityListModel.fromJson(i);
          if (data.active == 1) {
            listOfLocation.add(data);
            searchListOfLocation.add(data);
          }
        }

        _apiCache[cacheKey] = List.from(listOfLocation);

        // Set city list if state is already selected
        if (stateController.text.isNotEmpty) {
          final index = listOfLocation.indexWhere((element) =>
          element.stateName?.toLowerCase() == stateController.text.toLowerCase());
          if (index >= 0) getCityData(index);
        }
      }
    } catch (e) {
      debugPrint("⚠️ State city list fetch error: $e");
    }
  }

  // Public methods
  void updateSchoolCode(String val) {
    isSchoolCodeValid = false;
    schoolCodeController.text = val;
    safeNotifyListeners();
  }

  void getCityData(int index) {
    if (index >= 0 && index < listOfLocation.length) {
      cityList = listOfLocation[index].cities ?? [];
      searchCityList = List.from(cityList);
      safeNotifyListeners();
    }
  }

  void resetState() {
    _isInitialized = false;
    gradeMapList.clear();
    _apiCache.clear();
    _initializationCompleter = null;
    safeNotifyListeners();
  }

  void initializeGradeMapList() {
    if (!_isInitialized) {
      gradeMapList.clear();
      gradeMapList.add({
        "la_grade_id": "",
        "la_section_id": "",
        "la_section_name": "",
        "subjects": "",
        "subject_name": ""
      });
      _isInitialized = true;
      safeNotifyListeners();
    }
  }

  bool isGradeEntryValid(Map<String, dynamic> grade) {
    return grade["la_grade_id"].toString().isNotEmpty &&
        grade["la_section_id"].toString().isNotEmpty &&
        grade["subjects"].toString().isNotEmpty;
  }

  void syncBoardWithDashboard(BuildContext context) {
    if (boardId != null && boardName != null) {
      final dashboardProvider =
      Provider.of<TeacherDashboardProvider>(context, listen: false);
      dashboardProvider.setSelectedBoard(boardId!, boardName!);
    }
  }

  void _setBoardFromUserData(String boardIdStr, String boardNameStr) {
    try {
      // Check if values are valid
      if (boardIdStr.isNotEmpty && boardNameStr.isNotEmpty) {
        final id = int.tryParse(boardIdStr);
        if (id != null) {
          boardId = id;
          boardName = boardNameStr;
          boardNameController.text = boardNameStr;
          debugPrint("✅ Board set from user data: $boardId - $boardName");
        } else {
          debugPrint("⚠️ Invalid board ID format: $boardIdStr");
        }
      } else {
        debugPrint("⚠️ Empty board data received");
      }
    } catch (e) {
      debugPrint("❌ Error setting board from user data: $e");
    }
  }

  void updateBoard(int id, String name) {
    try {
      if (id > 0 && name.isNotEmpty) {
        boardId = id;
        boardName = name;
        boardNameController.text = name;
        debugPrint("✅ Board updated: $id - $name");
        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error updating board: $e");
    }
  }

  Future<void> verifySchoolCode(BuildContext context) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(
        color: ColorCode.buttonColor,
      ),
      overlayColor: Colors.black54,
    );

    try {
      final response =
      await SignUpServices().verifyCode(schoolCodeController.text.trim());
      Loader.hide();

      if (response.statusCode == 200) {
        isSchoolCodeValid = true;
        verifySchoolModel = VerifySchoolModel.fromJson(response.data);
        schoolNameController.text = verifySchoolModel!.data!.school!.name!;
        stateController.text = verifySchoolModel!.data!.school!.state!;
        cityController.text = verifySchoolModel!.data!.school!.city!;
        Fluttertoast.showToast(
          msg: "School code verified successfully",
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        isSchoolCodeValid = false;
        Fluttertoast.showToast(
          msg: "Invalid school code",
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Loader.hide();
      Fluttertoast.showToast(
        msg: "Error verifying school code",
        gravity: ToastGravity.BOTTOM,
      );
      isSchoolCodeValid = false;
    }

    safeNotifyListeners();
  }

  void addNewGradeEntry() {
    gradeMapList.add({
      "la_grade_id": "",
      "la_section_id": "",
      "la_section_name": "",
      "subjects": "",
      "subject_name": ""
    });
    safeNotifyListeners();
  }

  void updateGradeMapList(String gradeId, String sectionId, String subjectId,
      String sectionName, String subjectName, int index) {
    if (index < gradeMapList.length) {
      gradeMapList[index] = {
        "la_grade_id": gradeId,
        "la_section_id": sectionId,
        "la_section_name": sectionName,
        "subjects": subjectId,
        "subject_name": subjectName
      };
      safeNotifyListeners();
    }
  }

  void updateDOB(DateTime picked) {
    date = picked;
    dobController.text =
    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    safeNotifyListeners();
  }

  void setInitialDOB(String? dob) {
    if (dob != null && dob.isNotEmpty) {
      try {
        final DateTime dobDate = DateTime.parse(dob);
        date = dobDate;
        dobController.text =
        "${dobDate.year}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.day.toString().padLeft(2, '0')}";
      } catch (e) {
        debugPrint("❌ Error parsing DOB: $e");
        date = DateTime.now();
        dobController.text = "";
      }
    } else {
      date = DateTime.now();
      dobController.text = "";
    }
    safeNotifyListeners();
  }

  void updateTeacher(BuildContext context, String contact) async {
    try {
      // Validation
      if (!_validateProfileData()) {
        return;
      }

      if (context.mounted) {
        Loader.show(
          context,
          progressIndicator: const CircularProgressIndicator(
            color: ColorCode.buttonColor,
          ),
          overlayColor: Colors.black54,
        );
      }

      // Prepare grade data
      final cleanGradeMapList = gradeMapList
          .where((grade) =>
      grade["la_grade_id"].toString().isNotEmpty &&
          grade["subjects"].toString().isNotEmpty)
          .map((grade) => {
        "la_grade_id": grade["la_grade_id"],
        "la_section_id": grade["la_section_id"],
        "subjects": grade["subjects"],
      })
          .toList();

      // Prepare request body
      final schoolData = verifySchoolModel?.data?.school;
      final Map<String, dynamic> body = {
        "mobile_no": contact,
        "type": 5,
        "name": teacherNameController.text.trim(),
        "school_id": schoolData?.id,
        "school": schoolData?.name ?? schoolNameController.text.trim(),
        "school_code": schoolData?.code ?? schoolCodeController.text.trim(),
        "state": stateController.text.trim(),
        "city": cityController.text.trim(),
        "la_board_id": boardId,
        "board_name": boardName,
        "dob": dobController.text.trim(),
        "grades": cleanGradeMapList,
      };

      debugPrint("📤 Update request body: $body");

      // Send update request
      final response = await ProfileService().updateProfileData(body);
      debugPrint("📥 Update Profile Response: ${response.statusCode}");

      Loader.hide();

      if (response.statusCode == 200) {
        // Update dashboard data
        if (context.mounted) {
          await Provider.of<TeacherDashboardProvider>(context, listen: false)
              .getDashboardData();
        }

        Fluttertoast.showToast(
          msg: "Profile updated successfully",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Failed to update profile. Please try again.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e, stackTrace) {
      Loader.hide();
      debugPrint("❌ Error updating teacher profile: $e");
      debugPrint("Stack trace: $stackTrace");

      if (context.mounted) {
        Fluttertoast.showToast(
          msg: "An error occurred while updating profile",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  bool _validateProfileData() {
    // Check for at least one valid grade entry
    final hasValidGrade = gradeMapList.any((grade) =>
    grade["la_grade_id"].toString().isNotEmpty &&
        grade["la_section_id"].toString().isNotEmpty &&
        grade["subjects"].toString().isNotEmpty);

    if (!hasValidGrade) {
      Fluttertoast.showToast(
        msg: "Please add at least one grade with section and subject",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }

    // Check DOB
    if (dobController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select date of birth",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }

    // Check board
    if (boardId == null || boardName == null || boardName!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select a board",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }

    return true;
  }

  // Helper to check if provider is still valid
  bool get mounted => !_isDisposed;
}