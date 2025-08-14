import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/storage_utils.dart';
import '../../../common/helper/string_helper.dart';
import '../models/vision_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}

class TeacherVisionAPIService {
  static const String baseUrl = "https://api.life-lab.org/v3";
  static const int _REQUEST_TIMEOUT = 15;
  Future<String?> _getAuthToken() async {
    return StorageUtil.getString(StringHelper.token);
  }
  Future<List<TeacherVisionVideo>> _fetchVideos({
    String? subjectId,
    String? levelId,
    int page = 1,
    int perPage = 10,
    required bool isAllSubjects,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final Map<String, String> queryParams = {
        'per_page': perPage.toString(),
        'page': page.toString(),
      };

      if (!isAllSubjects && subjectId != null && subjectId.isNotEmpty) {
        queryParams['la_subject_id'] = subjectId;
      }
      if (levelId != null && levelId.isNotEmpty) {
        queryParams['la_level_id'] = levelId;
      }

      const endpoint = '$baseUrl/teachers/visions-list';
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      debugPrint('🔄 Fetching videos from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final videos = _parseVideoData(responseData['data']);
          if (videos.isEmpty) {
            debugPrint('ℹ️ API returned empty videos list');
          }
          return videos;
        } else {
          throw Exception(responseData['message'] ?? 'Unknown API error');
        }
      } else if (response.statusCode == 401) {
        await _clearAuthToken();
        throw Exception('Authentication failed');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 Error fetching videos: $e');
      rethrow;
    }
  }

  List<TeacherVisionVideo> _parseVideoData(Map<String, dynamic> data) {
    List<dynamic> videoData = [];

    if (data['visions'] != null) {
      final visions = data['visions'];
      if (visions is Map<String, dynamic> && visions['data'] != null) {
        videoData = visions['data'];
      } else if (visions is List) {
        videoData = visions;
      }
    } else if (data['videos'] != null) {
      final videos = data['videos'];
      if (videos is Map<String, dynamic> && videos['data'] != null) {
        videoData = videos['data'];
      } else if (videos is List) {
        videoData = videos;
      }
    }

    return videoData.map((item) => TeacherVisionVideo.fromJson(item)).toList();
  }

  Future<void> _clearAuthToken() async {
    await SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(StringHelper.token));
  }

  Future<List<TeacherVisionVideo>> getAllVisionVideos({
    String? levelId,
    int page = 1,
    int perPage = 10,
  }) async {
    return await _fetchVideos(
      levelId: levelId,
      page: page,
      perPage: perPage,
      isAllSubjects: true,
    );
  }

  Future<List<TeacherVisionVideo>> getVisionVideosBySubject(
      String subjectId, {
        String? levelId,
        int page = 1,
        int perPage = 10,
      }) async {
    return await _fetchVideos(
      subjectId: subjectId,
      levelId: levelId,
      page: page,
      perPage: perPage,
      isAllSubjects: false,
    );
  }
// Add this to TeacherVisionAPIService
  Future<List<Map<String, dynamic>>> getAllLevels() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/levels');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        debugPrint('Levels API response: $responseData'); // Add this for debugging

        if (responseData['status'] == 200 && responseData['data'] != null) {
          final dynamic data = responseData['data'];

          // Check for 'laLevels' key
          if (data is Map<String, dynamic> && data['laLevels'] != null) {
            try {
              final levels = List<Map<String, dynamic>>.from(data['laLevels']);
              debugPrint('Successfully parsed ${levels.length} levels');
              return levels;
            } catch (e) {
              debugPrint('Error parsing laLevels: $e');
              throw Exception('Failed to parse levels data');
            }
          }
          throw Exception('laLevels key not found in response');
        }
        throw Exception('Invalid API response status or data');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      debugPrint('❌ Error fetching levels: $e');
      rethrow;
    }
  }
  Future<List<TeacherVisionVideo>> getAssignedVideos({
    String? subjectId,
    String? levelId,
  })
  async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final Map<String, String> queryParams = {};
      if (subjectId != null && subjectId.isNotEmpty) {
        queryParams['la_subject_id'] = subjectId;
      }
      if (levelId != null && levelId.isNotEmpty) {
        queryParams['la_level_id'] = levelId;
      }

      final endpoints = [
        '$baseUrl/teachers/visions',
      ];

      for (final endpoint in endpoints) {
        try {
          final result = await _fetchFromEndpoint(endpoint, queryParams, token);
          if (result.isNotEmpty) {
            return result;
          }
        } catch (e) {
          continue;
        }
      }

      throw Exception('All assigned video endpoints failed');
    } catch (e) {
      debugPrint('❌ Error in getAssignedVideos: $e');
      rethrow;
    }
  }
  Future<List<TeacherVisionVideo>> searchVisionVideos({
    String? subjectId,
    String? levelId,
    required String searchTitle,
    required int page,
    required int perPage,
    required String authToken,
  })
  async {
    try {
      final Map<String, String> queryParams = {
        'search_title': searchTitle,
      };
      if (page > 0) queryParams['page'] = page.toString();
      if (perPage > 0) queryParams['per_page'] = perPage.toString();


      if (subjectId != null && subjectId.isNotEmpty) {
        queryParams['la_subject_id'] = subjectId;
      }
      if (levelId != null && levelId.isNotEmpty) {
        queryParams['la_level_id'] = levelId;
      }

      final uri = Uri.https('api.life-lab.org', '/v3/teachers/visions-list', queryParams);

      debugPrint('🔍 Searching Vision Videos');
      debugPrint('➡️ Request URI: $uri');
      debugPrint('➡️ Request Headers: Authorization=Bearer $authToken');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      debugPrint('⬅️ Response status: ${response.statusCode}');
      debugPrint('⬅️ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 200 && responseData['data'] != null) {
          return _parseVideoData(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Unknown API error during search');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - invalid or expired token');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('❌ Error in searchVisionVideos: $e');
      rethrow;
    }
  }

  Future<List<TeacherVisionVideo>> _fetchFromEndpoint(
      String endpoint,
      Map<String, String> queryParams,
      String token,
      )
  async {
    final uri = Uri.parse(endpoint)
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: _REQUEST_TIMEOUT),
      onTimeout: () =>
      throw TimeoutException('Request timed out after $_REQUEST_TIMEOUT seconds'),
    );

    if (response.statusCode == 200) {
      return _parseSuccessResponse(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  List<TeacherVisionVideo> _parseSuccessResponse(String responseBody) {
    final Map<String, dynamic> responseData = json.decode(responseBody);

    if (responseData['status'] != 200) {
      throw Exception(responseData['message'] ?? 'Unknown error');
    }

    if (responseData['data'] == null) {
      throw Exception('No data field in response');
    }

    final List<dynamic> videoData = _extractVideoData(responseData['data']);

    return videoData
        .map((item) => TeacherVisionVideo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _extractVideoData(Map<String, dynamic> data) {
    if (data['assigned_visions'] is List) {
      return data['assigned_visions'];
    }
    if (data['visions'] is Map) {
      final visions = data['visions'] as Map<String, dynamic>;
      if (visions['data'] is List) {
        return visions['data'];
      }
    }
    if (data['visions'] is List) {
      return data['visions'];
    }
    if (data['assignments'] is List) {
      return data['assignments'];
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/subjects');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final dynamic data = responseData['data'];
          if (data is Map<String, dynamic> && data['subject'] != null) {
            return List<Map<String, dynamic>>.from(data['subject']);
          } else if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          } else if (data is Map<String, dynamic>) {
            for (String key in ['subjects', 'items', 'list']) {
              if (data[key] is List) {
                return List<Map<String, dynamic>>.from(data[key]);
              }
            }
          }
        }
      }
      throw Exception('Failed to parse subjects');
    } catch (e) {
      debugPrint('❌ Error fetching subjects: $e');
      rethrow;
    }
  }

  Future<bool> assignVideoToStudents({
    required String videoId,
    required List<String> studentIds,
    String? dueDate,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/teachers/assign-visions');
      final payload = {
        'vision_id': int.tryParse(videoId) ?? videoId,
        'user_ids': studentIds.map((id) => int.tryParse(id) ?? id).toList(),
        'due_date': dueDate,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          return responseData['status'] == 200 ||
              responseData['success'] == true ||
              responseData.containsKey('data');
        } catch (e) {
          return true;
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('❌ Error assigning video: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStudentProgress(String assignmentId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/vision/progress/$assignmentId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching student progress: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVisionDetails(String visionId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/vision/$visionId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching vision details: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsForAssignment(
      Map<String, dynamic> data) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      if (!data.containsKey('school_id') || data['school_id'] == null) {
        throw Exception('School ID is required');
      }
      if (!data.containsKey('la_section_id') ||
          data['la_section_id'] == null ||
          data['la_section_id'].toString().isEmpty) {
        throw Exception('Section ID is required');
      }

      final uri = Uri.parse('$baseUrl/teachers/class-students');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          List<dynamic> studentsData = [];
          if (responseData['data']['users'] != null) {
            final usersObject = responseData['data']['users'];
            if (usersObject is Map<String, dynamic> &&
                usersObject['data'] != null) {
              studentsData = usersObject['data'];
            } else if (usersObject is List) {
              studentsData = usersObject;
            }
          } else if (responseData['data'] is List) {
            studentsData = responseData['data'];
          } else if (responseData['data']['students'] != null) {
            studentsData = responseData['data']['students'];
          } else if (responseData['data']['class_students'] != null) {
            studentsData = responseData['data']['class_students'];
          } else if (responseData['data']['data'] != null) {
            studentsData = responseData['data']['data'];
          }

          return studentsData
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error');
        }
      } else if (response.statusCode == 401) {
        await _clearAuthToken();
        throw Exception('Authentication failed');
      } else if (response.statusCode == 422) {
        throw Exception('Validation error: ${response.body}');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching students: $e');
      rethrow;
    }
  }

  Future<bool> unassignVision(String assignmentId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/vision/assignment/$assignmentId');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['status'] == 200;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('❌ Error unassigning vision: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVisionParticipants(
      String visionId, String? className) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse(
          '$baseUrl/teachers/vision/$visionId/participants-with-answers?class=$className');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final Map<String, dynamic> data = responseData['data'];
          final List<dynamic> participantsData = data['participants'] ?? [];
          return participantsData
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching participants: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSubmissionStatus(
      String visionCompleteId, dynamic newStatus) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri =
      Uri.parse('$baseUrl/teachers/vision-submission/$visionCompleteId/status');
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'comment': 'Ok',
          'status': newStatus.toString().split('.').last,
        }),
      ).timeout(const Duration(seconds: _REQUEST_TIMEOUT), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('❌ Error updating submission status: $e');
      rethrow;
    }
  }
}
