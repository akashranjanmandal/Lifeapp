import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
import 'package:provider/provider.dart';

/// ---------------------------
/// Success Page Widget
/// ---------------------------
class SuccessPage extends StatelessWidget {
  final int studentCount;
  final int totalCoins;

  const SuccessPage({
    super.key,
    required this.studentCount,
    required this.totalCoins,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 80),
          Column(
            children: [
              const Text(
                "Assigned Successfully",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),
              const SizedBox(height: 30),
              Text(
                "$studentCount Students",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Total Coins Earned: $totalCoins",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// Class Student Page
/// ---------------------------
class ClassStudentPage extends StatefulWidget {
  final String? subjectId;
  final String sectionId;
  final String gradeId;
  final String missionId;
  final String type;

  const ClassStudentPage({
    super.key,
    this.subjectId,
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

  /// Show success screen after assigning
  void _showSuccessDialog(int studentCount) {
    final provider = Provider.of<ToolProvider>(context, listen: false);

    // Find the mission by missionId
    final currentMission = provider.missionListModel?.data?.missions?.data
        ?.firstWhere(
            (m) => m.id.toString() == widget.missionId,
        );

    final coinsPerStudent = currentMission?.level?.teacher_assign_points ?? 1;
    final totalCoins = coinsPerStudent * studentCount;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (context, _, __) {
        return SuccessPage(
          studentCount: studentCount,
          totalCoins: totalCoins,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Map<String, dynamic> data = {
        "school_id": Provider.of<TeacherDashboardProvider>(context, listen: false)
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
      MixpanelService.track("Student selection for mission screen activity time",
          properties: {
            "duration_seconds": duration,
            "timestamp": DateTime.now().toIso8601String(),
          });
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    MixpanelService.track("Back icon clicked",
        properties: {"timestamp": DateTime.now().toIso8601String()});
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

        /// Assign Button
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20,top :10),
          child: Row(
            children: [
              /// Date Picker Button
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final provider =
                    Provider.of<ToolProvider>(context, listen: false);

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: provider.currentDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );

                    if (picked != null) {
                      provider.currentDate = picked;
                      provider.dateController.text =
                      "${picked.day}-${picked.month}-${picked.year}";
                      provider.notifyListeners();

                      MixpanelService.track(
                        "Due date selected on ClassStudentPage",
                        properties: {
                          "selected_date": provider.dateController.text,
                          "timestamp": DateTime.now().toIso8601String(),
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  ),
                  icon: const Icon(Icons.calendar_today, color: Colors.black87, size: 20),
                  label: Consumer<ToolProvider>(
                    builder: (context, provider, _) {
                      return Text(
                        provider.dateController.text.isEmpty
                            ? "Set Due Date"
                            : provider.dateController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              /// Assign Button
              Expanded(
                flex: 1,
                child: CustomButton(
                  name: "Assign Selected",
                  width: double.infinity,
                  height: 45,
                  onTap: () async {
                    final provider =
                    Provider.of<ToolProvider>(context, listen: false);

                    MixpanelService.track("Assign selected button clicked",
                        properties: {
                          "selected_student_count": studentIdList.length,
                          "due_date": provider.dateController.text,
                          "timestamp": DateTime.now().toIso8601String(),
                        });

                    if (studentIdList.isEmpty) {
                      Fluttertoast.showToast(msg: "Please select student");
                      return;
                    }

                    if (provider.dateController.text.isEmpty) {
                      Fluttertoast.showToast(msg: "Please select a due date");
                      return;
                    }

                    Map<String, dynamic> data;
                    bool success;

                    if (widget.type == "1") {
                      data = {
                        "la_mission_id": widget.missionId,
                        "user_ids": studentIdList,
                        "due_date": provider.dateController.text,
                      };
                      success = await provider.assignMission(context, data);
                    } else {
                      data = {
                        "la_topic_id": widget.missionId,
                        "user_ids": studentIdList,
                        "due_date": provider.dateController.text,
                        "type": widget.type,
                      };
                      success = await provider.assignTopic(context, data);
                    }

                    if (success) {
                      _showSuccessDialog(studentIdList.length);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        /// Student List
        body: provider.classStudentModel != null
            ? ListView.builder(
          shrinkWrap: true,
          itemCount: studentList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 10),
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
                          selectAll = val ?? false;
                          studentIdList.clear();
                          if (selectAll) {
                            studentIdList.addAll(
                              studentList.map((e) => e.id!).toList(),
                            );
                          }
                        });

                        MixpanelService.track(
                            "Assign all students checked",
                            properties: {
                              "checked": selectAll,
                              "timestamp":
                              DateTime.now().toIso8601String(),
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
                        ApiHelper.imgBaseUrl +
                            student.profileImage!),
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
                          if (studentIdList.length ==
                              studentList.length) {
                            selectAll = true;
                          }
                        }
                      });

                      MixpanelService.track(
                          "Individual student checked",
                          properties: {
                            "student_id": student.id,
                            "checked": val ?? false,
                            "timestamp":
                            DateTime.now().toIso8601String(),
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
