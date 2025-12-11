import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/mentor/code/services/mentor_login_service.dart';
import 'package:lifelab3/src/mentor/mentor_home/presentations/pages/mentor_home_page.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';

import '../../../common/helper/color_code.dart';
import '../../../common/helper/string_helper.dart';

class MentorOtpProvider extends ChangeNotifier {
  TextEditingController codeController = TextEditingController();
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

  // Start timer externally (called after successful OTP send)
  void startTimer() {
    _startOtpTimer();
  }

  // Method to resend OTP
  Future<void> resendOtp(BuildContext context, String code) async {
    if (!_canResendOtp) {
      Fluttertoast.showToast(msg: "Please wait $formattedTimer before requesting a new OTP.");
      return;
    }

    try {
      Response? response = await MentorLoginService().sendOtp(code);
      if (response != null && response.statusCode == 200) {
        Fluttertoast.showToast(msg: "OTP sent successfully");
        _startOtpTimer(); // Start timer after successful OTP send
      } else {
        Fluttertoast.showToast(msg: "Failed to send OTP");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error resending OTP");
    }
  }

  Future verifyOtp(BuildContext context, String number) async {
    if(codeController.text.isNotEmpty) {
      Loader.show(
        context,
        progressIndicator: const CircularProgressIndicator(color: ColorCode.buttonColor),
        overlayColor: Colors.black54,
      );

      Map<String, dynamic> data = {
        "type": 4,
        "mobile_no": number,
        "otp": otpController.text,
      };

      try {
        Response? response = await MentorLoginService().confirmOtp(data);

        Loader.hide();

        if(response != null && response.statusCode == 200) {
          StorageUtil.putBool(StringHelper.isMentor, true);
          StorageUtil.putString(StringHelper.token, response.data["data"]["token"]);
          _stopOtpTimer(); // Stop timer after successful verification
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MentorHomePage()),
                  (route) => false
          );
        } else {
          Fluttertoast.showToast(msg: "Try again later");
        }
      } catch (e) {
        Loader.hide();
        Fluttertoast.showToast(msg: "Error verifying OTP");
      }
      notifyListeners();
    } else {
      Fluttertoast.showToast(msg: StringHelper.invalidData);
    }
  }

  // Dispose timer when provider is disposed
  @override
  void dispose() {
    _stopOtpTimer();
    codeController.dispose();
    otpController.dispose();
    super.dispose();
  }
}