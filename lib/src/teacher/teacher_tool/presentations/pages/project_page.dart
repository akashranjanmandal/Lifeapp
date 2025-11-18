import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/tool_mission_page.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:lifelab3/src/teacher/vision/presentations/vision_list.dart';
import 'package:lifelab3/src/teacher/vision/providers/vision_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
import 'package:shimmer/shimmer.dart';

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
    MixpanelService.track("ProjectScreen_BackIconClicked", properties: {
      "project_name": widget.name,
      "section_id": widget.sectionId,
      "grade_id": widget.gradeId,
      "class_id": widget.classId,
    });
    return true;
  }

  void _showPremiumInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text("Info"),
          ],
        ),
        content: const Text(
            "This is a premium feature for Life Lab partner schools, now available for everyone",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectButton({
    required String title,
    required VoidCallback onPressed,
    bool isPremium = false,
    bool showInfo = false,
  }) {
    return Stack(
      children: [
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
            onPressed: onPressed,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Title text
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ✨ Crown icon for premium (with shimmer)
                if (isPremium)
                  Positioned(
                    top: -15,
                    right: MediaQuery.of(context).size.width * -0.24,
                    child: Shimmer.fromColors(
                      baseColor: Colors.amber,
                      highlightColor: Colors.white,
                      period: const Duration(seconds: 2),
                      child: Image.asset(
                        'assets/images/crown_icon_2.png',
                        height: 26,
                        width: 26,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ℹ️ Info icon inside top-right of button
        if (showInfo)
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: _showPremiumInfo,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.info_outline, color: Colors.deepPurple),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: commonAppBar(context: context, name: widget.name),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Column(
            children: [
              // Vision
              _buildProjectButton(
                title: "Vision",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => TeacherVisionProvider(gradeId: widget.gradeId),
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
              ),
              const SizedBox(height: 20),

              // Mission
              _buildProjectButton(
                title: "Mission",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ToolProvider(),
                        child: ToolMissionPage(
                          projectName: widget.name,
                          sectionId: widget.sectionId,
                          gradeId: widget.gradeId,
                          classId: widget.classId,
                          type: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Jigyasa (Premium)
              _buildProjectButton(
                title: "Jigyasa",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ToolProvider(),
                        child: ToolMissionPage(
                          projectName: widget.name,
                          sectionId: widget.sectionId,
                          gradeId: widget.gradeId,
                          classId: widget.classId,
                          type: 5,
                        ),
                      ),
                    ),
                  );
                },
                isPremium: true,
                showInfo: true,
              ),
              const SizedBox(height: 20),

              // Pragya (Premium)
              _buildProjectButton(
                title: "Pragya",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ToolProvider(),
                        child: ToolMissionPage(
                          projectName: widget.name,
                          sectionId: widget.sectionId,
                          gradeId: widget.gradeId,
                          classId: widget.classId,
                          type: 6,
                        ),
                      ),
                    ),
                  );
                },
                isPremium: true,
                showInfo: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
