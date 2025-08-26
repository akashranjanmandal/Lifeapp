import 'dart:io';
import 'package:dio/dio.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/teacher_faq_category_model.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';

class TeacherFaqService {
  final Dio dio = Dio();

  /// Fetch raw FAQ list (optionally filtered by category and audience)
  Future<List<dynamic>> getTeacherFaqsRaw({
    String? categoryId,
    String? audience, // 'teacher', 'student', or 'all'
  }) async {
    try {
      final token = await StorageUtil.getString(StringHelper.token);

      final queryParams = {
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (audience != null && audience.isNotEmpty) 'audience': audience,
      };

      final response = await dio.get(
        "https://api.life-lab.org/v3/faqs",
        queryParameters: queryParams,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer $token",
          },
        ),
      );

      print("Raw API response: ${response.data}");

      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error fetching Teacher FAQs: $e");
      return [];
    }
  }

  /// Returns strongly typed TeacherFaq objects with optional audience filter
  Future<List<TeacherFaq>> getFaqsByCategory({
    String? categoryId,
    String audience = 'teacher', // default to teacher
  }) async {
    final raw =
        await getTeacherFaqsRaw(categoryId: categoryId, audience: audience);

    // include items for the specific audience OR 'all'
    return raw
        .map((json) => TeacherFaq.fromJson(json))
        .where((faq) => faq.audience == audience)
        .toList();
  }
}
