import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../common/helper/api_helper.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';

class TeacherDashboardService {

  Dio dio = Dio();

  Future getCompetencies(Map<String, dynamic> body) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getCompetency,
        data: FormData.fromMap(body),
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      debugPrint("Competencies Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Competencies Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Competencies Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Competencies Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getConceptCartoon(Map<String, dynamic> body) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getConceptCartoon,
        data: FormData.fromMap(body),
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      debugPrint("Concept Cartoon Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Concept Cartoon Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Concept Cartoon Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Concept Cartoon Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getAssessment(Map<String, dynamic> body) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getAssessment,
        data: FormData.fromMap(body),
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      debugPrint("Get Assessment Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Get Assessment Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Get Assessment Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Get Assessment Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getWorkSheet(Map<String, dynamic> body) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.getWorksheet,
        data: FormData.fromMap(body),
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("Get Worksheet Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Get Worksheet Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Get Worksheet Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Get Worksheet Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getConceptCartoonHeader() async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.getConceptCartoonHeader,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("Concept Cartoon Header Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Concept Cartoon Header Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Concept Cartoon Header Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Concept Cartoon Header Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }

  Future getLessonLanguage() async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.lessonLanguage,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("Lesson Language Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Lesson Language Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Lesson Language Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Lesson Language Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }
  Future getSubject() async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.subjects,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("subjects Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Lesson Language Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Lesson Language Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Lesson Language Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }
  Future getGrades() async {
    try {
      Response response = await dio.get(
        ApiHelper.baseUrl + ApiHelper.teachersGrade,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("subjects Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Lesson Language Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Lesson Language Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Lesson Language Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }
// Add this method to your TeacherDashboardService class
  Future<Response?> getTeacherSubjectGrade() async {
    try {
      Response response = await dio.get(
        "https://api.life-lab.org/v3/TeacherSubjectGrade/",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
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
  Future submitPlan(Map<String, dynamic> body) async {
    try {
      Response response = await dio.post(
        ApiHelper.baseUrl + ApiHelper.lessonPlan,
        data: body,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );

      debugPrint("Submit lesson plan Code: ${response.statusCode}");

      return response;
    } on DioException catch (e) {
      debugPrint("Submit lesson plan Dio Error ${e.response}");
      Fluttertoast.showToast(msg: e.response!.data!["message"]);
      Loader.hide();
    } on SocketException catch(e) {
      Loader.hide();
      debugPrint("Submit lesson plan Socket Error: $e");
      Fluttertoast.showToast(msg: StringHelper.badInternet);
    } catch (e) {
      Loader.hide();
      debugPrint("Submit lesson plan Catch Error: $e");
      Fluttertoast.showToast(msg: StringHelper.tryAgainLater);
    }
  }
  Future<Response?> postPblTextbookMappings(Map<String, dynamic> body) async {
    try {
      // Remove la_board_id if null
      if (body['la_board_id'] == null) {
        body.remove('la_board_id');
      }

      Response response = await dio.post(
        "https://api.life-lab.org/v3/pbl-textbook-mappings/",
        data: body,
        options: Options(
          contentType: "application/json",
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader:
            "Bearer ${StorageUtil.getString(StringHelper.token)}"
          },
        ),
      );
      return response;
    } catch (e) {
      debugPrint("PBL Textbook Mappings Error: $e");
      return null;
    }
  }
}