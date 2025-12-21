import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/student/home/models/dashboard_model.dart';
import 'package:lifelab3/src/student/home/models/subject_model.dart' as DashboardModels;
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
import '../model/pbl_loading_state.dart';

class TeacherDashboardProvider extends ChangeNotifier {
  // ----------------- STATE MANAGEMENT -----------------
  DashboardModel? dashboardModel;
  DashboardModels.SubjectModel? subjectModel;
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

  // ----------------- LOADING STATES -----------------
  PblLoadingState pblLoadingState = PblLoadingState.initial;
  bool _isLoadingDashboard = false;
  bool _dashboardLoaded = false;
  String? _dashboardError;

  // ----------------- SELECTION STATES -----------------
  String board = "";
  String language = "";
  int? boardId = 0;
  int languageId = 0;
  PblTextbookMappingResponse? pblMappingResponse;
  String title = "";
  int subjectId = 0;
  int gradeId = 0;

  // ----------------- PBL LANGUAGE -----------------
  PblLanguageModel? pblLanguageModel;
  String pblSelectedLanguage = "";
  int pblLanguageId = 0;

  // ----------------- ALL SUBJECTS & GRADES -----------------
  List<DashboardModels.Subject> allSubjects = [];
  List<LaGrade> allGrades = [];

  // ----------------- FILTER STATES -----------------
  int filterSubjectId = 0;
  int filterGradeId = 0;

  // ----------------- SUBJECT-GRADE MAPPING -----------------
  Map<int, List<TeacherSubjectGradePair>> subjectToGradesMap = {};
  List<TeacherSubjectGradePair> subjectGradePairsWithPdf = [];

  // ----------------- PDF STORAGE -----------------
  List<PblTextbookMapping> allPblPdfs = [];
  Map<String, TeacherSubjectGradePair> pdfSubjectGradeMap = {};

  // ----------------- CURRENT API FILTERS -----------------
  int _currentApiSubjectId = 0;
  int _currentApiGradeId = 0;

  // ----------------- SUBSCRIPTION STATUS -----------------
  bool isTeacherLifeLabDemo = false;
  bool isTeacherJigyasa = false;
  bool isTeacherPragya = false;
  bool isTeacherLesson = false;
  bool hasSubscriptionData = false;

  // ----------------- GETTERS -----------------
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isDashboardLoaded => _dashboardLoaded;
  String? get dashboardError => _dashboardError;
  bool _hasInternet = true;

  void setInternetStatus(bool value) {
    _hasInternet = value;
  }

  List<TeacherSubjectGradePair> get subjectGradePairs =>
      teacherSubjectGradeModel?.subjectGradePairs ?? [];

  List<Board> get availableBoards => boardModel?.data?.boards ?? [];

  List<PblLanguageItem> get availablePblLanguages => pblLanguageModel?.data.pblLanguages ?? [];

  List<PblTextbookMapping> get pdfMappings =>
      pblMappingResponse?.data.pblTextbookMappings ?? [];

  List<PblTextbookMapping> getFilteredPdfs() {
    return allPblPdfs;
  }

  List<LaGrade> getAvailableGradesForSubject(int subjectId) {
    if (subjectId == 0) return [];

    final gradeIds = <int>{};
    for (final entry in pdfSubjectGradeMap.entries) {
      if (entry.value.subject?.id == subjectId && entry.value.grade?.id != null) {
        gradeIds.add(entry.value.grade!.id!);
      }
    }

    return allGrades.where((grade) => grade.id != null && gradeIds.contains(grade.id)).toList();
  }

  List<DashboardModels.Subject> getSubjectsWithPdfs() {
    final subjectIds = <int>{};
    for (final entry in pdfSubjectGradeMap.entries) {
      if (entry.value.subject?.id != null) {
        subjectIds.add(entry.value.subject!.id!);
      }
    }

    return allSubjects.where((subject) => subject.id != null && subjectIds.contains(subject.id)).toList();
  }

  List<LaGrade> getAllGradesWithPdfs() {
    final gradeIds = <int>{};
    for (final entry in pdfSubjectGradeMap.entries) {
      if (entry.value.grade?.id != null) {
        gradeIds.add(entry.value.grade!.id!);
      }
    }

    return allGrades.where((grade) => grade.id != null && gradeIds.contains(grade.id)).toList();
  }

  bool hasPdfsForSubjectGrade(int subjectId, int gradeId) {
    return allPblPdfs.any((pdf) {
      final pair = pdfSubjectGradeMap['${pdf.id}'];
      return pair != null &&
          pair.subject?.id == subjectId &&
          pair.grade?.id == gradeId;
    });
  }

  /// ================= SETTERS =================

  void setSubjectGradePairsWithPdf(List<TeacherSubjectGradePair> pairs) {
    subjectGradePairsWithPdf = pairs;
    notifyListeners();
  }

  void setAllPblPdfs(List<PblTextbookMapping> pdfs) {
    allPblPdfs = pdfs;
    notifyListeners();
  }

  void setPdfSubjectGradeMap(Map<String, TeacherSubjectGradePair> map) {
    pdfSubjectGradeMap = map;
    notifyListeners();
  }

  void setSubjectToGradesMap(Map<int, List<TeacherSubjectGradePair>> map) {
    subjectToGradesMap = map;
    notifyListeners();
  }

  /// ================= FILTER METHODS =================

  void setFilterSubjectId(int id) {
    filterSubjectId = id;
    notifyListeners();

    if (pblLanguageId > 0 && boardId != null && boardId! > 0) {
      _applyFiltersViaApi();
    }
  }

  void setFilterGradeId(int id) {
    filterGradeId = id;
    notifyListeners();

    if (pblLanguageId > 0 && boardId != null && boardId! > 0) {
      _applyFiltersViaApi();
    }
  }

  void resetPblFilters() {
    filterSubjectId = 0;
    filterGradeId = 0;
    notifyListeners();

    if (pblLanguageId > 0 && boardId != null && boardId! > 0) {
      loadAllPblPdfs();
    }
  }

  /// ================= API METHODS =================

  Future<void> getDashboardData() async {
    // 🔒 HARD GUARD: do NOT enter loading if no internet
    if (!_hasInternet) {
      _isLoadingDashboard = false;
      _dashboardLoaded = false;
      _dashboardError = "No internet connection";
      notifyListeners();
      return;
    }

    try {
      _isLoadingDashboard = true;
      _dashboardError = null;
      notifyListeners();

      Response? response = await DashboardServices().getDashboardData();

      if (response != null && response.statusCode == 200) {
        dashboardModel = DashboardModel.fromJson(response.data);

        // ---- Board info ----
        boardId = int.tryParse(
          dashboardModel?.data?.user?.la_board_id ?? '',
        );

        if (dashboardModel?.data?.user?.board_name != null &&
            dashboardModel!.data!.user!.board_name!.isNotEmpty) {
          board = dashboardModel!.data!.user!.board_name!;
        }

        // ---- Subscription (safe call) ----
        if (_hasInternet) {
          await fetchSubscriptionData();
        }

        _dashboardLoaded = true;
        _dashboardError = null;
      } else {
        _dashboardLoaded = false;
        _dashboardError =
        "Failed to load dashboard (${response?.statusCode ?? 'No response'})";
      }
    } catch (e) {
      // ❌ Any error (network / parsing / timeout)
      _dashboardLoaded = false;
      _dashboardError = "Error loading dashboard";
      debugPrint("❌ Dashboard error: $e");
    } finally {
      // 🔥 ALWAYS reset loading (THIS PREVENTS INFINITE SPINNER)
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubscriptionData() async {
    try {
      Response? response = await DashboardServices().checkSubscription();

      if (response != null && response.statusCode == 200) {
        final data = response.data["data"];

        isTeacherLifeLabDemo = data["LIFE_LAB_DEMO_MODELS"] == 1;
        isTeacherJigyasa = data["JIGYASA_SELF_DIY_ACTVITES"] == 1;
        isTeacherPragya = data["PRAGYA_DIY_ACTIVITES_WITH_LIFE_LAB_KITS"] == 1;
        isTeacherLesson = data["LIFE_LAB_ACTIVITIES_LESSION_PLANS"] == 1;

        hasSubscriptionData = true;

        notifyListeners();
      } else {
        debugPrint("❌ Failed to load subscription data: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching subscription data: $e");
    }
  }

  Future<void> getAllSubjects() async {
    try {
      final response = await TeacherDashboardService().getAllSubjects();
      if (response != null && response.statusCode == 200) {
        subjectModel = DashboardModels.SubjectModel.fromJson(response.data);
        allSubjects = subjectModel?.data?.subject ?? [];
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load all subjects: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching all subjects: $e");
    }
  }

  Future<void> getAllGrades() async {
    try {
      final response = await TeacherDashboardService().getAllGrades();
      if (response != null && response.statusCode == 200) {
        gradeModel = GradeModel.fromJson(response.data);
        allGrades = gradeModel?.data?.laGrades ?? [];
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load all grades: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching all grades: $e");
    }
  }

  Future<void> getTeacherSubjectGrade() async {
    try {
      final response = await TeacherDashboardService().getTeacherSubjectGrade();
      if (response != null && response.statusCode == 200) {
        teacherSubjectGradeModel = TeacherSubjectGradeModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to fetch teacher subject-grade data: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error in getTeacherSubjectGrade: $e");
    }
  }

  Future<void> loadAllPblPdfs() async {
    pblLoadingState = PblLoadingState.loading;
    notifyListeners();

    try {
      await getAllSubjects();
      await getAllGrades();
      await getTeacherSubjectGrade();
      await getPblTextbookMappings();

      if (pdfMappings.isEmpty) {
        pblLoadingState = PblLoadingState.loaded;
        notifyListeners();
        return;
      }

      allPblPdfs = List.from(pdfMappings);
      _buildPdfSubjectGradeMap();

      pblLoadingState = PblLoadingState.loaded;
      notifyListeners();

    } catch (e) {
      debugPrint("❌ Error loading PDFs: $e");
      pblLoadingState = PblLoadingState.error;
      notifyListeners();
    }
  }

  Future<void> getPblTextbookMappings({int? laSubjectId, int? laGradeId}) async {
    try {
      Map<String, dynamic> body = {
        "language_id": pblLanguageId,
        "la_board_id": boardId,
      };

      if (laSubjectId != null && laSubjectId > 0) {
        body["la_subject_id"] = laSubjectId;
        _currentApiSubjectId = laSubjectId;
      } else {
        _currentApiSubjectId = 0;
      }

      if (laGradeId != null && laGradeId > 0) {
        body["la_grade_id"] = laGradeId;
        _currentApiGradeId = laGradeId;
      } else {
        _currentApiGradeId = 0;
      }

      final response = await TeacherDashboardService().postPblTextbookMappings(body);

      if (response != null && response.statusCode == 200) {
        pblMappingResponse = PblTextbookMappingResponse.fromJson(response.data);
      } else {
        pblMappingResponse = null;
      }
    } catch (e) {
      pblMappingResponse = null;
      debugPrint("❌ PBL Mapping API Error: $e");
    }

    notifyListeners();
  }

  Future<void> _applyFiltersViaApi() async {
    pblLoadingState = PblLoadingState.loading;
    notifyListeners();

    try {
      await getPblTextbookMappings(
        laSubjectId: filterSubjectId > 0 ? filterSubjectId : null,
        laGradeId: filterGradeId > 0 ? filterGradeId : null,
      );

      allPblPdfs = List.from(pdfMappings);
      _buildPdfSubjectGradeMap();

      pblLoadingState = PblLoadingState.loaded;
      notifyListeners();

    } catch (e) {
      debugPrint("❌ Error applying filters: $e");
      pblLoadingState = PblLoadingState.error;
      notifyListeners();
    }
  }

  void _buildPdfSubjectGradeMap() {
    pdfSubjectGradeMap.clear();
    subjectGradePairsWithPdf.clear();

    for (final pdf in allPblPdfs) {
      final subject = allSubjects.firstWhere(
            (s) => s.id == pdf.subject.id,
        orElse: () => DashboardModels.Subject(
          id: pdf.subject.id,
          title: "Subject ${pdf.subject.id}",
        ),
      );

      final grade = allGrades.firstWhere(
            (g) => g.id == pdf.grade.id,
        orElse: () => LaGrade(
          id: pdf.grade.id,
          name: "Grade ${pdf.grade.id}",
        ),
      );

      final pair = TeacherSubjectGradePair(
        subject: TeacherSubject(
          id: subject.id,
          title: subject.title,
        ),
        grade: TeacherGrade(
          id: grade.id,
          name: grade.name,
        ),
      );

      pdfSubjectGradeMap['${pdf.id}'] = pair;

      if (!subjectGradePairsWithPdf.any((existingPair) =>
      existingPair.subject?.id == pair.subject?.id &&
          existingPair.grade?.id == pair.grade?.id)) {
        subjectGradePairsWithPdf.add(pair);
      }
    }
  }

  Future<void> getPblLanguages() async {
    try {
      final response = await TeacherDashboardService().getPblLanguages();
      if (response != null && response.statusCode == 200) {
        pblLanguageModel = PblLanguageModel.fromJson(response.data);

        if (pblLanguageModel?.data.pblLanguages != null &&
            pblLanguageModel!.data.pblLanguages.isNotEmpty) {
          final englishLang = pblLanguageModel!.data.pblLanguages.firstWhere(
                (lang) => (lang.pblLangSlug ?? '').toLowerCase() == 'en',
            orElse: () => pblLanguageModel!.data.pblLanguages.first,
          );

          pblLanguageId = englishLang.pblLangId ?? 0;
          pblSelectedLanguage = englishLang.pblLangTitle ?? englishLang.pblLangName ?? '';
        }

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
    notifyListeners();
  }

  Future<void> getBoard() async {
    try {
      Response? response = await TeacherSignUpServices().getBoard();
      if (response != null && response.statusCode == 200) {
        boardModel = BoardModel.fromJson(response.data);

        if (boardId == 0 && boardModel?.data?.boards != null && boardModel!.data!.boards!.isNotEmpty) {
          boardId = boardModel!.data!.boards!.first.id!;
          board = boardModel!.data!.boards!.first.name ?? "";
        }

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
    clearPblSelections();
    notifyListeners();
  }

  Future<void> getSubjectsData() async {
    try {
      Response? response = await TeacherDashboardService().getSubject();
      if (response != null && response.statusCode == 200) {
        subjectModel = DashboardModels.SubjectModel.fromJson(response.data);
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
      Response? response = await LevelListService().getLevelData();
      if (response != null && response.statusCode == 200) {
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
      Response? response = await TeacherDashboardService().getCompetencies(body);
      if (response != null && response.statusCode == 200) {
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
      Response? response = await TeacherDashboardService().getConceptCartoon(body);
      if (response != null && response.statusCode == 200) {
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
      Response? response = await TeacherDashboardService().getConceptCartoonHeader();
      if (response != null && response.statusCode == 200) {
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
      Response? response = await TeacherDashboardService().getAssessment(body);
      if (response != null && response.statusCode == 200) {
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
      Response? response = await TeacherDashboardService().getWorkSheet(body);
      if (response != null && response.statusCode == 200) {
        workSheetModel = WorkSheetModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load worksheets: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading worksheets: $e");
    }
  }

  Future<void> getLanguage() async {
    try {
      Response? response = await TeacherDashboardService().getLessonLanguage();
      if (response != null && response.statusCode == 200) {
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
    notifyListeners();
  }

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

      Response? response = await TeacherDashboardService().submitPlan(body);

      Loader.hide();

      if (response != null && response.statusCode == 200) {
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

  /// ================= CLEAR METHODS =================

  void clearSubjectGradeSelection() {
    subjectId = 0;
    gradeId = 0;
    notifyListeners();
  }

  void clearPblSelections() {
    subjectId = 0;
    gradeId = 0;
    subjectGradePairsWithPdf.clear();
    pblMappingResponse = null;
    subjectToGradesMap.clear();
    allPblPdfs.clear();
    pdfSubjectGradeMap.clear();
    resetPblFilters();
    notifyListeners();
  }

  void clearPblMapping() {
    pblMappingResponse = null;
    clearPblSelections();
  }

  void clearLessonPlan() {
    language = "";
    languageId = 0;
    lessonPlanModel = null;
    notifyListeners();
  }

  void resetAllSelections() {
    clearPblSelections();
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

  /// ================= VALIDATION METHODS =================

  bool get isBoardSelected => boardId != null && boardId! > 0 && board.isNotEmpty;
  bool get isLanguageSelected => languageId > 0 && language.isNotEmpty;
  bool get isPblLanguageSelected => pblLanguageId > 0 && pblSelectedLanguage.isNotEmpty;
  bool get isSubjectSelected => subjectId > 0;
  bool get isGradeSelected => gradeId > 0;

  bool get canProceedToSubjects => isBoardSelected && isPblLanguageSelected;
  bool get canProceedToGrades => isSubjectSelected;
  bool get canProceedToPdfs => isGradeSelected;

  /// ================= REFRESH METHODS =================

  Future<void> refreshAllData() async {
    if (!_hasInternet) {
      _isLoadingDashboard = false;
      _dashboardError = "No internet connection";
      notifyListeners();
      return;
    }

    _dashboardLoaded = false;
    await getDashboardData();
  }

  TeacherSubjectGradePair? getSubjectGradeInfoForPdf(PblTextbookMapping pdf) {
    return pdfSubjectGradeMap['${pdf.id}'];
  }
}