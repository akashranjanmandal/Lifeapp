import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/project_page.dart';

class TeacherClassPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const TeacherClassPage({Key? key, this.onBackToHome}) : super(key: key);

  @override
  State<TeacherClassPage> createState() => _TeacherClassPageState();
}

class _TeacherClassPageState extends State<TeacherClassPage> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ToolProvider>(context, listen: false);
    provider.getTeacherGrade();
    provider.getLevel();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToolProvider>(context);
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: "Your classroom",
        onBack: () {
          if (widget.onBackToHome != null) {
            widget.onBackToHome!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      body: provider.teacherGradeSectionModel != null
          ? ListView.builder(
        shrinkWrap: true,
        itemCount:
        provider.teacherGradeSectionModel!.data!.teacherGrades!.length,
        itemBuilder: (context, index) {
          final gradeSection =
          provider.teacherGradeSectionModel!.data!.teacherGrades![index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherProjectPage(
                    name:
                    "Class ${gradeSection.grade!.name!} ${gradeSection.section!.name!}",
                    gradeId: gradeSection.grade!.id!.toString(),
                    classId: gradeSection.id!.toString(),
                    sectionId: gradeSection.section!.id.toString(),
                  ),
                ),
              );
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin:
              const EdgeInsets.only(left: 15, right: 15, bottom: 20),
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
                  )
                ],
              ),
              child: Text(
                "Class ${gradeSection.grade!.name!} ${gradeSection.section!.name!}",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      )
          : const LoadingWidget(),
    );
  }
}
