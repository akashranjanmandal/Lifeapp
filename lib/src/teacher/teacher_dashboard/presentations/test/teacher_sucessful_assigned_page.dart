// SuccessPage is a StatelessWidget that displays a success message.
import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/test/teacher_track_assigned_mission_page.dart';

class SuccessPage extends StatelessWidget {
  final String title;
  final int number;
  final String subtitle;

  const SuccessPage({
    super.key,
    this.title = 'Assigned \nSuccessfully',
    this.number = 50,
    this.subtitle = 'Students are assigned',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            textAlign: TextAlign.center,
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Display the green circle with a checkmark.
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 20),
          Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE94459),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                //route where to go
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TeacherAssignedPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
