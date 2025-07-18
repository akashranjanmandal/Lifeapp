import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../model/model.dart';

class LeaderboardService {
  final String token;
  final Dio dio = Dio();
  final String baseUrl = 'https://api.life-lab.org/v3/teachers';
  LeaderboardService(this.token);

  Future<Map<String, String>> getHeaders() async {
    final token = await StorageUtil.getString(StringHelper.token);
    if (token.isEmpty) {
      throw Exception("Missing auth token");
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<LeaderboardEntry>> fetchTeacherLeaderboard({int page = 1}) async {
    final headers = await getHeaders();

    final response = await dio.get(
      '$baseUrl/leaderboard',
      queryParameters: {'page': page},
      options: Options(headers: headers),
    );

    debugPrint('Status code: ${response.statusCode}');
    debugPrint('Response body: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        final List entries = data['data'];
        return entries.map((e) => LeaderboardEntry.fromTeacherJson(e)).toList();
      }
    }
    throw Exception('Failed to load teacher leaderboard');
  }

  Future<List<LeaderboardEntry>> fetchSchoolLeaderboard({int page = 1}) async {
    final headers = await getHeaders();

    final response = await dio.get(
      '$baseUrl/school-leaderboard',
      queryParameters: {'page': page},
      options: Options(headers: headers),
    );

    debugPrint('Status code: ${response.statusCode}');
    debugPrint('Response body: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        final List entries = data['data'];
        return entries.map((e) => LeaderboardEntry.fromSchoolJson(e)).toList();
      }
    }
    throw Exception('Failed to load school leaderboard');
  }
}
