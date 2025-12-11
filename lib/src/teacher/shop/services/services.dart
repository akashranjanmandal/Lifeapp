import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../../common/helper/api_helper.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';
import '../models/model.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

class ProductService {
  final String token;
  final Dio dio = Dio();
  final String baseUrl = ApiHelper.baseUrl;

  ProductService(this.token);

  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ✅ Add this ↓↓↓
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
  Future<Map<String, dynamic>> fetchProductsWithCoins() async {
    final token = await StorageUtil.getString(StringHelper.token);

    final res = await dio.get(
      '$baseUrl/v3/coupon/teacher/list',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ),
    );

    if (res.statusCode == 200) {
      // Return the full response with flags, NOT res.data['data']
      return res.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load products: ${res.data}');
    }
  }

  Future<List<Product>> fetchProducts() async {
    final token = await StorageUtil.getString(StringHelper.token);

    developer.log('Fetching products from $baseUrl/v3/coupon/teacher/list', name: 'ProductService');
    developer.log('Using token: $token', name: 'ProductService');

    if (token.isEmpty) {
      throw Exception('Auth token is empty, user might not be logged in');
    }

    final res = await dio.get(
      '$baseUrl/v3/teacher/list',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ),
    );
    developer.log('Response status: ${res.statusCode}', name: 'ProductService');
    developer.log('Response data: ${res.data}', name: 'ProductService');

    if (res.statusCode == 200) {
      final data = (res.data['data'] ?? []) as List;
      return data.map((e) => Product.fromJson(e)).toList();

    } else if (res.statusCode == 401) {
      // Handle token expiry or unauthenticated state here
      throw Exception('Unauthorized: Token invalid or expired');
    } else {
      throw Exception('Failed to load products: ${res.data}');
    }
  }

  Future<List<Purchase>> fetchPurchaseHistory() async {
    try {
      final url = '$baseUrl/v3/coupon/teacher/purchase-history';
      debugPrint('[ProductService] Fetching purchase history from $url');

      final headers = await getHeaders(); // get token headers

      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );

      debugPrint('[ProductService] Response status: ${response.statusCode}');
      debugPrint('[ProductService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => Purchase.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load purchase history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[ProductService] Dio Error: ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ProductService] Unknown Error: $e');
      rethrow;
    }
  }

  Future<int> redeemProduct(int productId) async {
    try {
      final url = '$baseUrl/v3/coupon/$productId/redeem';
      debugPrint('[ProductService] Redeeming product id $productId at $url');

      final headers = await getHeaders(); // ✅ includes token

      final response = await dio.post(
        url,
        options: Options(headers: headers),
      );

      debugPrint('[ProductService] Response status: ${response.statusCode}');
      debugPrint('[ProductService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final jsonBody = response.data;
        if (jsonBody.containsKey('data') && jsonBody['data'] != null) {
          return jsonBody['data']['coins'] as int;
        } else {
          final errorMsg = jsonBody['message'] ?? 'Redeem failed';
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = response.data['error'] ?? 'Redeem failed';
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      debugPrint('[ProductService] Dio Error: ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ProductService] Unknown Error: $e');
      rethrow;
    }
  }

  Future<List<CoinTransaction>> fetchCoinTransactions() async {
    try {
      final url = '$baseUrl/v3/coupon/teacher/coin-history'; // replace with correct endpoint
      final headers = await getHeaders();

      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );

      debugPrint('[ProductService] Response status (coin tx): ${response.statusCode}');
      debugPrint('[ProductService] Response data (coin tx): ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((json) => CoinTransaction.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token invalid or expired');
      } else {
        throw Exception('Failed to load coin transactions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[ProductService] Dio Error (coin tx): ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ProductService] Unknown Error (coin tx): $e');
      rethrow;
    }
  }


}
