import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/student/home/models/subject_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/model/board_model.dart';

import '../../../common/helper/color_code.dart';
import '../../../common/helper/string_helper.dart';
import '../../../common/widgets/common_navigator.dart';
import '../../../student/sign_up/model/register_student_model.dart';
import '../../../student/sign_up/model/school_list_model.dart';
import '../../../student/sign_up/model/section_model.dart';
import '../../../student/sign_up/model/state_city_model.dart';
import '../../../student/sign_up/model/verify_school_model.dart';
import '../../../student/sign_up/services/sign_up_services.dart';
import '../../../utils/storage_utils.dart';
import '../services/teacher_sign_up_services.dart';

class TeacherSignUpProvider extends ChangeNotifier {
  // -------- API MODELS --------
  SchoolListModel? schoolListModel;
  SectionModel? sectionModel;
  BoardModel? boardModel;
  SubjectModel? subjectModel;
  VerifySchoolModel? verifySchoolModel;

  // -------- DROPDOWN DATA --------
  List<StateCityListModel> listOfLocation = [];
  List<StateCityListModel> searchListOfLocation = [];
  List<City> cityList = [];
  List<City> searchCityList = [];

  // -------- CONTROLLERS --------
  TextEditingController teacherNameController = TextEditingController();
  TextEditingController dobController = TextEditingController(); // Added DOB controller
  TextEditingController schoolNameController = TextEditingController();
  TextEditingController schoolCodeController = TextEditingController();
  TextEditingController boardNameController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  // UI-SIDE controllers for sheets
  TextEditingController gradeController = TextEditingController();
  TextEditingController sectionController = TextEditingController();
  TextEditingController subjectController = TextEditingController();
  TextEditingController stateSearchCont = TextEditingController();
  TextEditingController citySearchCont = TextEditingController();

  // -------- SELECTION STATES --------
  int boardId = 0;
  int? selectedBoardId;
  int? sectionId;
  bool isSchoolCodeValid = false;
  DateTime? selectedDate; // Added for DOB

  List<int> gradeList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  /// GRADE-SECTION-SUBJECT LIST (for API)
  List<Map<String, dynamic>> gradeMapList = [
    {
      "la_grade_id": "",
      "la_section_id": "",
      "subjects": "",
      "la_section_name": "",
      "subject_name": ""
    }
  ];

  // ---------- DOB METHODS ----------
  void setSelectedDate(DateTime date) {
    selectedDate = date;
    dobController.text =
    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    notifyListeners();
  }

  void clearDob() {
    dobController.clear();
    selectedDate = null;
    notifyListeners();
  }

  String getFormattedDob() {
    if (selectedDate == null) return '';
    return "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
  }

  // ---------- VALIDATION ----------
  String? validateForm() {
    if (teacherNameController.text.isEmpty) {
      return "Please enter teacher name";
    }
    if (dobController.text.isEmpty) {
      return "Please select date of birth";
    }
    if (!isSchoolCodeValid) {
      return "Please verify school code";
    }
    if (gradeMapList.isEmpty ||
        gradeMapList[0]["la_grade_id"] == null ||
        gradeMapList[0]["la_grade_id"].toString().isEmpty) {
      return "Please add at least one grade-section-subject";
    }
    if (boardNameController.text.isEmpty) {
      return "Please select board";
    }
    return null;
  }

  bool get isGradeListValid => gradeMapList.every((e) =>
  e["la_grade_id"].toString().isNotEmpty &&
      e["la_section_id"].toString().isNotEmpty &&
      e["subjects"].toString().isNotEmpty);

  void sanitizeClassList() {
    for (var g in gradeMapList) {
      g.remove("la_section_name");
      g.remove("subject_name");
      g["la_grade_id"] = int.parse(g["la_grade_id"].toString());
      g["la_section_id"] = int.parse(g["la_section_id"].toString());
      g["subjects"] = int.parse(g["subjects"].toString());
    }
  }

  // ---------- CLEAR ALL ----------
  void clearAll() {
    teacherNameController.clear();
    dobController.clear();
    schoolCodeController.clear();
    schoolNameController.clear();
    stateController.clear();
    cityController.clear();
    boardNameController.clear();
    selectedBoardId = null;
    selectedDate = null;
    isSchoolCodeValid = false;
    gradeMapList.clear();
    gradeMapList.add({
      "la_grade_id": "",
      "la_section_id": "",
      "subjects": "",
      "la_section_name": "",
      "subject_name": ""
    });
    notifyListeners();
  }

  // ---------- API CALLS ----------
  Future<void> getSchoolList() async {
    Response? response = await TeacherSignUpServices().getSchoolList();
    if (response?.statusCode == 200) {
      schoolListModel = SchoolListModel.fromJson(response!.data);
      notifyListeners();
    }
  }

  Future<void> getSectionList() async {
    Response response = await SignUpServices().getSectionList();
    if (response.statusCode == 200) {
      sectionModel = SectionModel.fromJson(response.data);
      notifyListeners();
    }
  }

  Future<void> getBoard() async {
    Response response = await TeacherSignUpServices().getBoard();
    if (response.statusCode == 200) {
      boardModel = BoardModel.fromJson(response.data);
      notifyListeners();
    }
  }

  Future<void> subjects() async {
    Response response = await TeacherSignUpServices().subjects();
    if (response.statusCode == 200) {
      subjectModel = SubjectModel.fromJson(response.data);
      notifyListeners();
    }
  }

  Future<void> getStateCityList() async {
    Response? response = await TeacherSignUpServices().getStateList();
    if (response?.statusCode == 200) {
      for (var i in response!.data) {
        StateCityListModel data = StateCityListModel.fromJson(i);
        if (data.active == 1) {
          listOfLocation.add(data);
          searchListOfLocation.add(data);
        }
      }
      notifyListeners();
    }
  }

  void getCityData(int index) {
    int index1 = listOfLocation.indexWhere((e) =>
    e.stateName!.toLowerCase() == stateController.text.toLowerCase());
    cityList = listOfLocation[index1].cities!;
    searchCityList = searchListOfLocation[index].cities!;
    notifyListeners();
  }

  // ---------- REGISTER TEACHER ----------
  void registerStudent(BuildContext context, String contact) async {
    debugPrint("📌 TEACHER SIGNUP BUTTON PRESSED");

    // Debug: Check board selection
    debugPrint("🔍 Board ID check: selectedBoardId = $selectedBoardId");
    debugPrint("🔍 Board name: ${boardNameController.text}");

    // Validate form
    final validationError = validateForm();
    if (validationError != null) {
      Fluttertoast.showToast(msg: validationError);
      return;
    }

    // ADD THIS VALIDATION FOR BOARD
    if (selectedBoardId == null || selectedBoardId == 0) {
      Fluttertoast.showToast(msg: "Please select a board");
      return;
    }

    sanitizeClassList();

    Map<String, dynamic> body = {
      "mobile_no": contact,
      "name": teacherNameController.text,
      "type": 5,
      "school": schoolNameController.text,
      "school_code": int.tryParse(schoolCodeController.text) ?? 0,
      "la_board_id": selectedBoardId ?? 0, // Should not be 0
      "state": stateController.text,
      "city": cityController.text,
      "dob": getFormattedDob(),
      "grades": gradeMapList
          .where((e) =>
      e["la_grade_id"] != null &&
          e["la_grade_id"].toString().isNotEmpty &&
          e["la_section_id"] != null &&
          e["la_section_id"].toString().isNotEmpty &&
          e["subjects"] != null &&
          e["subjects"].toString().isNotEmpty)
          .map((e) => {
        "la_grade_id": int.tryParse(e["la_grade_id"].toString()) ?? 0,
        "la_section_id": int.tryParse(e["la_section_id"].toString()) ?? 0,
        "subjects": int.tryParse(e["subjects"].toString()) ?? 0,
      })
          .toList(),
    };

    Loader.show(
      context,
      progressIndicator:
      const CircularProgressIndicator(color: ColorCode.buttonColor),
      overlayColor: Colors.black54,
    );

    Response? response = await TeacherSignUpServices().registerStudent(body);

    Loader.hide();

    if (response != null && response.statusCode == 200) {
      RegisterStudentModel model =
      RegisterStudentModel.fromJson(response.data);
      StorageUtil.putBool(StringHelper.isTeacher, true);
      StorageUtil.putString(StringHelper.token, model.data!.user!.token!);
      if (!context.mounted) return;
      pushRemoveUntil(context: context, page: const TeacherDashboardPage());
    } else {
      Fluttertoast.showToast(msg: "Registration failed. Please try again.");
    }
  }

  // ---------- VERIFY SCHOOL ----------
  void verifySchoolCode(BuildContext context) async {
    if (schoolCodeController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter school code");
      return;
    }

    Loader.show(
      context,
      progressIndicator:
      const CircularProgressIndicator(color: ColorCode.buttonColor),
      overlayColor: Colors.black54,
    );

    Response response =
    await SignUpServices().verifyCode(schoolCodeController.text);

    Loader.hide();

    if (response.statusCode == 200) {
      isSchoolCodeValid = true;
      verifySchoolModel = VerifySchoolModel.fromJson(response.data);
      schoolNameController.text = verifySchoolModel!.data!.school!.name!;
      stateController.text = verifySchoolModel!.data!.school!.state!;
      cityController.text = verifySchoolModel!.data!.school!.city ?? "";
      Fluttertoast.showToast(msg: "School verified successfully!");
    } else {
      isSchoolCodeValid = false;
      schoolCodeController.clear();
      schoolNameController.clear();
      stateController.clear();
      cityController.clear();
      Fluttertoast.showToast(msg: "Invalid school code. Please try again.");
    }

    notifyListeners();
  }

// ---------- BOARD SELECTION ----------
  void setSelectedBoard(int id, String name) {
    selectedBoardId = id;
    boardNameController.text = name;

    // Add detailed debug
    debugPrint("🎯 setSelectedBoard called with:");
    debugPrint("   ID: $id");
    debugPrint("   Name: $name");
    debugPrint("   selectedBoardId is now: $selectedBoardId");
    debugPrint("   boardNameController.text is now: ${boardNameController.text}");

    notifyListeners();
  }

  // ---------- GRADE SELECTION ----------
  void setSelectedGrade(Map<String, dynamic> gradeMap, String grade) {
    final index = gradeMapList.indexOf(gradeMap);
    if (index != -1) {
      gradeMapList[index]["la_grade_id"] = grade;
      notifyListeners();
    }
  }

  // ---------- SECTION SELECTION ----------
  void setSelectedSection(
      Map<String, dynamic> gradeMap, String sectionId, String sectionName) {
    final index = gradeMapList.indexOf(gradeMap);
    if (index != -1) {
      gradeMapList[index]["la_section_id"] = sectionId;
      gradeMapList[index]["la_section_name"] = sectionName;
      notifyListeners();
    }
  }

  // ---------- SUBJECT SELECTION ----------
  void setSelectedSubject(
      Map<String, dynamic> gradeMap, String subjectId, String subjectName) {
    final index = gradeMapList.indexOf(gradeMap);
    if (index != -1) {
      gradeMapList[index]["subjects"] = subjectId;
      gradeMapList[index]["subject_name"] = subjectName;
      notifyListeners();
    }
  }

  // ---------- STATE SELECTION ----------
  void setSelectedState(String state) {
    stateController.text = state;
    cityController.clear();
    notifyListeners();
  }

  // ---------- CITY SELECTION ----------
  void setSelectedCity(String city) {
    cityController.text = city;
    notifyListeners();
  }
}