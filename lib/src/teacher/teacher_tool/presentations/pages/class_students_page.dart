import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class ClassStudentPage extends StatefulWidget {
  final String subjectId;
  final String sectionId;
  final String gradeId;
  final String missionId;
  final String type;

  const ClassStudentPage({
    super.key,
    required this.subjectId,
    required this.sectionId,
    required this.gradeId,
    required this.missionId,
    required this.type,
  });

  @override
  State<ClassStudentPage> createState() => _ClassStudentPageState();
}

class _ClassStudentPageState extends State<ClassStudentPage> {
  List<int> studentIdList = [];
  bool selectAll = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();

    _startTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Map<String, dynamic> data = {
        "school_id":
        Provider.of<TeacherDashboardProvider>(context, listen: false)
            .dashboardModel!
            .data!
            .user!
            .school!
            .id!,
        "la_grade_id": widget.gradeId,
        "la_subject_id": widget.subjectId,
        "la_section_id": widget.sectionId,
      };
      debugPrint("Data: $data");
      Provider.of<ToolProvider>(context, listen: false).getStudentList(data);
    });
  }

  @override
  void dispose() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      MixpanelService.track("Student selection for mission screen activity time", properties: {
        "duration_seconds": duration,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    MixpanelService.track("Back icon clicked", properties: {
      "timestamp": DateTime.now().toIso8601String(),
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToolProvider>(context);
    final studentList = provider.classStudentModel?.data?.users?.data ?? [];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: commonAppBar(context: context, name: "Submission"),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 50),
          child: CustomButton(
            name: "Assign selected",
            width: MediaQuery.of(context).size.width,
            height: 45,
            onTap: () {
              MixpanelService.track("Assign selected button clicked", properties: {
                "selected_student_count": studentIdList.length,
                "timestamp": DateTime.now().toIso8601String(),
              });

              if (studentIdList.isNotEmpty) {
                if (widget.type == "1") {
                  Map<String, dynamic> data = {
                    "la_mission_id": widget.missionId,
                    "user_ids": studentIdList,
                    "due_date": provider.dateController.text,
                  };
                  provider.assignMission(context, data);
                } else {
                  Map<String, dynamic> data = {
                    "la_topic_id": widget.missionId,
                    "user_ids": studentIdList,
                    "due_date": provider.dateController.text,
                    "type": widget.type,
                  };
                  provider.assignTopic(context, data);
                }
              } else {
                Fluttertoast.showToast(msg: "Please select student");
              }
            },
          ),
        ),
        body: provider.classStudentModel != null
            ? ListView.builder(
          shrinkWrap: true,
          itemCount: studentList.length + 1, // Add 1 for 'Assign All'
          itemBuilder: (context, index) {
            if (index == 0) {
              // Top Checkbox Row - Assign All Students
              return Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.select_all, color: Colors.black54),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Assign All Students",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Checkbox(
                      value: selectAll,
                      onChanged: (val) {
                        setState(() {
                          selectAll = val!;
                          studentIdList.clear();
                          if (selectAll) {
                            studentIdList.addAll(
                              studentList.map((e) => e.id!).toList(),
                            );
                          }
                        });

                        MixpanelService.track("Assign all students checked", properties: {
                          "checked": selectAll,
                          "timestamp": DateTime.now().toIso8601String(),
                        });
                      },
                    ),
                  ],
                ),
              );
            }

            final student = studentList[index - 1];
            final isChecked = studentIdList.contains(student.id);

            return Container(
              width: MediaQuery.of(context).size.width,
              margin:
              const EdgeInsets.only(left: 15, right: 15, bottom: 10),
              padding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  student.profileImage != null
                      ? CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                        ApiHelper.imgBaseUrl + student.profileImage!),
                  )
                      : const CircleAvatar(
                    radius: 20,
                    backgroundImage:
                    AssetImage(ImageHelper.profileIcon),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      student.name!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isChecked,
                    onChanged: (val) {
                      setState(() {
                        if (isChecked) {
                          studentIdList.remove(student.id!);
                          selectAll = false;
                        } else {
                          studentIdList.add(student.id!);
                          if (studentIdList.length == studentList.length) {
                            selectAll = true;
                          }
                        }
                      });

                      MixpanelService.track("Individual student checked", properties: {
                        "student_id": student.id,
                        "checked": val ?? false,
                        "timestamp": DateTime.now().toIso8601String(),
                      });
                    },
                  ),
                ],
              ),
            );
          },
        )
            : const LoadingWidget(),
      ),
    );
  }
}
