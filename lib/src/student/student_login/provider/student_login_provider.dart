import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/student/nav_bar/presentations/pages/nav_bar_page.dart';
import 'package:lifelab3/src/student/student_login/model/verify_otp_model.dart';

import '../../../common/helper/color_code.dart';
import '../../../common/helper/string_helper.dart';
import '../../../utils/storage_utils.dart';
import '../../sign_up/presentations/pages/sign_up_page.dart';
import '../services/student_services.dart';

class StudentLoginProvider extends ChangeNotifier {
  TextEditingController contactController = TextEditingController();
  TextEditingController otpController = TextEditingController();

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

  // Start OTP timer for 30 seconds
  void _startOtpTimer() {
    _otpTimerCount = 30; // 30 seconds
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
    contactController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> sendOtp(BuildContext context) async {
    if (!_canResendOtp) {
      Fluttertoast.showToast(msg: "Please wait $formattedTimer before requesting a new OTP.");
      return;
    }

    // Loader.show(
    //   context,
    //   progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor,),
    //   overlayColor: Colors.black54,
    // );

    Map<String, dynamic> map = {
      "type": 3,
      "mobile_no": contactController.text,
    };

    try {
      Response response = await SignUpApiService().sendOtp(map: map);

      // Loader.hide();

      if(response.statusCode == 200) {
        Fluttertoast.showToast(msg: response.data["message"]);
        _startOtpTimer(); // Start timer after successful OTP send
      }
    } catch (e) {
      // Loader.hide();
      // Error handling is done in the service
    }
  }

  Future<void> verifyOtp(BuildContext context) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor,),
      overlayColor: Colors.black54,
    );

    Map<String, dynamic> map = {
      "type": 3,
      "mobile_no": contactController.text,
      "otp": otpController.text,
    };

    try {
      Response? response = await SignUpApiService().verifyOtp(map: map);

      Loader.hide();

      if(response?.statusCode == 200) {
        VerifyOtpModel model = VerifyOtpModel.fromJson(response!.data);
        if(context.mounted) {
          var mo = model.data!.token!;
          debugPrint('🔐 Token received: $mo');

          if(model.data!.token!.isNotEmpty) {
            // Store authentication data
            await StorageUtil.putBool(StringHelper.isLoggedIn, true);
            await StorageUtil.putString(StringHelper.token, model.data!.token!);

            // Verify storage immediately
            final storedToken = StorageUtil.getString(StringHelper.token);
            final isLoggedIn = StorageUtil.getBool(StringHelper.isLoggedIn);

            debugPrint('✅ Token stored successfully: $storedToken');
            debugPrint('✅ Login status: $isLoggedIn');

            if (storedToken.isEmpty) {
              debugPrint('❌ Token storage failed!');
              Fluttertoast.showToast(msg: "Authentication failed. Please try again.");
              return;
            }

            _stopOtpTimer(); // Stop timer after successful verification
            pushRemoveUntil(context: context, page: const NavBarPage(currentIndex: 0));
          } else {
            _stopOtpTimer(); // Stop timer
            push(
              context: context,
              page: const SignUpPage(),
            );
          }
        }
        Fluttertoast.showToast(msg: response.data["message"]);
      }
    } catch (e) {
      Loader.hide();
      debugPrint('❌ OTP Verification Error: $e');
      // Error handling is done in the service
    }
  }
  // Add resend OTP method
  Future<void> resendOtp(BuildContext context) async {
    if (!_canResendOtp) {
      Fluttertoast.showToast(msg: "Please wait $formattedTimer before requesting a new OTP.");
      return;
    }

    await sendOtp(context);
  }
}