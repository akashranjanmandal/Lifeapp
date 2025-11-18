import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../common/helper/api_helper.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';

class ToolServices {
  Dio dio = Dio();

  Future<void> storeToken() async {
    try {
      final deviceToken = await FirebaseMessaging.instance.getToken();
      if (deviceToken == null) {
        debugPrint("⚠️ Device token is null, cannot store");
        return;
      }

      final authToken = StorageUtil.getString(StringHelper.token);
      if (authToken == null) {
        debugPrint("⚠️ No auth token, skipping token sync");
        return;
      }

      Response response = await Dio().post(
        "${ApiHelper.baseUrl}${ApiHelper.storeToken}",
        data: {
          'device': Platform.isAndroid ? "android" : "ios",
          'device_token': deviceToken,
        },
        options: Options(
          contentType: "application/json",
          headers: {
            "Authorization": "Bearer $authToken",
            "Accept": "application/json",
          },
        ),
      );

      debugPrint("✅ store token code: ${response.statusCode}");
      debugPrint("✅ store token data: ${response.data}");
    } on SocketException catch (e) {
      debugPrint("❌ store token Socket Error: $e");
    } on DioException catch (e) {
      debugPrint("❌ store token Dio Error: ${e.message}");
      if (e.response != null) {
        debugPrint("Response: ${e.response!.data}");
      }
    } catch (e) {
      debugPrint("❌ store token Catch Error: $e");
    }
  }

  Future getStudentList(Map<String, dynamic> data) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getClassStudent,
        data: data,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint("Get Class Student Code: ${response.statusCode}");
      debugPrint("Get Class Student Code: ${response.data}");

      if (response.statusCode == 200) {
        return response;
      }
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Get Class Student Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } on DioException catch (e) {
      debugPrint("Get Class Student Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("Get Class Student Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getTopicData(String type) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.topic,
        data: {"type": type},
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("Get Teacher Topic Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Get Teacher Topic Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Get Teacher Topic Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Get Teacher Topic Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future assignStudent(Map<String, dynamic> data) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.assignMission,
        data: data,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint("Assign Mission Code: ${response.statusCode}");

      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Assign Mission Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } on DioException catch (e) {
      debugPrint("Assign Mission Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("Assign Mission Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future assignTopic(Map<String, dynamic> data) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.assignTopic,
        data: data,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint("Assign Topic Code: ${response.statusCode}");

      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Assign Topic Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } on DioException catch (e) {
      debugPrint("Assign Topic Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("Assign Topic Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

// Get all student report
  Future getAllStudentReport() async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.getAllStudent,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint("All Student Code: ${response.statusCode}");
      debugPrint("All Student Data: ${response.data}");

      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("All Student Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } on DioException catch (e) {
      debugPrint("All Student Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("All Student Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getAllStudentMissionList({required String userId}) async {
    try {
      Response response = await dio.get(
        "${ApiHelper.baseUrl}${ApiHelper.getStudentMissions}?user_id=$userId",
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint("Student Mission Code: ${response.statusCode}");
      log("Student Mission Data: ${response.data}");

      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Student Mission Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } on DioException catch (e) {
      debugPrint("Student Mission Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("Student Mission Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getTeacherGrade() async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.teachersGrade,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint("Get Teacher Grade Section Code: ${response.statusCode}");
      debugPrint("Get Teacher Grade Section Data: ${response.data}");

      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Get Teacher Grade Section Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } on DioException catch (e) {
      debugPrint("Get Teacher Grade Section Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("Get Teacher Grade Section Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  // Get class student report
  Future getClassStudentReport(String gradeId, {String? timeline}) async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.classStudent + gradeId,
        queryParameters: timeline != null ? {"timeline": timeline} : null,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );
      debugPrint("📡 API Payload: $response");
      debugPrint("Class Student Code: ${response.statusCode}");
      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Class Student Socket Error: $e");
      Fluttertoast.showToast(msg: "No internet connection");
    } on DioException catch (e) {
      debugPrint("Class Student Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("Class Student Catch Error: $e");
      Fluttertoast.showToast(msg: "Something went wrong");
    }
  }

  Future getAssignMissionData({
    int? type,
    String? subjectId,
    String? levelId,
  }) async {
    try {
      // Build params only if values exist
      final Map<String, dynamic> params = {"type": type};

      if (subjectId != null && subjectId.isNotEmpty) {
        params["la_subject_id"] = subjectId;
      }

      if (levelId != null && levelId.isNotEmpty) {
        params["la_level_id"] = levelId;
      }

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.getTeacherMission,
        queryParameters:
            params.isEmpty ? null : params, // 👈 no params if empty
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("Get Mission Params: $params");
      debugPrint("Get Mission Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Get Mission Dio Error ${e.response}");
      Fluttertoast.showToast(
          msg: e.response?.data?["message"] ?? "Something went wrong");
      Loader.hide();
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Get Mission Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Get Mission Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getTeacherMissionParticipant({required String missionId}) async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.getTeacherMissionParticipant + missionId,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint(
          "Get Teacher Mission Participant Code: ${response.statusCode}");

      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Get Teacher Mission Participant Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } on DioException catch (e) {
      debugPrint("Get Teacher Mission Participant Dio Error ${e.response}");
      Loader.hide();
    } catch (e) {
      Loader.hide();
      debugPrint("Get Teacher Mission Participant Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future<Response?> submitTeacherMissionApproveReject(
      {required String studentId,
      required int status,
      required String comment}) async {
    try {
      Response response = await dio.patch(
        "${ApiHelper.baseUrl}${ApiHelper.teacherMissionApproveReject}$studentId/status",
        data: {"comment": comment, "status": status},
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer ${StorageUtil.getString(StringHelper.token)}",
          },
        ),
      );

      debugPrint("Submit Teacher Mission Status Code: ${response.statusCode}");
      debugPrint("Submit Teacher Mission Status Code: ${response.data}");
      debugPrint("Submit Teacher Mission Status Code: $studentId");

      return response;
    } on SocketException catch (e) {
      Loader.hide();
      debugPrint("Submit Teacher Mission Status Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } on DioException catch (e) {
      debugPrint("Submit Teacher Mission Status Dio Error ${e.response}");
      Loader.hide();
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Submit Teacher Mission Status Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }
}
