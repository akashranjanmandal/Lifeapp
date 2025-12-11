import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/mentor/code/provider/mentor_code_provider.dart';
import 'package:provider/provider.dart';
import 'mentor_otp_widget.dart';

void mentorEnterPinSheet(BuildContext context, MentorOtpProvider provider, String number) => showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          height: 330, // Increased height for timer
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Consumer<MentorOtpProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter OTP sent to your number",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 20),
                  MentorOtpWidget2(provider: provider),

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

                      // Timer-enabled resend button
                      TextButton(
                        onPressed: provider.canResendOtp
                            ? () => provider.resendOtp(context, provider.codeController.text)
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
                        provider.verifyOtp(context, number);
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