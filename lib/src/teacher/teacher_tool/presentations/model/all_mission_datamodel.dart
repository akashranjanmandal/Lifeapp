import 'package:flutter/material.dart';

class AllMissionStatusModel {
  static const Map<String, Map<String, dynamic>> _statusMap = {
    "assigned": {
      "text": "Assigned",
      "color": Colors.blue,
    },
    "review": {
      "text": "Review",
      "color": Colors.orange,
    },
    "rejected": {
      "text": "Rejected",
      "color": Colors.red,
    },
    "incompleted": {
      "text": "Incomplete",
      "color": Colors.grey,
    },
    "approved": {
      "text": "Approved",
      "color": Colors.green,
    },
  };

  /// Returns config for a given status key (case-insensitive)
  static Map<String, dynamic> getStatus(String status) {
    return _statusMap[status.toLowerCase()] ??
        {"text": "Unknown", "color": Colors.black};
  }
}
