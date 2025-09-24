import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/class_students_page.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../common/helper/string_helper.dart';
import '../../../../common/widgets/custom_text_field.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

import '../../../../student/mission/models/mission_details_model.dart';

class AssignMissionPage extends StatefulWidget {
  final String img;
  final String missionId;
  final String sectionId;
  final String gradeId;
  final String? subjectId;
  final String type;
  final List<Resource> resources; // Add resources parameter

  const AssignMissionPage({
    super.key,
    required this.img,
    required this.missionId,
    required this.sectionId,
    required this.gradeId,
    this.subjectId,
    required this.type,
    required this.resources,
  });

  @override
  State<AssignMissionPage> createState() => _AssignMissionPageState();
}

class _AssignMissionPageState extends State<AssignMissionPage> {
  DateTime? _startTime;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<bool> _onWillPop() async {
    MixpanelService.track("Back icon clicked in assign mission page", properties: {
      "timestamp": DateTime.now().toIso8601String(),
    });
    return true;
  }

  @override
  void dispose() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      MixpanelService.track("Assign mission screen activity time", properties: {
        "duration_seconds": duration,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToolProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("Assign Mission",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),          ),
          centerTitle: false,
          actions: [
            if (widget.resources.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    "Swipe →",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // PageView with resources only
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.resources.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: PhotoView(
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        imageProvider: NetworkImage(
                          "${ApiHelper.imgBaseUrl}${widget.resources[index].media?.url ?? ""}",
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Assign section always visible
            Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  CustomButton(
                    name: "Assign students",
                    color: Colors.blue,
                    height: 45,
                    onTap: () {
                      MixpanelService.track("Assign students button clicked",
                          properties: {
                            "mission_id": widget.missionId,
                            "section_id": widget.sectionId,
                            "grade_id": widget.gradeId,
                            "type": widget.type,
                            "timestamp": DateTime.now().toIso8601String(),
                          });

                      push(
                        context: context,
                        page: ClassStudentPage(
                          sectionId: widget.sectionId,
                          missionId: widget.missionId,
                          gradeId: widget.gradeId,
                          type: widget.type,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
