import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/presentations/widget/board_sheet.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/presentations/widget/grade_sheet.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/presentations/widget/section_sheet.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/presentations/widget/subject_sheet.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/provider/teacher_sign_up_provider.dart';
import 'package:provider/provider.dart';

import '../../../../common/helper/color_code.dart';
import '../../../../common/helper/image_helper.dart';
import '../../../../common/helper/string_helper.dart';
import '../../../../common/utils/mixpanel_service.dart';
import '../../../../common/widgets/custom_text_field.dart';

class TeacherSignUpPage extends StatefulWidget {
  final String contact;

  const TeacherSignUpPage({super.key, required this.contact});

  @override
  State<TeacherSignUpPage> createState() => _TeacherSignUpPageState();
}

class _TeacherSignUpPageState extends State<TeacherSignUpPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<TeacherSignUpProvider>(context, listen: false)
          .getSchoolList();
      Provider.of<TeacherSignUpProvider>(context, listen: false)
          .getStateCityList();
      Provider.of<TeacherSignUpProvider>(context, listen: false)
          .getSectionList();
      Provider.of<TeacherSignUpProvider>(context, listen: false).getBoard();
      Provider.of<TeacherSignUpProvider>(context, listen: false).subjects();
      Provider.of<TeacherSignUpProvider>(context, listen: false)
          .gradeMapList
          .clear();
      Provider.of<TeacherSignUpProvider>(context, listen: false)
          .gradeMapList
          .add({
        "la_grade_id": "",
        "la_section_id": "",
        "subjects": "",
        "la_section_name": "",
        "subject_name": ""
      });
    });
    super.initState();
  }

  Widget _buildTextLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: ColorCode.textBlackColor,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherSignUpProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(ImageHelper.gappuBoboImg1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Teacher Name
                  _buildTextLabel("Teacher Name"),
                  CustomTextField(
                    readOnly: false,
                    fieldController: provider.teacherNameController,
                    hintName: "Enter Teacher Name",
                    suffix: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: 20),

                  // School Code
                  _buildTextLabel("School Code"),
                  Row(
                    children: [
                      Expanded(

                        child: CustomTextField(
                          readOnly: false,
                          fieldController: provider.schoolCodeController,
                          hintName: "Enter School Code",
                          suffix: const Icon(Icons.school_outlined),
                          onChange: (val) {
                            setState(() {
                              provider.isSchoolCodeValid = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!provider.isSchoolCodeValid)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFFFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onPressed: () => provider.verifySchoolCode(context),
                          icon: const Icon(Icons.verified_outlined, size: 18),
                          label: const Text(
                            "Verify",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // School Info
                  if (provider.isSchoolCodeValid)
                    _buildTextLabel("School Address"),
                  CustomTextField(
                    readOnly: true,
                    fieldController: TextEditingController(
                      text: "${provider.schoolNameController.text}, ${provider.stateController.text}, ${provider.cityController.text}",
                    ),
                    hintName: "School Address",
                    suffix: const Icon(Icons.location_on_outlined),
                  ),
                  if (provider.isSchoolCodeValid) const SizedBox(height: 20),

                  // Dynamic Grade-Section-Subject Fields
                  ...provider.gradeMapList.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> e = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white, // white background
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextLabel("Grade"),
                                const SizedBox(height: 6),
                                CustomTextField(
                                  readOnly: true,
                                  fieldController: TextEditingController(text: e["la_grade_id"]),
                                  hintName: "Select Grade",
                                  suffix: const Icon(Icons.grade_outlined),
                                  onTap: () => teacherGradeListBottomSheet(context, provider, e),
                                ),
                                const SizedBox(height: 20),

                                _buildTextLabel("Section"),
                                const SizedBox(height: 6),
                                CustomTextField(
                                  readOnly: true,
                                  fieldController: TextEditingController(text: e["la_section_name"]),
                                  hintName: "Select Section",
                                  suffix: const Icon(Icons.view_agenda_outlined),
                                  onTap: () => teacherSectionListBottomSheet(context, provider, e),
                                ),
                                const SizedBox(height: 20),

                                _buildTextLabel("Subject"),
                                const SizedBox(height: 6),
                                CustomTextField(
                                  readOnly: true,
                                  fieldController: TextEditingController(text: e["subject_name"]),
                                  hintName: "Select Subject",
                                  suffix: const Icon(Icons.book_outlined),
                                  onTap: () => subjectListBottomSheet(context, provider, e),
                                ),
                              ],
                            ),
                          ),

                          // 🗑️ Delete Button (except for the first entry)
                          if (index != 0)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  provider.gradeMapList.removeAt(index);
                                  provider.notifyListeners();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.redAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.delete, size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          provider.gradeMapList.add({
                            "la_grade_id": "",
                            "la_section_id": "",
                            "subjects": "",
                            "la_section_name": "",
                            "subject_name": ""
                          });
                          provider.notifyListeners();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5C6BFF), Color(0xFF906EFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                "Add New Class",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Board
                  const SizedBox(height: 28),
                  _buildTextLabel("Board"),
                  CustomTextField(
                    readOnly: true,
                    fieldController: provider.boardNameController,
                    hintName: "Select Board",
                    suffix: const Icon(Icons.apartment_outlined),
                    onTap: () => boardListBottomSheet(context, provider),
                  ),

                  // Submit Button
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5C6BFF), Color(0xFF936DFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // ✅ Mixpanel tracking for Teacher Signup
                          MixpanelService.track("Teacher Signup Clicked", properties: {
                            "teacher_name": provider.teacherNameController.text,
                            "mobile_no": widget.contact,
                            "school_code": provider.schoolCodeController.text,
                            "school_name": provider.schoolNameController.text,
                            "state": provider.stateController.text,
                            "city": provider.cityController.text,
                            "board": provider.boardNameController.text,
                            "grade_map_list": provider.gradeMapList,
                            "timestamp": DateTime.now().toIso8601String(),
                          });

                          provider.registerStudent(context, widget.contact);
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text(
                          StringHelper.submit,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        StringHelper.aLifeLabProduct,
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}