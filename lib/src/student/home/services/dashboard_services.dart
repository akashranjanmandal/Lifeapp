import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';
import 'package:lifelab3/src/student/home/models/campaign_model.dart';
import '../../../common/helper/api_helper.dart';

class DashboardServices {
  Dio dio = Dio();

  // Add API key constant
  static const String otpApiKey = "gasdgg_555gae1_a151ghrhtj_k548jt_fsc265461hjvb";

  DashboardServices() {
    // Configure Dio to handle 401 errors gracefully
    dio.options.validateStatus = (status) {
      return status! < 500; // Don't throw for client errors (4xx)
    };
  }

  // Helper method to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = StorageUtil.getString(StringHelper.token);
    debugPrint('🔐 Using token for request: ${token.isNotEmpty ? "YES" : "NO"}');

    return {
      HttpHeaders.acceptHeader: "application/json",
      HttpHeaders.contentTypeHeader: "application/json",
      "x-api-key": otpApiKey, // Add API key header
      if (token.isNotEmpty) HttpHeaders.authorizationHeader: "Bearer $token",
    };
  }

  Future<Response?> getDashboardData() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.dashboard,
        options: Options(headers: headers),
      );

      debugPrint("✅ Dashboard Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("❌ Dashboard Dio Error: ${e.message}");
      debugPrint("❌ Dashboard Response: ${e.response?.data}");

      if (e.response?.statusCode == 401) {
        debugPrint("🔄 401 Unauthorized in dashboard");
        _handleUnauthorized();
      } else {
        Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Failed to load dashboard");
      }

      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("❌ Dashboard Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("❌ Dashboard Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<List<Campaign>> getTodayCampaigns() async {
    try {
      final headers = await _getHeaders();

      final response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.campaignsToday, // Use from ApiHelper
        options: Options(headers: headers),
      );

      debugPrint("✅ Campaigns Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data["campaigns"] != null && data["campaigns"] is List) {
          final campaigns = (data["campaigns"] as List)
              .map((e) => Campaign.fromJson(e))
              .toList();
          debugPrint("✅ Loaded ${campaigns.length} campaigns");
          return campaigns;
        }
      } else if (response.statusCode == 401) {
        debugPrint("🔄 401 Unauthorized in campaigns");
        _handleUnauthorized();
      }

      return [];
    } on DioException catch (e) {
      debugPrint("❌ Campaigns Dio Error: ${e.message}");

      if (e.response?.statusCode == 401) {
        _handleUnauthorized();
      }

      return [];
    } catch (e) {
      debugPrint("❌ Error fetching campaigns: $e");
      return [];
    }
  }

  Future<Response?> getSubjectData() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.subjects,
        options: Options(headers: headers),
      );

      debugPrint("✅ Get Subject Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("❌ Get Subject Dio Error: ${e.message}");

      if (e.response?.statusCode == 401) {
        _handleUnauthorized();
      } else {
        Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Failed to load subjects");
      }

      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("❌ Get Subject Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("❌ Get Subject Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getCoinHistory() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.coinHistory,
        options: Options(headers: headers),
      );

      debugPrint("✅ Coin History Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("❌ Coin History Dio Error: ${e.message}");

      if (e.response?.statusCode == 401) {
        _handleUnauthorized();
      } else {
        Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Failed to load coin history");
      }

      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("❌ Coin History Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("❌ Coin History Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> subscribeCode({required String code, required String type}) async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.subscribeCode,
        data: {
          "enrollment_code": code,
          "type": type
        },
        options: Options(headers: headers),
      );

      debugPrint("✅ Subscribe Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("❌ Subscribe Dio Error: ${e.message}");

      if (e.response?.statusCode == 401) {
        _handleUnauthorized();
      } else {
        Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Failed to subscribe");
      }

      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("❌ Subscribe Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("❌ Subscribe Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> checkSubscription() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.checkSubscription,
        options: Options(headers: headers),
      );

      debugPrint("✅ Check Subscribe Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("❌ Check Subscribe Dio Error: ${e.message}");

      if (e.response?.statusCode == 401) {
        _handleUnauthorized();
      } else {
        Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Failed to check subscription");
      }

      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("❌ Check Subscribe Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("❌ Check Subscribe Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  void _handleUnauthorized() {
    debugPrint('🔄 Unauthorized access detected in DashboardServices - clearing storage');

    // Clear storage on unauthorized access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StorageUtil.putBool(StringHelper.isLoggedIn, false);
      StorageUtil.putString(StringHelper.token, '');
      StorageUtil.putBool(StringHelper.isTeacher, false);

      debugPrint('🔐 Storage cleared due to unauthorized access');
    });
  }
}