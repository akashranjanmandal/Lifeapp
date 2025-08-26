import 'dart:io';
import 'package:dio/dio.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/teacher_faq_category_model.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';

class FaqTestService {
  final Dio dio = Dio();

  /// Fetch all FAQs (no audience filtering)
  Future<List<TeacherFaq>> getAllFaqs([String? categoryId]) async {
    try {
      final token = await StorageUtil.getString(StringHelper.token);

      final queryParams = {
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
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
        final rawList = response.data['data'] as List<dynamic>;
        return rawList.map((json) => TeacherFaq.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching all FAQs: $e");
      return [];
    }
  }
}
