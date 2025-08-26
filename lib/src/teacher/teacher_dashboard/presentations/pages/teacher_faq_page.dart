import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/widgets/faq_test.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/widgets/teacher_faq_listview.dart';

class TeacherFaqPage extends StatefulWidget {
  const TeacherFaqPage({super.key});

  @override
  State<TeacherFaqPage> createState() => _TeacherFaqPageState();
}

class _TeacherFaqPageState extends State<TeacherFaqPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "${StringHelper.faq}s",
          style: TextStyle(
            color: ColorCode.textBlackColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: const TeacherFaqListview(),
      // body: const FaqTestPage(),
    );
  }
}
