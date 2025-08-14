import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/tool_subject_page.dart';
import 'package:lifelab3/src/teacher/vision/presentations/vision_list.dart';
import 'package:lifelab3/src/teacher/vision/providers/vision_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class TeacherProjectPage extends StatefulWidget {
  final String name;
  final String sectionId;
  final String gradeId;
  final String classId;

  const TeacherProjectPage({
    super.key,
    required this.name,
    required this.classId,
    required this.gradeId,
    required this.sectionId,
  });

  @override
  State<TeacherProjectPage> createState() => _TeacherProjectPageState();
}

class _TeacherProjectPageState extends State<TeacherProjectPage> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Track screen view when page is opened
    MixpanelService.track("ProjectScreen_View", properties: {
      "project_name": widget.name,
      "section_id": widget.sectionId,
      "grade_id": widget.gradeId,
      "class_id": widget.classId,
    });
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;

    // Track the total time spent on this screen
    MixpanelService.track("ProjectScreen_ActivityTime", properties: {
      "duration_seconds": duration,
      "project_name": widget.name,
      "section_id": widget.sectionId,
      "grade_id": widget.gradeId,
      "class_id": widget.classId,
    });
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Track when back icon is clicked or system back pressed
    MixpanelService.track("ProjectScreen_BackIconClicked", properties: {
      "project_name": widget.name,
      "section_id": widget.sectionId,
      "grade_id": widget.gradeId,
      "class_id": widget.classId,
    });

    return true; // allow navigation to pop
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: commonAppBar(context: context, name: widget.name,
          // If your commonAppBar supports onBack callback, you can add here:
          // onBack: () {
          //  MixpanelService.track("ProjectScreen_BackIconClicked", ...);
          //  Navigator.of(context).pop();
          // },
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              // Vision Button with increased font size
              SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    shadowColor: Colors.grey.withOpacity(0.5),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => VisionProvider(),
                          child: VisionPage(
                            navName: 'Vision',
                            subjectName: 'Subject Name',
                            sectionId: widget.sectionId,
                            gradeId: widget.gradeId,
                            classId: widget.classId,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Vision",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24, // Increased font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Mission Button with increased font size
              SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    shadowColor: Colors.grey.withOpacity(0.5),
                  ),
                  onPressed: () {
                    push(
                      context: context,
                      page: ToolSubjectListPage(
                        projectName: "Mission",
                        sectionId: widget.sectionId,
                        gradeId: widget.gradeId,
                        classId: widget.classId,
                      ),
                    );
                  },
                  child: const Text(
                    "Mission",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24, // Increased font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Uncomment and add Mixpanel tracking on other buttons if you enable them
              /*
              const SizedBox(height: 20),
              CustomButton(
                name: "Quiz",
                height: 50,
                color: Colors.white,
                textColor: Colors.black,
                isShadow: true,
                onTap: () {
                  push(
                    context: context,
                    page: ToolSubjectListPage(
                      projectName: "Quiz",
                      classId: widget.classId,
                    ),
                  );
                },
              ),
              */
            ],
          ),
        ),
      ),
    );
  }
}
