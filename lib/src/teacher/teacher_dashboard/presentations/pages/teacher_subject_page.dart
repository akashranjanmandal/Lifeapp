import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_subject_grade_list_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_subject_level_list_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:provider/provider.dart';

import '../../../../common/helper/api_helper.dart';
import '../../../../common/helper/color_code.dart';
import '../../../../common/helper/image_helper.dart';
import '../../../../common/widgets/common_navigator.dart';


class TeacherSubjectListPage extends StatefulWidget {
  final String name;

  const TeacherSubjectListPage({super.key, required this.name});

  @override
  State<TeacherSubjectListPage> createState() => _TeacherSubjectListPageState();
}

class _TeacherSubjectListPageState extends State<TeacherSubjectListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // 🔥 trigger the API call once when the page opens
      Provider.of<TeacherDashboardProvider>(context, listen: false).getSubjectsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherDashboardProvider>(context);

    final subjectModel = provider.subjectModel;

    // show loader while fetching
    if (subjectModel == null || subjectModel.data?.subject == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final subjects = subjectModel.data!.subject!;

    if (subjects.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No subjects found")),
      );
    }

    return Scaffold(
      appBar: commonAppBar(context: context, name: StringHelper.subjects),
      body: ListView.builder(
        shrinkWrap: true,
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];

          return InkWell(
            onTap: () {
              if (!(subject.couponCodeUnlock ?? false)) {
                if (widget.name == StringHelper.competencies ||
                    widget.name == StringHelper.conceptCartoons) {
                  push(
                    context: context,
                    page: TeacherSubjectLevelListPage(
                      subjectName: subject.title ?? "",
                      subjectId: subject.id?.toString() ?? "",
                      name: widget.name,
                    ),
                  );
                } else {
                  push(
                    context: context,
                    page: TeacherSubjectGradeListPage(
                      subjectName: subject.title ?? "",
                      subjectId: subject.id?.toString() ?? "",
                      name: widget.name,
                    ),
                  );
                }
              } else {
                Fluttertoast.showToast(msg: StringHelper.locked);
              }
            },
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ColorCode.subjectListColor1,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * .5,
                            child: Text(
                              subject.title ?? "",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * .5,
                            child: Text(
                              subject.heading ?? "",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                              ),
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      (subject.image?.url != null)
                          ? Image.network(
                        ApiHelper.imgBaseUrl + subject.image!.url!,
                        width: MediaQuery.of(context).size.width * .3,
                      )
                          : Image.asset(
                        ImageHelper.subjectListIcon,
                        width: MediaQuery.of(context).size.width * .3,
                      ),
                    ],
                  ),
                ),
                if (subject.couponCodeUnlock ?? false)
                  Container(
                    height: 140,
                    width: MediaQuery.of(context).size.width,
                    margin:
                    const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: const Color(0xffA7A7A7).withOpacity(.5),
                    ),
                    child: Center(
                      child: Image.asset(
                        ImageHelper.lockIcon,
                        height: 40,
                      ),
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
