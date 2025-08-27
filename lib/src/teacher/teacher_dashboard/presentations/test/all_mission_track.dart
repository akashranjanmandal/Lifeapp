// lib/src/teacher/teacher_dashboard/presentations/widgets/test/all_mission_track.dart
import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/test/approve_reject_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/test/model/all_mission_datamodel.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/test/teacher_track_assigned_mission_page.dart';

class AllMissionTrackPage extends StatelessWidget {
  const AllMissionTrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mockStatuses = [
      "assigned",
      "review",
      "approved",
      "rejected",
      "incompleted"
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mission',
          style: TextStyle(color: ColorCode.grey),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Buttons
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('All Missions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherAssignedPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Track Assigned Missions'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search',
                  suffixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Student cards
            Expanded(
              child: ListView.builder(
                itemCount: mockStatuses.length,
                itemBuilder: (context, index) {
                  final status =
                      AllMissionStatusModel.getStatus(mockStatuses[index]);
                  return AllMissionTrackStudentCard(
                    name: 'Rajesh',
                    imagePath: 'assets/images/profile_2.png',
                    buttonText: status["text"] as String,
                    buttonColor: status["color"] as Color,
                    rawStatus: mockStatuses[index], // pass raw status here
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllMissionTrackStudentCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final String buttonText;
  final Color buttonColor;
  final String rawStatus;

  const AllMissionTrackStudentCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.buttonText,
    required this.buttonColor,
    required this.rawStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDetails = rawStatus == "approved" || rawStatus == "rejected";

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Student info
          Flexible(
            flex: 3,
            child: Container(
              height: 57,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(imagePath),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status + Details (uses model color/text)
          Flexible(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: hasDetails ? 36 : 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor, // ← from model
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        Text(buttonText, style: const TextStyle(fontSize: 13)),
                  ),
                ),
                if (hasDetails) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ApproveRejectPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          const Text("Details", style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
