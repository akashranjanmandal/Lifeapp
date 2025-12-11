import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';

import '../../provider/student_login_provider.dart';
import 'otp_widget.dart';

void enterPinSheet(BuildContext context, StudentLoginProvider provider) => showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (context) {
    return _StudentOtpBottomSheet(provider: provider);
  },
);

class _StudentOtpBottomSheet extends StatefulWidget {
  final StudentLoginProvider provider;

  const _StudentOtpBottomSheet({required this.provider});

  @override
  State<_StudentOtpBottomSheet> createState() => _StudentOtpBottomSheetState();
}

class _StudentOtpBottomSheetState extends State<_StudentOtpBottomSheet> {
  late StudentLoginProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider;
    // Add listener to rebuild when timer changes
    _provider.addListener(_onProviderUpdate);
  }

  void _onProviderUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: 330,
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
            OtpWidget(provider: _provider),

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
                  onPressed: _provider.canResendOtp
                      ? () => _provider.resendOtp(context)
                      : null,
                  child: Text(
                    _provider.canResendOtp
                        ? StringHelper.resendOtp
                        : "Resend OTP in ${_provider.formattedTimer}",
                    style: TextStyle(
                      color: _provider.canResendOtp ? Colors.blue : Colors.grey,
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
                if(_provider.otpController.text.length == 4) {
                  _provider.verifyOtp(context);
                } else {
                  Fluttertoast.showToast(msg: StringHelper.invalidData);
                }
              },
            ),

            const SizedBox(height: 40),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}