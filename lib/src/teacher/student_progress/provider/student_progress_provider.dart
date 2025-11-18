// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as d;
import 'dart:typed_data';
import 'dart:ui';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/utils/show_download_notifications.dart';
import 'package:lifelab3/src/teacher/student_progress/model/teacher_grade_section_model.dart';
import 'package:lifelab3/src/teacher/student_progress/model/teacher_mission_list_model.dart';
import 'package:lifelab3/src/teacher/student_progress/model/teacher_mission_participant_model.dart';
import 'package:lifelab3/src/teacher/teacher_tool/model/all_student_report_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../teacher_tool/services/tool_services.dart';
import '../model/student_missions_model.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';

class StudentProgressProvider extends ChangeNotifier {
  TextEditingController searchController = TextEditingController();

  AllStudentReportModel? allStudentReportModel;
  StudentMissionsModel? studentMissionsModel;
  TeacherGradeSectionModel? teacherGradeSectionModel;
  TeacherMissionListModel? teacherMissionListModel;
  TeacherMissionParticipantModel? teacherMissionParticipantModel;
  bool isImageProcessing = false;

  void getAllStudent() async {
    Response response = await ToolServices().getAllStudentReport();

    if (response.statusCode == 200) {
      allStudentReportModel = AllStudentReportModel.fromJson(response.data);
      notifyListeners();
    } else {
      allStudentReportModel = null;
    }
  }

  void getAllStudentMissionList({required String userId}) async {
    Response response =
        await ToolServices().getAllStudentMissionList(userId: userId);

    if (response.statusCode == 200) {
      studentMissionsModel = StudentMissionsModel.fromJson(response.data);
      notifyListeners();
    } else {
      studentMissionsModel = null;
    }
  }

  void getTeacherGrade() async {
    Response response = await ToolServices().getTeacherGrade();

    if (response.statusCode == 200) {
      teacherGradeSectionModel =
          TeacherGradeSectionModel.fromJson(response.data);
      notifyListeners();
    } else {
      teacherGradeSectionModel = null;
    }
  }

  void getClassStudent(String gradeId, {String? timeline}) async {
    // Build API URL
    String url = ApiHelper.baseUrl + ApiHelper.classStudent + gradeId;
    if (timeline != null && timeline.isNotEmpty && timeline != "All") {
      url += "?timeline=$timeline";
    }

    print("CALLING API: $url");

    try {
      Response response = await ToolServices().getClassStudentReport(
        gradeId,
        timeline: timeline,
      );

      print("API Hit Status: ${response.statusCode}");
      debugPrint(jsonEncode(response.data), wrapWidth: 1024);

      if (response.statusCode == 200) {
        allStudentReportModel = AllStudentReportModel.fromJson(response.data);

        // DEBUG: Log what got parsed into the model
        if (allStudentReportModel?.data != null) {
          print(" PARSED MODEL VALUES:");
          print("  - totalVision: ${allStudentReportModel!.data!.totalVision}");
          print(
              "  - totalMission: ${allStudentReportModel!.data!.totalMission}");
          print("  - totalQuiz: ${allStudentReportModel!.data!.totalQuiz}");
          print("  - totalCoins: ${allStudentReportModel!.data!.totalCoins}");

          // TEMPORARY WORKAROUND: Calculate totals manually if API returns 0
          if ((allStudentReportModel!.data!.totalVision == 0 ||
                  allStudentReportModel!.data!.totalMission == 0) &&
              allStudentReportModel!.data!.student != null) {
            int calculatedVision = 0;
            int calculatedMission = 0;

            for (var student in allStudentReportModel!.data!.student!) {
              calculatedVision += student.vision ?? 0;
              calculatedMission += student.mission ?? 0;
            }

            allStudentReportModel!.data!.totalVision = calculatedVision;
            allStudentReportModel!.data!.totalMission = calculatedMission;

            print(" FRONTEND WORKAROUND APPLIED:");
            print("  Calculated totalVision: $calculatedVision");
            print("  Calculated totalMission: $calculatedMission");
          }
        } else {
          print("allStudentReportModel.data is NULL after parsing!");
        }

        notifyListeners();
      } else {
        allStudentReportModel = null;
        notifyListeners();
        Fluttertoast.showToast(msg: "Failed to fetch class data");
      }
    } catch (e) {
      print("Error fetching class students: $e");
      allStudentReportModel = null;
      notifyListeners();
      Fluttertoast.showToast(msg: "Something went wrong. Please try again.");
    }
  }

  void getTeacherMission(Map<String, dynamic> data) async {
    Response response = await ToolServices().getAssignMissionData(
      type: data["type"],
      subjectId: data["la_subject_id"],
      levelId: data["la_level_id"],
    );
    if (response.statusCode == 200) {
      teacherMissionListModel = TeacherMissionListModel.fromJson(response.data);
      notifyListeners();
    } else {
      teacherMissionListModel = null;
    }
  }

  void getTeacherMissionParticipant(String missionId) async {
    Response response =
        await ToolServices().getTeacherMissionParticipant(missionId: missionId);

    if (response.statusCode == 200) {
      d.log("Data ${jsonEncode(response.data)}");
      teacherMissionParticipantModel =
          TeacherMissionParticipantModel.fromJson(response.data);
      notifyListeners();
    } else {
      teacherMissionParticipantModel = null;
    }
  }

  Future<SubmitMissionResponse?> submitApproveReject({
    required int status,
    required String comment,
    required String studentId,
    required BuildContext context,
    required String missionId,
  }) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(),
      overlayColor: Colors.black54,
    );

    try {
      Response? response =
          await ToolServices().submitTeacherMissionApproveReject(
        status: status,
        comment: comment,
        studentId: studentId,
      );

      Loader.hide();

      if (response != null && response.statusCode == 200) {
        Fluttertoast.showToast(msg: response.data["message"]);

        // Parse and return the API response
        return SubmitMissionResponse.fromJson(response.data);
      } else {
        Fluttertoast.showToast(msg: "Try again later");
      }
    } catch (e) {
      Loader.hide();
      Fluttertoast.showToast(msg: "Try again later");
    }

    return null;
  }

//download image
  void downloadImage(BuildContext context, GlobalKey boundaryKey) async {
    int androidVersion = 0;
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var release = androidInfo.version.release;
      androidVersion = int.tryParse(release.split(".").first) ?? 0;
    }

    var randomNum = Random();
    Directory? directory;
    var statusPermission = androidVersion < 12
        ? (await Permission.storage.request())
        : PermissionStatus.granted;
    if (statusPermission.isDenied) return;

    if (statusPermission.isGranted) {
      Loader.show(
        context,
        progressIndicator: const CircularProgressIndicator(),
        overlayColor: Colors.black54,
      );
      try {
        isImageProcessing = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));

        RenderRepaintBoundary? boundary = boundaryKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;

        var image = await boundary.toImage(pixelRatio: 3);
        ByteData? byteData =
            await image.toByteData(format: ImageByteFormat.png);
        Uint8List? uInt8list = byteData!.buffer.asUint8List();

        if (Platform.isIOS) {
          directory = await getTemporaryDirectory();
          if (!await directory.exists())
            await directory.create(recursive: true);
          final file = await File(
                  '${directory.path}/Lifelab_${randomNum.nextInt(1000000)}.png')
              .create();
          await file.writeAsBytes(uInt8list);
          //show notification
          if (await file.exists()) {
            await showDownloadNotification(file.path);
          } else {
            Fluttertoast.showToast(msg: "File not saved!");
          }
          Fluttertoast.showToast(msg: 'Downloaded');
        } else {
          directory = await getExternalStorageDirectory();
          File file = await File(
                  "/storage/emulated/0/Download/Lifelab_${randomNum.nextInt(1000000)}.png")
              .create(recursive: true);
          await file.writeAsBytes(uInt8list);
          //show notification
          if (await file.exists()) {
            await showDownloadNotification(file.path);
          } else {
            Fluttertoast.showToast(msg: "File not saved!");
          }
          Fluttertoast.showToast(msg: 'Downloaded');
        }
        Loader.hide();
      } catch (e) {
        Loader.hide();
        Fluttertoast.showToast(msg: "Please try again later!");
      }
      isImageProcessing = false;
      notifyListeners();
    }
  }
  // Download PDF method
  Future<void> downloadPDF(
      BuildContext context,
      String gradeName,
      String sectionName,
      String subjectName,
      String gradeId,
      )
  async {
    int androidVersion = 0;
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var release = androidInfo.version.release;
      androidVersion = int.tryParse(release.split(".").first) ?? 0;
    }

    var statusPermission = androidVersion < 12
        ? (await Permission.storage.request())
        : PermissionStatus.granted;

    if (statusPermission.isDenied) {
      Fluttertoast.showToast(msg: "Storage permission denied");
      return;
    }

    if (allStudentReportModel == null || allStudentReportModel!.data == null) {
      Fluttertoast.showToast(msg: "Data not ready for download!");
      return;
    }

    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(),
      overlayColor: Colors.black54,
    );

    try {
      isImageProcessing = true;
      notifyListeners();

      // Generate PDF
      final pdf = await _generatePDF(gradeName, sectionName, subjectName);

      // Save PDF
      Directory directory;
      String filePath;
      var randomNum = Random();

      if (Platform.isIOS) {
        directory = await getTemporaryDirectory();
        filePath = '${directory.path}/ClassReport_${gradeName}_${sectionName}_${randomNum.nextInt(1000000)}.pdf';
      } else {
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        filePath = '/storage/emulated/0/Download/ClassReport_${gradeName}_${sectionName}_${randomNum.nextInt(1000000)}.pdf';
      }

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Show notification
      if (await file.exists()) {
        await showDownloadNotification(filePath);
        Fluttertoast.showToast(msg: 'PDF Downloaded Successfully');
      } else {
        Fluttertoast.showToast(msg: "File not saved!");
      }

      Loader.hide();

    } catch (e) {
      Loader.hide();
      Fluttertoast.showToast(msg: "PDF download failed: $e");
    }

    isImageProcessing = false;
    notifyListeners();
  }

  // Generate PDF method
  Future<pw.Document> _generatePDF(
      String gradeName,
      String sectionName,
      String subjectName,
      )
  async {
    final data = allStudentReportModel!.data!;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CLASS DETAILS Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Class $gradeName $sectionName",
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Subject : $subjectName",
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        "${data.student!.length}",
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Students",
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  )
                ],
              ),

              pw.SizedBox(height: 25),

              // PERFORMANCE SUMMARY
              pw.Text(
                'Performance Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),

              pw.SizedBox(height: 10),

              // Performance Summary Cards
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                margin: pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPDFStatCard("Vision\nCompleted", "${data.totalVision ?? ""}"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Mission\nCompleted", "${data.totalMission ?? ""}"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Quiz", "${data.totalQuiz ?? ""}"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Coins\nEarned", "${data.totalCoins ?? ""}"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Coins\nRedeemed", "${data.coinsRedeemed ?? ""}"),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // PERFORMANCE DETAILS
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                margin: pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Vision Stats
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Vision Stats ",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        children: [
                          pw.TextSpan(
                            text: "(Completion rate ${data.visionCompletionRate ?? 0}%)",
                            style: pw.TextStyle(
                              color: PdfColors.blue,
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFDetailRow("Assigned", "${data.totalVisionAssigned ?? 0}"),
                    _buildPDFDetailRow("Complete", "${data.totalVision ?? 0}"),
                    _buildPDFDetailRow("Coins Earned", "${data.totalVisionCoins ?? 0}"),

                    pw.Divider(color: PdfColors.grey, thickness: 1),
                    pw.SizedBox(height: 10),

                    // Mission Stats
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Mission Stats ",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        children: [
                          pw.TextSpan(
                            text: "(Completion rate ${data.missionCompletionRate ?? 0}%)",
                            style: pw.TextStyle(
                              color: PdfColors.blue,
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFDetailRow("Assigned", "${data.totalMissionAssigned ?? 0}"),
                    _buildPDFDetailRow("Complete", "${data.totalMission ?? 0}"),
                    _buildPDFDetailRow("Coins Earned", "${data.totalMissionCoins ?? 0}"),

                    pw.Divider(color: PdfColors.grey, thickness: 1),
                    pw.SizedBox(height: 10),

                    // Quiz Stats
                    pw.Text(
                      'Quiz Set Status',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFDetailRow("Total Quiz", "${data.totalQuiz ?? 0}"),
                    _buildPDFDetailRow("Coins Earned", "${data.quizTotalCoins ?? 0}"),
                  ],
                ),
              ),

              // Footer with timestamp
              pw.SizedBox(height: 20),
              pw.Text(
                "Generated on ${DateTime.now().toString()}",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Helper methods for PDF generation
  pw.Widget _buildPDFStatCard(String title, String value) {
    return pw.Expanded(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 11,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFVerticalDivider() {
    return pw.Container(
      width: 1,
      height: 50,
      color: PdfColors.grey,
      margin: pw.EdgeInsets.symmetric(horizontal: 1),
    );
  }

  pw.Widget _buildPDFDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.Spacer(),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Add to StudentProgressProvider class

// Download Individual Student PDF
  Future<void> downloadStudentPDF(
      BuildContext context,
      String studentName,
      String sectionName,
      String schoolName,
      String location,
      int vision,
      int mission,
      int quiz,
      int coins,
      int coinsRedeemed,
      int visionAssigned,
      int visionCompleted,
      int visionCoins,
      int visionCompletionRate,
      int missionAssigned,
      int missionCompleted,
      int missionCoins,
      int missionCompletionRate,
      int quizCompleted,
      int quizCoins,
      ) async {
    int androidVersion = 0;
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var release = androidInfo.version.release;
      androidVersion = int.tryParse(release.split(".").first) ?? 0;
    }

    var statusPermission = androidVersion < 12
        ? (await Permission.storage.request())
        : PermissionStatus.granted;

    if (statusPermission.isDenied) {
      Fluttertoast.showToast(msg: "Storage permission denied");
      return;
    }

    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(),
      overlayColor: Colors.black54,
    );

    try {
      isImageProcessing = true;
      notifyListeners();

      // Generate PDF
      final pdf = await _generateStudentPDF(
        studentName,
        sectionName,
        schoolName,
        location,
        vision,
        mission,
        quiz,
        coins,
        coinsRedeemed,
        visionAssigned,
        visionCompleted,
        visionCoins,
        visionCompletionRate,
        missionAssigned,
        missionCompleted,
        missionCoins,
        missionCompletionRate,
        quizCompleted,
        quizCoins,
      );

      // Save PDF
      Directory directory;
      String filePath;
      var randomNum = Random();

      if (Platform.isIOS) {
        directory = await getTemporaryDirectory();
        filePath = '${directory.path}/StudentReport_${studentName.replaceAll(' ', '_')}_${randomNum.nextInt(1000000)}.pdf';
      } else {
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        filePath = '/storage/emulated/0/Download/StudentReport_${studentName.replaceAll(' ', '_')}_${randomNum.nextInt(1000000)}.pdf';
      }

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Show notification
      if (await file.exists()) {
        await showDownloadNotification(filePath);
        Fluttertoast.showToast(msg: 'Student PDF Downloaded Successfully');
      } else {
        Fluttertoast.showToast(msg: "File not saved!");
      }

      Loader.hide();

    } catch (e) {
      Loader.hide();
      Fluttertoast.showToast(msg: "PDF download failed: $e");
    }

    isImageProcessing = false;
    notifyListeners();
  }

// Generate Individual Student PDF
  Future<pw.Document> _generateStudentPDF(
      String studentName,
      String sectionName,
      String schoolName,
      String location,
      int vision,
      int mission,
      int quiz,
      int coins,
      int coinsRedeemed,
      int visionAssigned,
      int visionCompleted,
      int visionCoins,
      int visionCompletionRate,
      int missionAssigned,
      int missionCompleted,
      int missionCoins,
      int missionCompletionRate,
      int quizCompleted,
      int quizCoins,
      ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Student Header
              pw.Center(
                child: pw.Column(
                  children: [
                    // Student Name
                    pw.Text(
                      studentName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    // Class Info
                    pw.Text(
                      "Class: $sectionName",
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    // School Info
                    pw.Text(
                      schoolName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    // Location
                    pw.Text(
                      location,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),

              // Performance Summary
              pw.Text(
                'Performance Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),

              pw.SizedBox(height: 10),

              // Performance Summary Cards
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                margin: pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPDFStatCard("Vision", "$vision"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Mission", "$mission"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Quiz", "$quiz"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Coins\nEarned", "$coins"),
                    _buildPDFVerticalDivider(),
                    _buildPDFStatCard("Coins\nRedeemed", "$coinsRedeemed"),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Performance Details
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                margin: pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Vision Stats
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Vision Stats ",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        children: [
                          pw.TextSpan(
                            text: "(Completion rate $visionCompletionRate%)",
                            style: pw.TextStyle(
                              color: PdfColors.blue,
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFDetailRow("Assigned", "$visionAssigned"),
                    _buildPDFDetailRow("Complete", "$visionCompleted"),
                    _buildPDFDetailRow("Coins Earned", "$visionCoins"),

                    pw.Divider(color: PdfColors.grey, thickness: 1),
                    pw.SizedBox(height: 10),

                    // Mission Stats
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Mission Stats ",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        children: [
                          pw.TextSpan(
                            text: "(Completion rate $missionCompletionRate%)",
                            style: pw.TextStyle(
                              color: PdfColors.blue,
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFDetailRow("Assigned", "$missionAssigned"),
                    _buildPDFDetailRow("Complete", "$missionCompleted"),
                    _buildPDFDetailRow("Coins Earned", "$missionCoins"),

                    pw.Divider(color: PdfColors.grey, thickness: 1),
                    pw.SizedBox(height: 10),

                    // Quiz Stats
                    pw.Text(
                      'Quiz Set Status',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFDetailRow("Total Quiz", "$quizCompleted"),
                    _buildPDFDetailRow("Coins Earned", "$quizCoins"),
                  ],
                ),
              ),

              // Footer with timestamp
              pw.SizedBox(height: 20),
              pw.Text(
                "Generated on ${DateTime.now().toString()}",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
