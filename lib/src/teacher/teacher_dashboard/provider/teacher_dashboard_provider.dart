import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/student/home/models/dashboard_model.dart';
import 'package:lifelab3/src/student/home/models/subject_model.dart';
import 'package:lifelab3/src/student/sign_up/model/grade_model.dart';
import 'package:lifelab3/src/student/subject_level_list/models/level_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/assessment_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/competencies_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/concept_cartoon_header_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/concept_cartoon_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/language_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/lesson_plan_model.dart' hide Board;
import 'package:lifelab3/src/teacher/teacher_dashboard/model/work_sheet_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/lesson_download_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/service/teacher_dashboard_service.dart';
import '../../../common/helper/color_code.dart';
import '../../../student/home/services/dashboard_services.dart';
import '../../../student/subject_level_list/service/level_list_service.dart';
import '../../teacher_sign_up/model/board_model.dart';
import '../../teacher_sign_up/services/teacher_sign_up_services.dart';
import '../model/language_pbl_model.dart';
import '../model/pbl_model.dart' hide Board;
import '../model/teacher_subject_grade_model.dart';

class TeacherDashboardProvider extends ChangeNotifier {
  DashboardModel? dashboardModel;
  SubjectModel? subjectModel;
  LevelModel? levels;
  CompetenciesModel? competenciesModel;
  ConceptCartoonModel? cartoonModel;
  AssessmentModel? assessmentModel;
  WorkSheetModel? workSheetModel;
  ConceptCartoonHeaderModel? headerModel;
  BoardModel? boardModel;
  LanguageModel? languageModel;
  GradeModel? gradeModel;
  LessonPlanModel? lessonPlanModel;
  TeacherSubjectGradeModel? teacherSubjectGradeModel;

  String board = "";
  String language = "";
  int? boardId = 0;
  int languageId = 0;
  PblTextbookMappingResponse? pblMappingResponse;
  String title = "";
  int subjectId = 0;
  int gradeId = 0;

  // PBL Language specific properties (different names)
  PblLanguageModel? pblLanguageModel;
  String pblSelectedLanguage = "";
  int pblLanguageId = 0;

  // NEW: Add subject-grade mapping for PBL
  Map<int, List<TeacherSubjectGradePair>> subjectToGradesMap = {};
  List<TeacherSubjectGradePair> subjectGradePairsWithPdf = [];

  /// ----------------- GETTERS -----------------
  // All subject-grade pairs
  List<TeacherSubjectGradePair> get subjectGradePairs =>
      teacherSubjectGradeModel?.subjectGradePairs ?? [];

  // Unique subjects
  List<TeacherSubject> get subjects =>
      subjectGradePairs.map((e) => e.subject!).toSet().toList();

  // Grades filtered by selected subject
  List<TeacherGrade> get grades {
    if (subjectId == 0) return [];
    return subjectGradePairs
        .where((pair) => pair.subject?.id == subjectId)
        .map((pair) => pair.grade!)
        .toList();
  }

  // PBL PDF mappings
  List<PblTextbookMapping> get pdfMappings =>
      pblMappingResponse?.data.pblTextbookMappings ?? [];

  // Available boards for dropdown
  List<Board> get availableBoards => boardModel?.data?.boards ?? [];

  // Available PBL languages
  List<PblLanguageItem> get availablePblLanguages => pblLanguageModel?.data.pblLanguages ?? [];

  // NEW: Get subject title for display
  String get selectedSubjectTitle {
    if (subjectGradePairsWithPdf.isEmpty) return '';
    try {
      final pair = subjectGradePairsWithPdf.firstWhere(
            (p) => p.subject?.id == subjectId,
        orElse: () => subjectGradePairsWithPdf.first,
      );
      return pair.subject?.title ?? '';
    } catch (e) {
      return subjectGradePairsWithPdf.first.subject?.title ?? '';
    }
  }

  // NEW: Get grade name for display
  String get selectedGradeName {
    if (subjectGradePairsWithPdf.isEmpty) return '';
    try {
      final pair = subjectGradePairsWithPdf.firstWhere(
            (p) => p.grade?.id == gradeId,
        orElse: () => subjectGradePairsWithPdf.first,
      );
      return pair.grade?.name ?? '';
    } catch (e) {
      return subjectGradePairsWithPdf.first.grade?.name ?? '';
    }
  }

  void setSubjectGradePairsWithPdf(List<TeacherSubjectGradePair> pairs) {
    subjectGradePairsWithPdf = pairs;
    notifyListeners();
  }

  // NEW: Subject-grade mapping methods
  void setSubjectToGradesMap(Map<int, List<TeacherSubjectGradePair>> map) {
    subjectToGradesMap = map;
    notifyListeners();
  }

  List<TeacherSubjectGradePair> getGradesForSubject(int subjectId) {
    return subjectToGradesMap[subjectId] ?? [];
  }

  /// ----------------- PBL LANGUAGE MANAGEMENT -----------------
  Future<void> getPblLanguages() async {
    try {
      final response = await TeacherDashboardService().getPblLanguages();
      if (response != null && response.statusCode == 200) {
        pblLanguageModel = PblLanguageModel.fromJson(response.data);

        // Auto-select English if available
        if (pblLanguageModel?.data.pblLanguages != null &&
            pblLanguageModel!.data.pblLanguages.isNotEmpty) {
          final englishLang = pblLanguageModel!.data.pblLanguages.firstWhere(
                (lang) => (lang.pblLangSlug ?? '').toLowerCase() == 'en',
            orElse: () => pblLanguageModel!.data.pblLanguages.first,
          );

          pblLanguageId = englishLang.pblLangId ?? 0;
          pblSelectedLanguage = englishLang.pblLangTitle ?? englishLang.pblLangName ?? '';
        }

        debugPrint("✅ Loaded ${pblLanguageModel?.data.pblLanguages.length ?? 0} PBL languages");
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load PBL languages: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching PBL languages: $e");
    }
  }

  void setPblLanguage(int id, String languageName) {
    pblLanguageId = id;
    pblSelectedLanguage = languageName;
    debugPrint("🎯 PBL Language changed to: $pblSelectedLanguage (ID: $pblLanguageId)");
    notifyListeners();
  }

  void clearPblLanguageSelection() {
    pblSelectedLanguage = "";
    pblLanguageId = 0;
    notifyListeners();
  }

  /// ----------------- BOARD MANAGEMENT -----------------
  Future<void> getBoard() async {
    try {
      Response? response = await TeacherSignUpServices().getBoard(); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        boardModel = BoardModel.fromJson(response.data);

        // Set default board if not already set
        if (boardId == 0 && boardModel?.data?.boards != null && boardModel!.data!.boards!.isNotEmpty) {
          boardId = boardModel!.data!.boards!.first.id!;
          board = boardModel!.data!.boards!.first.name ?? "";
        }

        debugPrint("✅ Loaded ${boardModel?.data?.boards?.length ?? 0} boards");
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load boards: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint('❌ Error fetching board data: $e');
    }
  }

  void setSelectedBoard(int id, String boardName) {
    boardId = id;
    board = boardName;

    // Clear dependent selections when board changes
    subjectId = 0;
    gradeId = 0;
    subjectGradePairsWithPdf.clear();
    pblMappingResponse = null;
    subjectToGradesMap.clear();

    debugPrint("🎯 Board changed to: $board (ID: $boardId)");
    notifyListeners();
  }

  /// ----------------- TEACHER SUBJECT GRADE -----------------
  Future<void> getTeacherSubjectGrade() async {
    try {
      final response = await TeacherDashboardService().getTeacherSubjectGrade();
      if (response != null && response.statusCode == 200) {
        teacherSubjectGradeModel = TeacherSubjectGradeModel.fromJson(response.data);

        // Debug prints
        debugPrint("Total pairs: ${teacherSubjectGradeModel?.subjectGradePairs?.length ?? 0}");
        notifyListeners();
      } else {
        debugPrint("Failed to fetch teacher subject-grade data: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("Error in getTeacherSubjectGrade: $e");
    }
  }

  void clearSubjectGradeSelection() {
    subjectId = 0;
    gradeId = 0;
    notifyListeners();
  }

  /// ----------------- PBL FUNCTIONS -----------------
  List<TeacherSubjectGradePair> getCombinedSubjectGradePairs() {
    final List<TeacherSubjectGradePair> combinedPairs = [];
    final Set<String> uniqueKeys = {};

    for (final pair in subjectGradePairsWithPdf) {
      final subjectId = pair.subject?.id ?? 0;
      final gradeId = pair.grade?.id ?? 0;
      final uniqueKey = '$subjectId-$gradeId';

      // Only add if we haven't seen this combination before
      if (!uniqueKeys.contains(uniqueKey)) {
        uniqueKeys.add(uniqueKey);
        combinedPairs.add(pair);
      }
    }

    return combinedPairs;
  }

  List<TeacherSubjectGradePair> get combinedSubjectGradePairs => getCombinedSubjectGradePairs();

  Future<void> getPblTextbookMappings({
    required int laSubjectId,
    required int laGradeId,
  }) async {
    try {
      Map<String, dynamic> body = {
        "language_id": pblLanguageId, // Use PBL language ID
        "la_board_id": boardId,
        "la_subject_id": laSubjectId,
        "la_grade_id": laGradeId,
      };

      debugPrint("Loading PDF mappings with: $body");

      final response = await TeacherDashboardService().postPblTextbookMappings(body);

      if (response != null && response.statusCode == 200) {
        pblMappingResponse = PblTextbookMappingResponse.fromJson(response.data);
        debugPrint("✅ Loaded ${pdfMappings.length} PDF mappings for board: $board");
      } else {
        pblMappingResponse = null;
        debugPrint("❌ No PDF mappings found for the selected criteria: ${response?.statusCode}");
      }
    } catch (e) {
      pblMappingResponse = null;
      debugPrint("❌ PBL Mapping Provider Error: $e");
    }

    notifyListeners();
  }

  void clearPblMapping() {
    pblMappingResponse = null;
    subjectId = 0;
    gradeId = 0;
    subjectToGradesMap.clear();
    notifyListeners();
  }

  /// ----------------- DASHBOARD -----------------
  Future<void> getDashboardData() async {
    try {
      Response? response = await DashboardServices().getDashboardData();
      if (response != null && response.statusCode == 200) {
        dashboardModel = DashboardModel.fromJson(response.data);

        // Safely parse boardId from dashboard
        boardId = int.tryParse(dashboardModel?.data?.user?.la_board_id ?? '');

        // Set board name if available
        if (dashboardModel?.data?.user?.board_name != null &&
            dashboardModel!.data!.user!.board_name!.isNotEmpty) {
          board = dashboardModel!.data!.user!.board_name!;
        }

        debugPrint("✅ Dashboard loaded - Board: $board, BoardID: $boardId");
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load dashboard: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading dashboard: $e");
    }
  }

  Future<void> getSubjectsData() async {
    try {
      Response? response = await TeacherDashboardService().getSubject(); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        subjectModel = SubjectModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load subjects: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading subjects: $e");
    }
  }

  void getLevel() async {
    try {
      Response? response = await LevelListService().getLevelData(); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        levels = LevelModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load levels: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading levels: $e");
    }
  }

  void getCompetency({required Map<String, dynamic> body}) async {
    try {
      Response? response = await TeacherDashboardService().getCompetencies(body); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        competenciesModel = CompetenciesModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load competencies: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading competencies: $e");
    }
  }

  void getConceptCartoon({required Map<String, dynamic> body}) async {
    try {
      Response? response = await TeacherDashboardService().getConceptCartoon(body); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        cartoonModel = ConceptCartoonModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load concept cartoons: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading concept cartoons: $e");
    }
  }

  void getConceptCartoonHeader() async {
    try {
      Response? response = await TeacherDashboardService().getConceptCartoonHeader(); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        headerModel = ConceptCartoonHeaderModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load concept cartoon headers: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading concept cartoon headers: $e");
    }
  }

  void getAssessment({required Map<String, dynamic> body}) async {
    try {
      Response? response = await TeacherDashboardService().getAssessment(body); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        assessmentModel = AssessmentModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load assessments: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading assessments: $e");
    }
  }

  void getWorkSheet({required Map<String, dynamic> body}) async {
    try {
      Response? response = await TeacherDashboardService().getWorkSheet(body); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        workSheetModel = WorkSheetModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load worksheets: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading worksheets: $e");
    }
  }

  /// ----------------- LANGUAGE MANAGEMENT -----------------
  Future<void> getLanguage() async {
    try {
      Response? response = await TeacherDashboardService().getLessonLanguage(); // Change to Response?
      if (response != null && response.statusCode == 200) { // Add null check
        languageModel = LanguageModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load languages: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading languages: $e");
    }
  }

  void setSelectedLanguage(int id, String languageName) {
    languageId = id;
    language = languageName;
    debugPrint("🎯 Language changed to: $language (ID: $languageId)");
    notifyListeners();
  }

  /// ----------------- LESSON PLAN -----------------
  Future<void> submitPlan({required BuildContext context, required String type}) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor),
      overlayColor: Colors.black54,
    );

    try {
      Map<String, dynamic> body = {
        "type": type,
        "la_board_id": boardId,
        "la_lession_plan_language_id": languageId,
      };

      Response? response = await TeacherDashboardService().submitPlan(body); // Change to Response?

      Loader.hide();

      if (response != null && response.statusCode == 200) { // Add null check
        lessonPlanModel = LessonPlanModel.fromJson(response.data);
        if (context.mounted && lessonPlanModel!.data!.laLessionPlans!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LessonDownloadPage(model: lessonPlanModel!)),
          );
        } else {
          Fluttertoast.showToast(msg: "No data available");
        }
      } else {
        lessonPlanModel = null;
        Fluttertoast.showToast(msg: "Failed to load lesson plans: ${response?.statusCode}");
      }
      notifyListeners();
    } catch (e) {
      Loader.hide();
      debugPrint("❌ Error submitting lesson plan: $e");
      Fluttertoast.showToast(msg: "Error loading lesson plans");
    }
  }

  void clearLessonPlan() {
    language = "";
    languageId = 0;
    lessonPlanModel = null;
    notifyListeners();
  }

  /// ----------------- RESET METHODS -----------------
  void resetAllSelections() {
    subjectId = 0;
    gradeId = 0;
    subjectGradePairsWithPdf.clear();
    pblMappingResponse = null;
    subjectToGradesMap.clear();
    notifyListeners();
  }

  void resetBoardSelection() {
    board = "";
    boardId = 0;
    resetAllSelections();
  }

  void resetLanguageSelection() {
    language = "";
    languageId = 0;
    resetAllSelections();
  }

  void resetPblLanguageSelection() {
    pblSelectedLanguage = "";
    pblLanguageId = 0;
    notifyListeners();
  }

  /// ----------------- VALIDATION METHODS -----------------
  bool get isBoardSelected => boardId != null && boardId! > 0 && board.isNotEmpty;
  bool get isLanguageSelected => languageId > 0 && language.isNotEmpty;
  bool get isPblLanguageSelected => pblLanguageId > 0 && pblSelectedLanguage.isNotEmpty;
  bool get isSubjectSelected => subjectId > 0;
  bool get isGradeSelected => gradeId > 0;

  bool get canProceedToSubjects => isBoardSelected && isPblLanguageSelected;
  bool get canProceedToGrades => isSubjectSelected;
  bool get canProceedToPdfs => isGradeSelected;

  /// ----------------- DEBUG METHODS -----------------
  void printCurrentState() {
    debugPrint("=== CURRENT STATE ===");
    debugPrint("Board: $board (ID: $boardId)");
    debugPrint("Language: $language (ID: $languageId)");
    debugPrint("PBL Language: $pblSelectedLanguage (ID: $pblLanguageId)");
    debugPrint("Subject ID: $subjectId");
    debugPrint("Grade ID: $gradeId");
    debugPrint("Available Boards: ${availableBoards.length}");
    debugPrint("Available PBL Languages: ${availablePblLanguages.length}");
    debugPrint("Subject-Grade Pairs: ${subjectGradePairs.length}");
    debugPrint("PDF Mappings: ${pdfMappings.length}");
    debugPrint("Subject-Grade Map entries: ${subjectToGradesMap.length}");
    debugPrint("=====================");
  }
}