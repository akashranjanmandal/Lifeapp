import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../common/helper/api_helper.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';
import 'package:flutter/foundation.dart';
import '../model/model.dart';

class LeaderboardService {
  final String token;
  final Dio dio = Dio();
  final String baseUrl = ApiHelper.baseUrl;
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

  Future<List<LeaderboardEntry>> fetchTeacherLeaderboard({
    String filter = 'monthly',
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await getHeaders();

    try {
      final response = await dio.get(
        '$baseUrl/v3/leaderboard/teachers',
        options: Options(headers: headers),
        queryParameters: {
          'filter': filter.toLowerCase(),
          'page': page,
          'limit': limit,
        },
      );

      debugPrint('Teacher Leaderboard Status code: ${response.statusCode}');
      debugPrint('Teacher Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // If response is a list
        if (data is List) {
          return data.map((e) => LeaderboardEntry.fromTeacherJson(e)).toList();
        }
        // If response has data field
        else if (data is Map && data.containsKey('data')) {
          final List<dynamic> items = data['data'];
          return items.map((e) => LeaderboardEntry.fromTeacherJson(e)).toList();
        }
        // If response is just the array directly
        else if (data is Map && data.containsKey('success')) {
          // Check if data field exists
          if (data['data'] is List) {
            return (data['data'] as List)
                .map((e) => LeaderboardEntry.fromTeacherJson(e))
                .toList();
          }
        }
      }

      throw Exception('Failed to load teacher leaderboard');
    } catch (e) {
      debugPrint('Error fetching teacher leaderboard: $e');
      rethrow;
    }
  }

  Future<List<LeaderboardEntry>> fetchSchoolLeaderboard({
    String filter = 'monthly',
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await getHeaders();

    try {
      final response = await dio.get(
        '$baseUrl/v3/leaderboard/school',
        options: Options(headers: headers),
        queryParameters: {
          'filter': filter.toLowerCase(),
          'page': page,
          'limit': limit,
        },
      );

      debugPrint('School Leaderboard Status code: ${response.statusCode}');
      debugPrint('School Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check response structure
        if (data is Map && data.containsKey('success') && data['success'] == true) {
          final List<dynamic>? schoolsList = data['data'];

          if (schoolsList != null && schoolsList is List) {
            return schoolsList.map((e) => LeaderboardEntry.fromSchoolJson(e)).toList();
          }
        }
        // If response is directly a list
        else if (data is List) {
          return data.map((e) => LeaderboardEntry.fromSchoolJson(e)).toList();
        }
      }

      throw Exception('Failed to load school leaderboard');
    } catch (e) {
      debugPrint('Error fetching school leaderboard: $e');
      rethrow;
    }
  }
}