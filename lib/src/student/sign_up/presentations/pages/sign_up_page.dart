import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/custom_text_field.dart';
import 'package:lifelab3/src/student/profile/presentations/widget/gender_sheet.dart';
import 'package:lifelab3/src/student/sign_up/presentations/widgets/section_list_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/utils/mixpanel_service.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../provider/sign_up_provider.dart';
import '../widgets/grade_list_widget.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  late TextEditingController _childNameController;
  late AnimationController _shakeController;
  late Animation<double> _offsetAnimation;

  bool _isNameValid = true;
  String _nameErrorMsg = '';

  final englishNameFormatter = FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]"));

  @override
  void initState() {
    super.initState();

    _childNameController = TextEditingController();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(_shakeController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SignUpProvider>(context, listen: false);
      provider.getSchoolList();
      provider.getStateCityList();
      provider.getSectionList();
      provider.getGradeList();

      // Link our controller to provider controller so it stays in sync
      provider.chileNameController = _childNameController;
    });
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _validateName(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isNameValid = false;
        _nameErrorMsg = 'Name cannot be empty';
      });
      _shakeController.forward(from: 0);
      return;
    }

    final valid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed);
    if (!valid) {
      setState(() {
        _isNameValid = false;
        _nameErrorMsg = 'Only English letters and spaces allowed';
      });
      _shakeController.forward(from: 0);
    } else {
      setState(() {
        _isNameValid = true;
        _nameErrorMsg = '';
      });
    }
  }

  void _onSubmit(SignUpProvider provider) {
    if (!_isNameValid || _childNameController.text.trim().isEmpty) {
      _shakeController.forward(from: 0);
      Fluttertoast.showToast(
        msg: "Please enter a valid English name without symbols or numbers",
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    // Track submit event with Mixpanel
    MixpanelService.track("Signup Button Clicked", properties: {
      "child_name": _childNameController.text.trim(),
      "gender": provider.sexController.text,
      "dob": provider.dobController.text,
      "grade": provider.gradeController.text,
      "section": provider.sectionController.text,
      "school_code": provider.schoolCodeController.text,
      "school_name": provider.schoolNameController.text,
      "state": provider.stateController.text,
      "city": provider.cityController.text,
      "timestamp": DateTime.now().toIso8601String(),
    });

    provider.registerStudent(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SignUpProvider>(context);

    return ChangeNotifierProvider.value(
      value: provider,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(ImageHelper.gappuBoboImg1),

              const SizedBox(height: 20),
              const Text(
                "Student Registration",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // Child Name with Shake animation and icons
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_offsetAnimation.value, 0),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: _childNameController,
                    inputFormatters: [englishNameFormatter],
                    decoration: InputDecoration(
                      hintText: StringHelper.chileName,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _isNameValid ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _isNameValid ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      suffixIcon: Icon(
                        _isNameValid ? Icons.check_circle : Icons.error,
                        color: _isNameValid ? Colors.green : Colors.red,
                      ),
                    ),
                    onChanged: (val) {
                      _validateName(val);
                      provider.chileNameController.text = val;
                      provider.chileNameController.selection = TextSelection.fromPosition(TextPosition(offset: val.length));
                    },
                  ),
                ),
              ),

              if (!_isNameValid)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 24),
                  child: Text(
                    _nameErrorMsg,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

              // Grade
              const SizedBox(height: 20),
              CustomTextField(
                readOnly: true,
                color: Colors.white,
                fieldController: provider.gradeController,
                margin: const EdgeInsets.only(left: 15, right: 15),
                hintName: StringHelper.grade,
                onTap: () {
                  gradeListBottomSheet(context, provider);
                },
              ),

              // Section
              const SizedBox(height: 20),
              CustomTextField(
                readOnly: true,
                color: Colors.white,
                fieldController: provider.sectionController,
                margin: const EdgeInsets.only(left: 15, right: 15),
                hintName: StringHelper.section,
                onTap: () {
                  sectionListBottomSheet(context, provider);
                },
              ),

              // Sex
              const SizedBox(height: 20),
              CustomTextField(
                readOnly: true,
                color: Colors.white,
                fieldController: provider.sexController,
                margin: const EdgeInsets.only(left: 15, right: 15),
                hintName: StringHelper.gender,
                onTap: () {
                  genderBottomSheet(context: context, provider: provider);
                },
              ),

              // DOB
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  CustomTextField(
                    readOnly: true,
                    color: Colors.white,
                    fieldController: provider.dobController,
                    margin: const EdgeInsets.only(left: 15, right: 15),
                    hintName: "DOB",
                    suffix: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: provider.date,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        provider.date = picked;
                        provider.dobController.text = "${picked.year}-${picked.month}-${picked.day}";
                        provider.notifyListeners();
                      } else {
                        Fluttertoast.showToast(msg: "Please select a Date of Birth");
                      }
                    },
                  ),
                ],
              ),

              // School Code + Verify
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      readOnly: false,
                      color: Colors.white,
                      fieldController: provider.schoolCodeController,
                      margin: const EdgeInsets.only(left: 15, right: 15),
                      hintName: "Enter school code",
                      onChange: (val) {
                        provider.isSchoolCodeValid = false;
                        provider.notifyListeners();
                      },
                    ),
                  ),
                  if (!provider.isSchoolCodeValid)
                    TextButton(
                      onPressed: () {
                        provider.verifySchoolCode(context);
                      },
                      child: const Text(
                        "verify",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),

              // Show school name + state + city if valid
              const SizedBox(height: 20),
              if (provider.isSchoolCodeValid)
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: RichText(
                    text: TextSpan(
                      text: provider.schoolNameController.text,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: " ,${provider.stateController.text}, ${provider.cityController.text}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Submit Button
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: CustomButton(
                  name: StringHelper.submit,
                  height: 50,
                  onTap: () => _onSubmit(provider),
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: TextButton(
                  onPressed: () {
                    launchUrl(Uri.parse(
                        "https://wa.me/918793626696text=Hello there,\nI have a question.\n\n"));
                  },
                  child: const Text(
                    "Facing a challenge? Message us!",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    StringHelper.aLifeLabProduct,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
