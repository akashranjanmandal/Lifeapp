// student_faq_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/student/home/models/student_faq_category_model.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';

class StudentFaqService {
  final Dio dio = Dio();

  /// Fetch raw FAQ list (optionally filtered by category and audience)
  Future<List<dynamic>> getStudentFaqsRaw({
    String? categoryId,
    String audience = 'student', // default to student
  }) async {
    try {
      final token = await StorageUtil.getString(StringHelper.token);

      final queryParams = {
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        'audience': audience,
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
      print("Error fetching Student FAQs: $e");
      return [];
    }
  }

  /// Returns strongly typed StudentFaq objects
  Future<List<StudentFaq>> getFaqsByCategory({
    String? categoryId,
    String audience = 'student',
  }) async {
    final raw =
        await getStudentFaqsRaw(categoryId: categoryId, audience: audience);

    // include items for the specific audience OR 'all'
    return raw
        .map((json) => StudentFaq.fromJson(json))
        .where((faq) => faq.audience == audience || faq.audience == 'all')
        .toList();
  }
}
