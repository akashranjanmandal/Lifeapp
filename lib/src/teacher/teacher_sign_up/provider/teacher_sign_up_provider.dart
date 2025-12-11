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

  int boardId = 0;
  int? sectionId;
  bool isSchoolCodeValid = false;

  List<int> gradeList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  /// GRADE-SECTION-SUBJECT LIST (for API)
  List<Map<String, dynamic>> gradeMapList = [
    {"la_grade_id": "", "la_section_id": "", "subjects": "", "la_section_name": "", "subject_name": ""}
  ];

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
    int index1 = listOfLocation.indexWhere(
            (e) => e.stateName!.toLowerCase() == stateController.text.toLowerCase());
    cityList = listOfLocation[index1].cities!;
    searchCityList = searchListOfLocation[index].cities!;
    notifyListeners();
  }

  // ---------- VALIDATION ----------
  bool get isGradeListValid => gradeMapList.every((e) =>
  e["la_grade_id"].toString().isNotEmpty &&
      e["la_section_id"].toString().isNotEmpty &&
      e["subjects"].toString().isNotEmpty
  );

  void sanitizeClassList() {
    for (var g in gradeMapList) {
      g.remove("la_section_name");
      g.remove("subject_name");
      g["la_grade_id"] = int.parse(g["la_grade_id"].toString());
      g["la_section_id"] = int.parse(g["la_section_id"].toString());
      g["subjects"] = int.parse(g["subjects"].toString());
    }
  }

  // ---------- REGISTER TEACHER ----------
  void registerStudent(BuildContext context, String contact) async {
    debugPrint("📌 SIGNUP BUTTON PRESSED");

    // City is optional (backend accepts blank)
    if (!isSchoolCodeValid ||
        teacherNameController.text.trim().isEmpty ||
        schoolNameController.text.trim().isEmpty ||
        stateController.text.trim().isEmpty ||
        !isGradeListValid) {
      Fluttertoast.showToast(msg: StringHelper.invalidData);
      return;
    }

    sanitizeClassList();

    Map<String, dynamic> body = {
      "mobile_no": contact,
      "type": 5,
      "name": teacherNameController.text.trim(),
      "school": schoolNameController.text.trim(),
      "school_code": int.parse(schoolCodeController.text),
      "state": stateController.text.trim(),
      "city": cityController.text.trim(),   // can be ""
      "la_board_id": boardId == 0 ? null : boardId,
      "device_token": StorageUtil.getString(StringHelper.fcmToken),
      "grades": gradeMapList,
    };

    Loader.show(context,
        progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor),
        overlayColor: Colors.black54
    );

    Response? response = await TeacherSignUpServices().registerStudent(body);

    Loader.hide();

    if (response != null && response.statusCode == 200) {
      RegisterStudentModel model = RegisterStudentModel.fromJson(response.data);
      StorageUtil.putBool(StringHelper.isTeacher, true);
      StorageUtil.putString(StringHelper.token, model.data!.user!.token!);
      if (!context.mounted) return;
      pushRemoveUntil(context: context, page: const TeacherDashboardPage());
    }
  }

  // ---------- VERIFY SCHOOL ----------
  void verifySchoolCode(BuildContext context) async {
    Loader.show(context,
        progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor),
        overlayColor: Colors.black54
    );

    Response response = await SignUpServices().verifyCode(schoolCodeController.text);

    Loader.hide();

    if (response.statusCode == 200) {
      isSchoolCodeValid = true;
      verifySchoolModel = VerifySchoolModel.fromJson(response.data);
      schoolNameController.text = verifySchoolModel!.data!.school!.name!;
      stateController.text = verifySchoolModel!.data!.school!.state!;
      cityController.text = verifySchoolModel!.data!.school!.city ?? ""; // allow blank city
    } else {
      isSchoolCodeValid = false;
      schoolCodeController.clear();
      schoolNameController.clear();
      stateController.clear();
      cityController.clear();
    }

    notifyListeners();
  }
}
