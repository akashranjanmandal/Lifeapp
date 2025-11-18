//class report page
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/teacher/student_progress/presentations/pages/classroom_student_list.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:provider/provider.dart';
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
  final GlobalKey _classDetailsKey = GlobalKey();

  late DateTime _startTime;
  final List<String> _timelineOptions = [
    'All',
    'monthly',
    'quarterly',
    'halfyearly',
    'yearly',
  ];
  String _selectedTimeline = 'All';
  bool _isDownloading = false;

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
          ? Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.allStudentReportModel!.data != null)
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _isDownloading
                                ? null
                                : () {
                              if (provider.allStudentReportModel !=
                                  null &&
                                  provider.allStudentReportModel!
                                      .data !=
                                      null) {
                                setState(() {
                                  _isDownloading = true;
                                });
                                provider
                                    .downloadPDF(
                                  context,
                                  widget.gradeName,
                                  widget.sectionName,
                                  widget.subjectName,
                                  widget.gradeId,
                                )
                                    .then((_) {
                                  setState(() {
                                    _isDownloading = false;
                                  });
                                });
                              } else {
                                Fluttertoast.showToast(
                                    msg: "Data not ready for download!");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: _isDownloading
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : const Text(
                              "Download Report",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 6,
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
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
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
                const SizedBox(
                  height: 15,
                ),
                // Dropdown timeline filter
                SizedBox(
                  height: 50,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTimeline,
                        items: _timelineOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(
                              option[0].toUpperCase() + option.substring(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeline = value!;
                          });
                          Provider.of<StudentProgressProvider>(context,
                              listen: false)
                              .getClassStudent(
                            widget.gradeId,
                            timeline: _selectedTimeline == 'All'
                                ? null
                                : _selectedTimeline,
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                // Content that will be captured for PDF
                Container(
                  width: MediaQuery.of(context).size.width,
                  color: ColorCode.defaultBgColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CLASS DETAILS
                      Row(
                        children: [
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
                                "${provider.allStudentReportModel!.data!.student!.length}",
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
                        ],
                      ),

                      // PERFORMANCE SUMMARY col
                      const SizedBox(height: 25),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.allStudentReportModel!.data != null)
                            const Text(
                              'Performance Summary',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 0),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${provider.allStudentReportModel!.data!.totalVision ?? ""}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Vision\nCompleted",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                ),
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${provider.allStudentReportModel!.data!.totalMission ?? ""}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Mission\nCompleted",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                ),
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${provider.allStudentReportModel!.data!.totalQuiz ?? ""}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Quiz",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                ),
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${provider.allStudentReportModel!.data!.totalCoins ?? ""}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Coins\nEarned",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                ),
                                Flexible(
                                  child: SizedBox(
                                    width: 60,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${provider.allStudentReportModel!.data!.coinsRedeemed ?? ""}",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Coins\nRedeemed",
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PERFORMANCE DETAILS col
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: "Vision Stats ",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                        "(Completion rate ${provider.allStudentReportModel!.data!.visionCompletionRate ?? 0}%)",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      "Assigned",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.totalVisionAssigned ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "Complete",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.totalVision ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "Coins Earned",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.totalVisionCoins ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                    color: Colors.grey, thickness: 1),
                                const SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                    text: "Mission Stats ",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                        "(Completion rate ${provider.allStudentReportModel!.data!.missionCompletionRate ?? ""}%)",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      "Assigned",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.totalMissionAssigned ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "Complete",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.totalMission ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "Coins Earned",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.totalMissionCoins ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                    color: Colors.grey, thickness: 1),
                                const SizedBox(height: 10),
                                const Text('Quiz Set Status',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    )),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      "Total Quiz",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.totalQuiz ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "coins Earned",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${provider.allStudentReportModel!.data!.quizTotalCoins ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      "Downloading PDF...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )
          : const LoadingWidget(),
    );
  }
}