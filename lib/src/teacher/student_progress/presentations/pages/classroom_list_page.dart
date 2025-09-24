//my classrooms(1st figma page)
import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/teacher/student_progress/presentations/pages/classroom_details_page.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class ClassroomListPage extends StatefulWidget {
  const ClassroomListPage({super.key});

  @override
  State<ClassroomListPage> createState() => _ClassroomListPageState();
}

class _ClassroomListPageState extends State<ClassroomListPage> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // Start tracking time when page opens
    Provider.of<StudentProgressProvider>(context, listen: false)
        .getTeacherGrade();

    // Track page view event
    MixpanelService.track("ClassroomListPage_View");
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    MixpanelService.track("ClassroomListPage_ActivityTime", properties: {
      "duration_seconds": duration,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProgressProvider>(context);
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: StringHelper.myClassrooms,
        // Assuming commonAppBar has an onBack callback or customized widget
        onBack: () {
          MixpanelService.track("ClassroomListPage_BackClicked");
          Navigator.of(context).pop();
        },
      ),
      body: provider.teacherGradeSectionModel != null
          ? ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(
                  left: 15, right: 15, top: 20, bottom: 50),
              itemCount: provider
                  .teacherGradeSectionModel!.data!.teacherGrades!.length,
              itemBuilder: (context, index) {
                final grade = provider
                    .teacherGradeSectionModel!.data!.teacherGrades![index];
                return InkWell(
                  onTap: () {
                    // Tracking the class option button click
                    MixpanelService.track(
                        "ClassroomListPage_ClassOptionClicked",
                        properties: {
                          "grade_id": grade.id.toString(),
                          "subject_name": grade.subject!.title!,
                          "section_name": grade.section!.name!,
                          "grade_name": grade.grade!.name!,
                        });

                    push(
                      context: context,
                      page: ClassroomDetailsPage(
                        gradeId: grade.id!.toString(),
                        subjectName: grade.subject!.title!,
                        sectionName: grade.section!.name!,
                        gradeName: grade.grade!.name!,
                      ),
                    );
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(1, 1),
                            spreadRadius: 2,
                            blurRadius: 5,
                          )
                        ]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Class ${grade.grade!.name!} ${grade.section!.name!} | ${grade.subject!.title!}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          height: 25,
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.blue,
                          ),
                          child: const Center(
                            child: Text(
                              "View",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const LoadingWidget(),
    );
  }
}
