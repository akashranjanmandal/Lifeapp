import 'dart:io';
import 'package:dio/dio.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';
import 'package:lifelab3/src/student/home/models/faq_category_model.dart';

class FaqService {
  Dio dio = Dio();

  // Keep your existing method (still returns raw data if needed)
  Future<List<dynamic>> getFaqsByCategoryRaw([String? categoryId]) async {
    try {
      final token = await StorageUtil.getString(StringHelper.token);

      Map<String, dynamic> queryParams = {};
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }

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

      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error fetching FAQs: $e");
      return [];
    }
  }

  Future<List<Faq>> getFaqsByCategory([String? categoryId]) async {
    final raw = await getFaqsByCategoryRaw(categoryId);
    return raw.map((json) => Faq.fromJson(json)).toList();
  }
}
