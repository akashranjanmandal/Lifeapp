import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';

class TeacherDashboardService {
  Dio dio = Dio();

  // Add this method to get headers with API key
  Future<Map<String, String>> _getHeaders() async {
    final token = StorageUtil.getString(StringHelper.token);
    return {
      HttpHeaders.acceptHeader: "application/json",
      HttpHeaders.contentTypeHeader: "application/json",
      "x-api-key": "gasdgg_555gae1_a151ghrhtj_k548jt_fsc265461hjvb",
      if (token.isNotEmpty) HttpHeaders.authorizationHeader: "Bearer $token",
    };
  }

  Future<Response?> getCompetencies(Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getCompetency,
        data: FormData.fromMap(body),
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      debugPrint("Competencies Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Competencies Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading competencies");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Competencies Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Competencies Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getConceptCartoon(Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getConceptCartoon,
        data: FormData.fromMap(body),
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      debugPrint("Concept Cartoon Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Concept Cartoon Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading concept cartoons");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Concept Cartoon Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Concept Cartoon Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getAssessment(Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getAssessment,
        data: FormData.fromMap(body),
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      debugPrint("Get Assessment Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Get Assessment Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading assessments");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Get Assessment Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Get Assessment Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getWorkSheet(Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getWorksheet,
        data: FormData.fromMap(body),
        options: Options(headers: headers),
      );

      debugPrint("Get Worksheet Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Get Worksheet Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading worksheets");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Get Worksheet Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Get Worksheet Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getConceptCartoonHeader() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.getConceptCartoonHeader,
        options: Options(headers: headers),
      );

      debugPrint("Concept Cartoon Header Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Concept Cartoon Header Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading concept cartoon headers");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Concept Cartoon Header Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Concept Cartoon Header Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getPblLanguages() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.PblLanguage,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      debugPrint("PBL Languages API Response: ${response.statusCode}");
      debugPrint("PBL Languages API Data: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("PBL Languages API Dio Error: ${e.response?.data}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Failed to load PBL languages");
      return null;
    } on SocketException catch(e) {
      debugPrint("PBL Languages API Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      debugPrint("PBL Languages API Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getLessonLanguage() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.lessonLanguage,
        options: Options(headers: headers),
      );

      debugPrint("Lesson Language Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Lesson Language Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading lesson languages");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Lesson Language Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Lesson Language Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getSubject() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.subjects,
        options: Options(headers: headers),
      );

      debugPrint("subjects Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Subjects Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading subjects");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Subjects Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Subjects Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getBoards() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.getBoard,
        options: Options(headers: headers),
      );

      debugPrint("Boards API Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Boards API Error: ${e.response?.data}");
      return null;
    } catch (e) {
      debugPrint("Boards API Exception: $e");
      return null;
    }
  }

  Future<Response?> getGrades() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.teachersGrade,
        options: Options(headers: headers),
      );

      debugPrint("Grades Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Grades Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error loading grades");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Grades Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Grades Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> getTeacherSubjectGrade() async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.get(
        ApiHelper.baseUrl + "/v3/TeacherSubjectGrade/", // Changed to use ApiHelper.baseUrl
        options: Options(headers: headers),
      );

      debugPrint("TeacherSubjectGrade API Response: ${response.statusCode}");
      debugPrint("TeacherSubjectGrade API Response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("TeacherSubjectGrade Error: ${e.response?.data}");
      return null;
    } catch (e) {
      debugPrint("TeacherSubjectGrade Exception: $e");
      return null;
    }
  }

  Future<Response?> submitPlan(Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();

      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.lessonPlan,
        data: body,
        options: Options(headers: headers),
      );

      debugPrint("Submit lesson plan Code: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      debugPrint("Submit lesson plan Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response?.data?["message"] ?? "Error submitting lesson plan");
      Loader.hide();
      return e.response;
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Submit lesson plan Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
      return null;
    } catch (e) {
      Loader.hide();
      debugPrint("Submit lesson plan Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
      return null;
    }
  }

  Future<Response?> postPblTextbookMappings(Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();

      // Remove la_board_id if null
      if (body['la_board_id'] == null) {
        body.remove('la_board_id');
      }

      // Debug: Print request body
      debugPrint("🔹 API Request Body: ${body.toString()}");

      Response response = await dio.post(
        ApiHelper.baseUrl + "/v3/pbl-textbook-mappings/", // Changed to use ApiHelper.baseUrl
        data: body,
        options: Options(headers: headers),
      );

      // Debug: Print full response
      debugPrint("✅ API Response [${response.statusCode}]: ${response.data}");
      return response;
    } catch (e, stacktrace) {
      debugPrint("❌ PBL Textbook Mappings Error: $e");
      debugPrint("❌ Stacktrace: $stacktrace");
      return null;
    }
  }
}