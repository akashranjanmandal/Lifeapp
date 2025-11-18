import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/student/home/models/subject_model.dart';
import 'package:lifelab3/src/student/sign_up/model/section_model.dart';
import 'package:lifelab3/src/student/subject_level_list/models/level_model.dart';
import 'package:lifelab3/src/student/subject_level_list/models/mission_list_model.dart';
import 'package:lifelab3/src/student/subject_level_list/models/quiz_topic_model.dart';
import 'package:lifelab3/src/teacher/teacher_tool/model/all_student_report_model.dart';
import 'package:lifelab3/src/teacher/teacher_tool/model/class_student_model.dart';
import 'package:lifelab3/src/teacher/teacher_tool/services/tool_services.dart';

import '../../../common/helper/color_code.dart';
import '../../../student/home/services/dashboard_services.dart';
import '../../../student/sign_up/services/sign_up_services.dart';
import '../../../student/subject_level_list/service/level_list_service.dart';
import '../../student_progress/model/teacher_grade_section_model.dart';

class ToolProvider extends ChangeNotifier {

  SectionModel? sectionModel;
  LevelModel? level;
  MissionListModel? missionListModel;
  SubjectModel? subjectModel;
  ClassStudentModel? classStudentModel;
  QuizTopicModel? topicModel;
  AllStudentReportModel? allStudentReportModel;
  TeacherGradeSectionModel? teacherGradeSectionModel;

  TextEditingController dateController = TextEditingController();
  DateTime currentDate = DateTime.now();

  Future<void> getSectionList() async {

    Response response = await SignUpServices().getSectionList();

    if(response.statusCode == 200) {
      sectionModel = SectionModel.fromJson(response.data);
      notifyListeners();
    }
  }

  void getLevel() async {
    Response response = await LevelListService().getLevelData();

    if(response.statusCode == 200) {
      level = LevelModel.fromJson(response.data);
      notifyListeners();
    }
  }

  Future<void> getSubjectsData() async {
    Response response = await DashboardServices().getSubjectData();

    if(response.statusCode == 200) {
      subjectModel = SubjectModel.fromJson(response.data);
      notifyListeners();
    }
  }

  void getMission(Map<String, dynamic> data) async {
    int type = data["type"] ?? 1; // default to 1 if not provided
    String? subjectId = data["la_subject_id"];
    String? levelId = data["la_level_id"];

    Response response = await LevelListService().getMissionData(
      type: type,
      subjectId: subjectId,
      levelId: levelId,
    );

    if (response.statusCode == 200) {
      missionListModel = MissionListModel.fromJson(response.data);
    } else {
      missionListModel = null;
    }
    notifyListeners();
  }

  Future<void> getStudentList(Map<String, dynamic> data) async {

    Response response = await ToolServices().getStudentList(data);

    if(response.statusCode == 200) {
      classStudentModel = ClassStudentModel.fromJson(response.data);
      notifyListeners();
    }
  }

  void getTopic(String type) async {
    Response response = await ToolServices().getTopicData(type);

    if(response.statusCode == 200) {
      topicModel = QuizTopicModel.fromJson(response.data);
    } else {
      topicModel = null;
    }
    notifyListeners();
  }
  Future<bool> assignMission(BuildContext context, Map<String, dynamic> data)
  async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor),
      overlayColor: Colors.black54,
    );

    Response response = await ToolServices().assignStudent(data);

    Loader.hide();

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: "Submitted");
      return true; // ✅ success
    }
    return false; // ✅ failure
  }

  Future<bool> assignTopic(BuildContext context, Map<String, dynamic> data) async {
    // 🟢 Log the payload before sending
    print("📤 [AssignTopic] Sending payload: $data");

    try {
      Loader.show(
        context,
        progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor),
        overlayColor: Colors.black54,
      );

      // 🟣 API call
      final response = await ToolServices().assignTopic(data);

      // 🟡 Log the raw response
      print("📥 [AssignTopic] Response received: ${response.data}");
      print("🔢 [AssignTopic] Status code: ${response.statusCode}");

      Loader.hide();

      // ✅ Success
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Submitted Successfully ✅");
        print("✅ [AssignTopic] Success! Topic assigned successfully.");
        return true;
      } else {
        // ❌ Server returned error
        print("❌ [AssignTopic] Failed with status: ${response.statusCode}");
        print("❌ [AssignTopic] Message: ${response.data}");
        Fluttertoast.showToast(msg: "Failed: ${response.data?['message'] ?? 'Unknown error'}");
        return false;
      }
    } catch (e, stack) {
      // 🔴 Log any exceptions
      Loader.hide();
      print("🧨 [AssignTopic] Exception occurred: $e");
      print("📜 [AssignTopic] Stack trace: $stack");
      Fluttertoast.showToast(msg: "Error occurred: $e");
      return false;
    }
  }


  void getTeacherGrade() async {
    Response response = await ToolServices().getTeacherGrade();

    if(response.statusCode == 200) {
      teacherGradeSectionModel = TeacherGradeSectionModel.fromJson(response.data);
      notifyListeners();
    } else {
      teacherGradeSectionModel = null;
    }
  }

}