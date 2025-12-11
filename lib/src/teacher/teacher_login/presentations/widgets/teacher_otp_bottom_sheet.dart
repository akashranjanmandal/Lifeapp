import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/teacher/teacher_login/presentations/widgets/teacher_otp_widget.dart';
import 'package:lifelab3/src/teacher/teacher_login/provider/teacher_login_provider.dart';
import 'package:provider/provider.dart'; // Add this import

void teacherEnterPinSheet(BuildContext context, TeacherLoginProvider provider) => showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (context) {
    return ChangeNotifierProvider.value( // Wrap with ChangeNotifierProvider
      value: provider,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          height: 320, // Increased height for timer
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Consumer<TeacherLoginProvider>( // Use Consumer to listen to changes
            builder: (context, provider, child) {
              return Column(
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
                  TeacherOtpWidget2(provider: provider),

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
                      TextButton(
                        onPressed: provider.canResendOtp
                            ? () => provider.resendOtp(true) // true for login flow
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  CustomButton(
                    name: StringHelper.submit,
                    height: 45,
                    width: MediaQuery.of(context).size.width,
                    onTap: () {
                      if(provider.otpController.text.length == 4) {
                        provider.verifyOtpLogin(context);
                      } else {
                        Fluttertoast.showToast(msg: StringHelper.invalidData);
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  },
);