import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';

import '../../provider/teacher_profile_provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
void teacherSubjectListBottomSheet(BuildContext context, TeacherProfileProvider provider, Map<String, dynamic> map) {

  MixpanelService.track("Profile Subject bottom sheet opened", properties: {
    "timestamp": DateTime.now().toIso8601String(),
    "grade_id": map["la_grade_id"] ?? "",
    "section_id": map["la_section_id"] ?? "",
    "section_name": map["la_section_name"] ?? "",
  });
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header with title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  StringHelper.subjects,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Column(
              children: provider.subjectModel!.data!.subject!
                  .map(
                    (e) => Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.deepPurple.shade100,
                      highlightColor: Colors.deepPurple.shade50,
                      onTap: () {
                        MixpanelService.track("Subject column in form updated", properties: {
                          "subject_id": e.id!.toString(),
                          "subject_name": e.title!,
                          "grade_id": map["la_grade_id"] ?? "",
                          "section_id": map["la_section_id"] ?? "",
                          "section_name": map["la_section_name"] ?? "",
                          "timestamp": DateTime.now().toIso8601String(),
                        });
                        provider.subjectController.text = e.title!;
                        map["subjects"] = e.id!.toString();
                        map["subject_name"] = e.title!;
                        provider.notifyListeners();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.deepPurple.shade50,
                        ),
                        child: Center(
                          child: Text(
                            e.title!,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              )
                  .toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}
