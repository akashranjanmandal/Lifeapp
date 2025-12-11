import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../common/helper/api_helper.dart';
import '../../../common/helper/string_helper.dart';

class TeacherLoginServices {
  Dio dio = Dio();

  // Add your OTP API key here
  static const String otpApiKey = "gasdgg_555gae1_a151ghrhtj_k548jt_fsc265461hjvb";

  Future sendOtp(Map<String, dynamic> data) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.sendOtp,
        data: data,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            "x-api-key": otpApiKey, // Add API key header
          },
        ),
      );

      debugPrint("Teacher Login Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Teacher Login Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Something went wrong");
      Loader.hide();
      rethrow; // Re-throw to handle in provider
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Teacher Login Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      rethrow;
    } catch (e) {
      Loader.hide();
      debugPrint("Teacher Login Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      rethrow;
    }
  }

  Future confirmOtp(Map<String, dynamic> data) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.verifyOtp,
        data: data,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            "x-api-key": otpApiKey, // Add API key header for verification too
          },
        ),
      );

      debugPrint("Mentor Verify Otp Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Mentor Verify Otp Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Something went wrong");
      Loader.hide();
      rethrow;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Mentor Verify Otp Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      rethrow;
    } catch (e) {
      Loader.hide();
      debugPrint("Mentor Verify Otp Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      rethrow;
    }
  }
}