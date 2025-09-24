import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/teacher/student_progress/presentations/widget/common_student_widget.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:provider/provider.dart';

class ClassroomStudentList extends StatelessWidget {
  final String sectionName;
  const ClassroomStudentList({super.key, required this.sectionName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProgressProvider>(context);
    return Scaffold(
      appBar: commonAppBar(context: context, name: 'My Students'),
      body: provider.allStudentReportModel?.data?.student == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount:
                    provider.allStudentReportModel!.data!.student!.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => CommonStudentWidget(
                  index: index,
                  provider: provider,
                  sectionName: sectionName,
                ),
              ),
            ),
    );
  }
}
