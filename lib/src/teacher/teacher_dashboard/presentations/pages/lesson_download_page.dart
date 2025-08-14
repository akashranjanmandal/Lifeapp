import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/lesson_plan_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/pdf_view_page.dart';

import '../../../../common/helper/api_helper.dart';
import '../../../../common/widgets/common_navigator.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class LessonDownloadPage extends StatefulWidget {
  final LessonPlanModel model;

  const LessonDownloadPage({super.key, required this.model});

  @override
  State<LessonDownloadPage> createState() => _LessonDownloadPageState();
}

class _LessonDownloadPageState extends State<LessonDownloadPage> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    MixpanelService.track("LessonPlanListPage_View");
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    MixpanelService.track("LessonPlanListPage_ActivityTime", properties: {
      "duration_seconds": duration,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: "Lesson Plan",
        onBack: () {
          MixpanelService.track("LessonPlanListPage_BackClicked");
          Navigator.of(context).pop();
        },
      ),
      body: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.model.data!.laLessionPlans!.length,
        itemBuilder: (context, index) {
          final lessonPlan = widget.model.data!.laLessionPlans![index];
          return Container(
            margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(1, 1),
                  spreadRadius: 1,
                  blurRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lessonPlan.title!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),

                // View Icon with tracking
                InkWell(
                  onTap: () {
                    MixpanelService.track("LessonPlanListPage_ViewIconClicked", properties: {
                      "lesson_plan_title": lessonPlan.title,
                      "lesson_plan_id": lessonPlan.id ?? "",
                    });
                    push(
                      context: context,
                      page: PdfPage(
                        url: ApiHelper.imgBaseUrl + lessonPlan.document!.url!,
                        name: lessonPlan.title!,
                      ),
                    );
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
