import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:provider/provider.dart';

import '../../../../common/helper/string_helper.dart';
import '../../../../common/widgets/common_appbar.dart';

class TeacherMissionSubmissionPage extends StatelessWidget {

  final int missionIndex;
  final bool missionStatus;
  final String missionId;

  const TeacherMissionSubmissionPage({super.key, required this.missionIndex, required this.missionStatus, required this.missionId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProgressProvider>(context);
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: StringHelper.submission,
        action: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Text(
            "Total ${provider.teacherMissionParticipantModel!.data!.data!.length}",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile
            const SizedBox(height: 30),
            Row(
              children: [
                provider.teacherMissionParticipantModel!.data!.data![missionIndex].user!.profileImage != null
                    ? CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(ApiHelper.imgBaseUrl + provider.teacherMissionParticipantModel!.data!.data![missionIndex].user!.profileImage!),
                )
                    : const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(ImageHelper.profileIcon),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .7,
                      child: Text(
                        provider.teacherMissionParticipantModel!.data!.data![missionIndex].user!.name!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Text(
                      "+91 ${provider.teacherMissionParticipantModel!.data!.data![missionIndex].user!.mobileNo!}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .7,
                      child: Text(
                        provider.teacherMissionParticipantModel!.data!.data![missionIndex].user!.school!.name!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Description
            const SizedBox(height: 30),
            if(provider.teacherMissionParticipantModel!.data!.data![missionIndex].submission !=null)Text("Description : ${provider.teacherMissionParticipantModel!.data!.data![missionIndex].submission!.description ?? ""}"),
            // Image
            if (provider.teacherMissionParticipantModel!
                .data!.data![missionIndex].submission != null &&
                provider.teacherMissionParticipantModel!
                    .data!.data![missionIndex].submission!.media !=
                    null &&
                provider.teacherMissionParticipantModel!
                    .data!.data![missionIndex].submission!.media!.isNotEmpty)
              Column(
                children: provider.teacherMissionParticipantModel!
                    .data!.data![missionIndex].submission!.media!
                    .map(
                      (media) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        ApiHelper.imgBaseUrl + media.url!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),

            // Approve
            if(missionStatus) const SizedBox(height: 40),
            if (missionStatus)
              CustomButton(
                name: "Approve",
                color: Colors.blue,
                height: 45,
                textColor: Colors.white,
                onTap: () async {
                  final provider = Provider.of<StudentProgressProvider>(context, listen: false);

                  // 1️⃣ Call API to approve
                  final result = await provider.submitApproveReject(
                    status: 1,
                    comment: "Approve",
                    studentId: provider.teacherMissionParticipantModel!
                        .data!.data![missionIndex].submission!.id!
                        .toString(),
                    context: context,
                    missionId: missionId,
                  );

                  // 2️⃣ Calculate teacher coins per student from mission list
                  final missionList = provider.teacherMissionListModel?.data?.missions?.data ?? [];
                  final currentMission = missionList.firstWhere(
                        (m) => m.id.toString() == missionId,
                  );
                  final coinsPerStudent = currentMission?.level?.teacher_correct_submission_points ?? 0;

                  // 3️⃣ Show modal with the coins
                  await _showCongratsPopup(context, coinsPerStudent);

                  // 4️⃣ Refresh participant list
                  provider.getTeacherMissionParticipant(missionId);

                  // 5️⃣ Navigate back
                  Navigator.of(context).pop();
                },
              ),

            // Reject
            if(missionStatus) const SizedBox(height: 20),
            if(missionStatus) CustomButton(
              name: "Reject",
              color: Colors.black26,
              height: 45,
              textColor: Colors.black,
              onTap: () async {
                final provider = Provider.of<StudentProgressProvider>(context, listen: false);

                // 1️⃣ Call API to reject
                final result = await provider.submitApproveReject(
                  status: 0,
                  comment: "Reject",
                  studentId: provider.teacherMissionParticipantModel!.data!.data![missionIndex].submission!.id!.toString(),
                  context: context,
                  missionId: missionId,
                );

                // 2️⃣ Show rejection message
                await _showRejectionPopup(context);

                // 3️⃣ Refresh participant list
                provider.getTeacherMissionParticipant(missionId);

                // 4️⃣ Navigate back
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCongratsPopup(BuildContext context, int coins) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Congrats',
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        child: Opacity(
          opacity: anim1.value,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Congratulations!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You have been credited with\n$coins coins 🎉",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

Future<void> _showRejectionPopup(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Rejected',
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        child: Opacity(
          opacity: anim1.value,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF44336), Color(0xFFE57373)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Mission Rejected",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "The mission has been rejected.\nStudent can resubmit.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}