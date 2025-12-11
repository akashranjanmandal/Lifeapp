import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/teacher/teacher_login/services/teacher_login_services.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/presentations/pages/teacher_sign_up_page.dart';

import '../../../common/helper/color_code.dart';
import '../../../common/helper/string_helper.dart';
import '../../../common/widgets/common_navigator.dart';
import '../../../student/student_login/model/verify_otp_model.dart';
import '../../../student/student_login/services/student_services.dart';
import '../../../utils/storage_utils.dart';
import '../../teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';

class TeacherLoginProvider extends ChangeNotifier {
  TextEditingController codeController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController otpController2 = TextEditingController();
  TextEditingController contactController = TextEditingController();

  // OTP Timer variables
  Timer? _otpTimer;
  int _otpTimerCount = 0;
  bool _canResendOtp = true;

  // Getters for UI
  int get otpTimerCount => _otpTimerCount;
  bool get canResendOtp => _canResendOtp;
  String get formattedTimer {
    int minutes = _otpTimerCount ~/ 60;
    int seconds = _otpTimerCount % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Start OTP timer for 25 seconds
  void _startOtpTimer() {
    _otpTimerCount = 25; // 25 seconds
    _canResendOtp = false;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpTimerCount > 0) {
        _otpTimerCount--;
        notifyListeners();
      } else {
        _stopOtpTimer();
        _canResendOtp = true;
        notifyListeners();
      }
    });
  }

  // Stop OTP timer
  void _stopOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = null;
  }

  // Reset OTP timer (call this when resending OTP)
  void resetOtpTimer() {
    _stopOtpTimer();
    _otpTimerCount = 0;
    _canResendOtp = true;
    notifyListeners();
  }

  // Dispose timer when provider is disposed
  @override
  void dispose() {
    _stopOtpTimer();
    super.dispose();
  }

  Future<void> sendOtp() async {
    if (!_canResendOtp) {
      Fluttertoast.showToast(msg: "Please wait $formattedTimer before requesting a new OTP.");
      return;
    }

    Map<String, dynamic> map = {
      "type": 5,
      "mobile_no": contactController.text,
    };

    try {
      Response response = await SignUpApiService().sendOtp(map: map);

      if(response.statusCode == 200) {
        Fluttertoast.showToast(msg: response.data["message"]);
        _startOtpTimer(); // Start timer after successful OTP send
      }
    } catch (e) {
      // Error handling is done in the service
    }
  }

  Future<void> sendOtpLogin() async {
    if (!_canResendOtp) {
      Fluttertoast.showToast(msg: "Please wait $formattedTimer before requesting a new OTP.");
      return;
    }

    Map<String, dynamic> map = {
      "type": 5,
      "mobile_no": contactController.text,
    };

    try {
      Response response = await TeacherLoginServices().sendOtp(map);

      if(response.statusCode == 200) {
        contactController.text = response.data["data"]["mobile_no"];
        Fluttertoast.showToast(msg: response.data["message"]);
        _startOtpTimer(); // Start timer after successful OTP send
        notifyListeners();
      }
    } catch (e) {
      // Error handling is done in the service
    }
  }

  // Add resend OTP method
  Future<void> resendOtp(bool isLogin) async {
    if (!_canResendOtp) {
      Fluttertoast.showToast(msg: "Please wait $formattedTimer before requesting a new OTP.");
      return;
    }

    if (isLogin) {
      await sendOtpLogin();
    } else {
      await sendOtp();
    }
  }

  Future<void> verifyOtp(BuildContext context) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor,),
      overlayColor: Colors.black54,
    );

    Map<String, dynamic> map = {
      "type": 5,
      "mobile_no": contactController.text,
      "otp": otpController2.text,
    };

    try {
      Response? response = await SignUpApiService().verifyOtp(map: map);

      Loader.hide();

      if(response?.statusCode == 200) {
        VerifyOtpModel model = VerifyOtpModel.fromJson(response!.data);
        if(context.mounted) {
          push(
            context: context,
            page: TeacherSignUpPage(contact: contactController.text,),
          );
        }
        Fluttertoast.showToast(msg: response.data["message"]);
        _stopOtpTimer(); // Stop timer after successful verification
      }
    } catch (e) {
      Loader.hide();
      // Error handling is done in the service
    }
  }

  Future<void> verifyOtpLogin(BuildContext context) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor,),
      overlayColor: Colors.black54,
    );

    Map<String, dynamic> map = {
      "type": 5,
      "mobile_no": contactController.text,
      "otp": otpController.text,
    };

    try {
      Response? response = await SignUpApiService().verifyOtp(map: map);

      Loader.hide();

      if(response?.statusCode == 200) {
        VerifyOtpModel model = VerifyOtpModel.fromJson(response!.data);
        if(context.mounted) {
          if(model.data!.token!.isNotEmpty) {
            StorageUtil.putBool(StringHelper.isTeacher, true);
            StorageUtil.putString(StringHelper.token, model.data!.token!);

            // Log the token immediately
            final storedToken = StorageUtil.getString(StringHelper.token);
            print("🔐 Stored Auth Token: $storedToken");

            pushRemoveUntil(context: context, page: const TeacherDashboardPage());
          } else {
            pushRemoveUntil(context: context, page: TeacherSignUpPage(contact: contactController.text));
          }
        }
        Fluttertoast.showToast(msg: response.data["message"]);
        _stopOtpTimer(); // Stop timer after successful verification
      }
    } catch (e) {
      Loader.hide();
      // Error handling is done in the service
    }
  }
}