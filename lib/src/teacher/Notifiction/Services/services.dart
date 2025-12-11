import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../common/helper/api_helper.dart';
import '../models/models.dart';

class NotificationService {
  final String token;
  final String baseUrl = ApiHelper.baseUrl;

  NotificationService(this.token);

  Future<List<NotificationModel>> fetchNotifications() async {
    final url = Uri.parse(baseUrl + ApiHelper.notification);
    print("Fetching notifications from: $url");
    print("Auth token: $token");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      } catch (e) {
        print("JSON parsing error: $e");
        throw Exception("Failed to parse notification data");
      }
    } else {
      print("Failed with status: ${response.statusCode}");
      throw Exception('Failed to load notifications');
    }
  }
  Future<void> clearNotifications() async {
    final url = Uri.parse(baseUrl + ApiHelper.clearNotification);
    print("Calling clear notifications API: $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    print("Clear notifications status code: ${response.statusCode}");
    if (response.statusCode == 200) {
      print("Notifications cleared successfully.");
    } else {
      print("Failed to clear notifications: ${response.body}");
      // Optionally throw an error or just ignore
    }
  }
}
