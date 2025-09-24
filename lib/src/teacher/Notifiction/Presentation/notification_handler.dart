import 'package:flutter/material.dart';

class TeacherNotificationHandler {
  /// Show a notification popup
  static void show(BuildContext context, Map<String, dynamic> data) {
    if (context == null) {
      debugPrint("TeacherNotificationHandler: context is null, cannot show popup");
      return;
    }

    final title = data['title']?.toString() ?? "Notification";
    final message = data['message']?.toString() ?? "";

    // Use addPostFrameCallback to ensure dialog shows after frame rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications, size: 60, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
