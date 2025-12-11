import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/teacher/teacher_login/presentations/widgets/teacher_otp_widget.dart';
import 'package:lifelab3/src/teacher/teacher_login/provider/teacher_login_provider.dart';
import 'package:provider/provider.dart';

void teacherEnterPinSheet2(BuildContext context, TeacherLoginProvider provider) => showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: 320, // Increased height for timer
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              StringHelper.enterTheOtp,
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 20),
            TeacherOtpWidget3(provider: provider),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  StringHelper.termNCondition,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),

                // Updated resend OTP button with timer
                Consumer<TeacherLoginProvider>(
                  builder: (context, provider, child) {
                    return TextButton(
                      onPressed: provider.canResendOtp
                          ? () => provider.resendOtp(false)
                          : null,
                      child: Text(
                        provider.canResendOtp
                            ? StringHelper.resendOtp
                            : "Resend OTP in ${provider.formattedTimer}",
                        style: TextStyle(
                          color: provider.canResendOtp ? Colors.blue : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            CustomButton(
              name: StringHelper.submit,
              height: 45,
              width: MediaQuery.of(context).size.width,
              onTap: () {
                if(provider.otpController2.text.length == 4) {
                  provider.verifyOtp(context);
                } else {
                  Fluttertoast.showToast(msg: StringHelper.invalidData);
                }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  },
);