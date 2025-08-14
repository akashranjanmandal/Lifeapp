import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class AssignmentSuccessScreen extends StatelessWidget {
  final int assignedCount;

  const AssignmentSuccessScreen({Key? key, required this.assignedCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _AssignmentSuccessScreenBody(assignedCount: assignedCount);
  }
}

class _AssignmentSuccessScreenBody extends StatefulWidget {
  final int assignedCount;
  const _AssignmentSuccessScreenBody({required this.assignedCount});

  @override
  State<_AssignmentSuccessScreenBody> createState() => _AssignmentSuccessScreenBodyState();
}

class _AssignmentSuccessScreenBodyState extends State<_AssignmentSuccessScreenBody> {
  DateTime? _entryTime;

  @override
  void initState() {
    super.initState();
    _entryTime = DateTime.now();
    MixpanelService.track('Assignment Success Screen Opened');
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
                  'Assigned\nSuccessfully',
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
                const SizedBox(height: 40),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      MixpanelService.track('Assignment Success Done Button Clicked');
                      Navigator.pop(context); // close current screen
                      Navigator.pop(context);   // close current screen
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
