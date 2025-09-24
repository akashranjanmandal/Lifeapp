//class report page(2nd figma)
import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/teacher/student_progress/presentations/pages/classroom_student_list.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:provider/provider.dart';

import '../widget/common_student_widget.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class ClassroomDetailsPage extends StatefulWidget {
  final String gradeName;
  final String sectionName;
  final String gradeId;
  final String subjectName;

  const ClassroomDetailsPage(
      {super.key,
      required this.gradeId,
      required this.gradeName,
      required this.sectionName,
      required this.subjectName});

  @override
  State<ClassroomDetailsPage> createState() => _ClassroomDetailsPageState();
}

class _ClassroomDetailsPageState extends State<ClassroomDetailsPage> {
  late DateTime _startTime;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<StudentProgressProvider>(context, listen: false)
          .getClassStudent(widget.gradeId);
    });
    super.initState();
    _startTime = DateTime.now();
    MixpanelService.track("IndividualClassroomScreen_View", properties: {
      "grade_id": widget.gradeId,
      "grade_name": widget.gradeName,
      "section_name": widget.sectionName,
      "subject_name": widget.subjectName,
    });
  }

  @override
  void dispose() {
    final durationSecs = DateTime.now().difference(_startTime).inSeconds;
    MixpanelService.track("IndividualClassroomScreen_ActivityTime",
        properties: {
          "duration_seconds": durationSecs,
          "grade_id": widget.gradeId,
        });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProgressProvider>(context);
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: 'Classroom Report',
      ),
      body: provider.allStudentReportModel != null
          ? SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.allStudentReportModel!.data != null)
                    Row(children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Class ${widget.gradeName} ${widget.sectionName}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            "Subject : ${widget.subjectName}",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            "${provider.allStudentReportModel!.data!.student!.length} ",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Students",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    ]),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Add your action here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8), // Decrease padding
                            ),
                            child: const Text(
                              "Download Report",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13, // Decrease text size
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20), // Increase spacing
                      Expanded(
                        flex: 6, // Increase width
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ClassroomStudentList(
                                              sectionName:
                                                  widget.sectionName)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: const BorderSide(
                                    color: Colors.grey, width: .7),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8), // Decrease padding
                            ),
                            child: const Text(
                              "View Students",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (provider.allStudentReportModel!.data != null)
                    const Text('Performance Summary',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 12),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              "${provider.allStudentReportModel!.data!.totalMission ?? ""}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              "Mission",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 35,
                          width: 1,
                          color: Colors.black54,
                        ),
                        Column(
                          children: [
                            Text(
                              "${provider.allStudentReportModel!.data!.totalQuiz ?? ""}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              "Quiz",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 35,
                          width: 1,
                          color: Colors.black54,
                        ),
                        Column(
                          children: [
                            Text(
                              "${provider.allStudentReportModel!.data!.totalPuzzle ?? ""}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              "Puzzles",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 35,
                          width: 1,
                          color: Colors.black54,
                        ),
                        Column(
                          children: [
                            Text(
                              "${provider.allStudentReportModel!.data!.totalCoins ?? ""}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              "Coins",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const LoadingWidget(),
    );
  }
}
