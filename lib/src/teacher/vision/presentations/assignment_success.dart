import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

import '../models/vision_model.dart';

class AssignmentSuccessScreen extends StatelessWidget {
  final int assignedCount;
  final TeacherVisionVideo visionVideo; // Pass the video model to get points

  const AssignmentSuccessScreen({
    Key? key,
    required this.assignedCount,
    required this.visionVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _AssignmentSuccessScreenBody(
      assignedCount: assignedCount,
      visionVideo: visionVideo,
    );
  }
}

class _AssignmentSuccessScreenBody extends StatefulWidget {
  final int assignedCount;
  final TeacherVisionVideo visionVideo;

  const _AssignmentSuccessScreenBody({
    required this.assignedCount,
    required this.visionVideo,
  });

  @override
  State<_AssignmentSuccessScreenBody> createState() => _AssignmentSuccessScreenBodyState();
}

class _AssignmentSuccessScreenBodyState extends State<_AssignmentSuccessScreenBody> {
  DateTime? _entryTime;
  int totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _entryTime = DateTime.now();
    MixpanelService.track('Assignment Success Screen Opened');

    // Calculate total points
    final teacherAssignPoints = widget.visionVideo.levelInfo?.teacherAssignPoints ?? 0;
    totalPoints = widget.assignedCount * teacherAssignPoints;
  }

  @override
  void dispose() {
    if (_entryTime != null) {
      final duration = DateTime.now().difference(_entryTime!);
      MixpanelService.track('Assignment Success Screen Activity Time', properties: {
        'duration_seconds': duration.inSeconds,
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Assign\nSuccessfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  '${widget.assignedCount}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Text(
                  'Students are assigned',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Total points
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      'Total Coins Earned: $totalPoints',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      MixpanelService.track('Assignment Success Done Button Clicked');
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
