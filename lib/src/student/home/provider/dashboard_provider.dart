import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/student/home/models/coin_history_model.dart';
import 'package:lifelab3/src/student/home/models/dashboard_model.dart';
import 'package:lifelab3/src/student/home/models/subject_model.dart';
import 'package:lifelab3/src/student/home/services/dashboard_services.dart';
import 'package:lifelab3/src/teacher/teacher_tool/services/tool_services.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';
import 'package:lifelab3/src/student/home/models/campaign_model.dart';
import '../../../common/helper/color_code.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardModel? dashboardModel;
  SubjectModel? subjectModel;
  CoinsHistoryModel? coinsHistoryModel;

  List<Campaign> _campaigns = [];
  List<Campaign> get campaigns => _campaigns;

  String? subscribeCode;

  // Fetch campaigns
  Future<void> getTodayCampaigns() async {
    try {
      _campaigns = await DashboardServices().getTodayCampaigns();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching campaigns: $e");
      _campaigns = [];
      notifyListeners();
    }
  }

  Future<void> getDashboardData() async {
    try {
      Response? response = await DashboardServices().getDashboardData();

      if (response != null && response.statusCode == 200) {
        dashboardModel = DashboardModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("Failed to load dashboard data: ${response?.statusCode}");
        // Don't clear existing data, just fail silently or show error
      }
    } catch (e) {
      debugPrint("Error in getDashboardData: $e");
    }
  }

  Future<void> storeToken() async {
    try {
      await ToolServices().storeToken();
    } catch (e) {
      debugPrint("Error storing token: $e");
    }
  }

  Future<void> getSubjectsData() async {
    try {
      Response? response = await DashboardServices().getSubjectData();

      if (response != null && response.statusCode == 200) {
        subjectModel = SubjectModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("Failed to load subjects: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("Error in getSubjectsData: $e");
    }
  }

  Future<void> getCoinHistoryData() async {
    try {
      Response? response = await DashboardServices().getCoinHistory();

      if (response != null && response.statusCode == 200) {
        coinsHistoryModel = CoinsHistoryModel.fromJson(response.data);
        notifyListeners();
      } else {
        debugPrint("Failed to load coin history: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("Error in getCoinHistoryData: $e");
    }
  }

  Future<void> subscribe(BuildContext context, String type) async {
    if (subscribeCode == null || subscribeCode!.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a subscription code");
      return;
    }

    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor),
      overlayColor: Colors.black54,
    );

    try {
      Response? response = await DashboardServices().subscribeCode(
        code: subscribeCode!,
        type: type,
      );

      Loader.hide();

      if (response != null && response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Subscribed successfully");
        Navigator.pop(context);
        await getDashboardData();
        await checkSubscription();
      } else {
        Fluttertoast.showToast(msg: response?.data?["message"] ?? "Please try again later");
      }
    } catch (e) {
      Loader.hide();
      debugPrint("Error in subscribe: $e");
      Fluttertoast.showToast(msg: "Please try again later");
    }
  }

  Future<void> checkSubscription() async {
    try {
      Response? response = await DashboardServices().checkSubscription();

      if (response != null && response.statusCode == 200) {
        final data = response.data["data"];
        StorageUtil.putBool(StringHelper.isJigyasa, data["JIGYASA"] == 1);
        StorageUtil.putBool(StringHelper.isPragya, data["PRAGYA"] == 1);
        StorageUtil.putBool(StringHelper.isTeacherLifeLabDemo, data["LIFE_LAB_DEMO_MODELS"] == 1);
        StorageUtil.putBool(StringHelper.isTeacherJigyasa, data["JIGYASA_SELF_DIY_ACTVITES"] == 1);
        StorageUtil.putBool(StringHelper.isTeacherPragya, data["PRAGYA_DIY_ACTIVITES_WITH_LIFE_LAB_KITS"] == 1);
        StorageUtil.putBool(StringHelper.isTeacherLesson, data["LIFE_LAB_ACTIVITIES_LESSION_PLANS"] == 1);

        debugPrint("✅ Subscription status updated");
      } else {
        debugPrint("❌ Failed to check subscription: ${response?.statusCode}");
      }
    } catch (e) {
      debugPrint("Error in checkSubscription: $e");
    }
  }

  // Add a method to verify token storage
  void debugTokenStorage() {
    final token = StorageUtil.getString(StringHelper.token);
    final isLoggedIn = StorageUtil.getBool(StringHelper.isLoggedIn);

    debugPrint('🔍 DASHBOARD PROVIDER TOKEN DEBUG:');
    debugPrint('🔍 Token: ${token.isNotEmpty ? "PRESENT (${token.substring(0, 10)}...)" : "MISSING"}');
    debugPrint('🔍 isLoggedIn: $isLoggedIn');
    debugPrint('🔍 Token length: ${token.length}');
  }
}