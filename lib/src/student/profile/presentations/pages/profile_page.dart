import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/student/home/provider/dashboard_provider.dart';
import 'package:lifelab3/src/student/profile/presentations/widget/gender_sheet.dart';
import 'package:lifelab3/src/student/profile/services/profile_services.dart';
import 'package:lifelab3/src/welcome/presentation/page/welcome_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../common/helper/api_helper.dart';
import '../../../../common/helper/color_code.dart';
import '../../../../common/utils/mixpanel_service.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../../utils/storage_utils.dart';
import '../../../nav_bar/presentations/pages/nav_bar_page.dart';
import '../../provider/profile_provider.dart';
import '../widget/profile_grade_list_widget.dart';
import '../widget/section_list_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  // Animation controllers for shake effect
  late AnimationController _shakeController;
  late Animation<double> _offsetAnimation;
  bool _isNameValid = true;
  String _nameErrorMsg = '';

  // Formatter to allow only English letters and spaces
  final englishNameFormatter = FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]"));

  DateTime? _entryTime;
  late String oldName;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
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

    _entryTime = DateTime.now();
    MixpanelService.track("Profile Page Visited", properties: {
      "timestamp": _entryTime!.toIso8601String(),
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<ProfileProvider>(context, listen: false).getSchoolList();
      Provider.of<ProfileProvider>(context, listen: false).getStateCityList();
      Provider.of<ProfileProvider>(context, listen: false).getSectionList();
      Provider.of<ProfileProvider>(context, listen: false).getGradeList();
      Provider.of<ProfileProvider>(context, listen: false).getStateCityList();

      final user = Provider.of<DashboardProvider>(context, listen: false)
          .dashboardModel!
          .data!
          .user!;

      ProfileProvider cP = Provider.of<ProfileProvider>(context, listen: false);

      cP.schoolNameController.text =
      user.school != null ? user.school!.name! : "";
      cP.gradeController.text = user.grade != null ? user.grade!.name! : "";

      cP.mobileController.text = user.mobileNo ?? "";

      cP.chileNameController.text = user.name ?? "";
      oldName = user.name ?? "";

      cP.parentNameController.text = user.guardianName ?? "";
      cP.sectionController.text =
      user.section == null ? "" : user.section!.name!;

      cP.dobController.text = user.dob == null ? "" : user.dob!.toString();

      cP.gender = user.gender ?? 0;

      if (cP.gender == 0) {
        cP.sexController.text = "Male";
      } else if (cP.gender == 1) {
        cP.sexController.text = "Female";
      } else {
        cP.sexController.text = "Other";
      }

      cP.addressController.text = user.address ?? "";

      cP.stateController.text = user.state ?? "";

      cP.cityController.text = user.city ?? "";
      cP.schoolCodeController.text = user.school!.code.toString();
      cP.hasSchoolCode = (user.school?.code?.toString().isNotEmpty ?? false);
      cP.isEditingSchoolCode = !cP.hasSchoolCode; // allow editing if no code

      setState(() {});
    });
  }
  @override
  void dispose() {
    _shakeController.dispose();
    final duration = DateTime.now().difference(_entryTime!);
    MixpanelService.track("Profile Page Activity Time", properties: {
      "duration_seconds": duration.inSeconds,
    });
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

  _loadPicker(ImageSource source) async {
    XFile? picked =
    await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (picked != null) {
      _cropImage(picked);
    }
  }

  _cropImage(picked) async {
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: ColorCode.buttonColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped != null) {
      Loader.show(
        context,
        progressIndicator: const CircularProgressIndicator(
          color: ColorCode.buttonColor,
        ),
        overlayColor: Colors.black54,
      );

      Response response =
      await ProfileService().uploadProfile(File(cropped.path));

      Loader.hide();

      if (response.statusCode == 200) {
        bool isNew = Provider.of<DashboardProvider>(context, listen: false)
            .dashboardModel!
            .data!
            .user!
            .imagePath == null;

        MixpanelService.track(
            isNew ? "New Profile Photo Added" : "Existing Profile Photo Updated"
        );

        Fluttertoast.showToast(msg: "Profile photo updated");
        await Provider.of<DashboardProvider>(context, listen: false)
            .getDashboardData();
      } else {
        Fluttertoast.showToast(msg: "Try again later");
      }

      setState(() {});
    }
  }

  assetsToLogoFileImg(String imgPath) async {
    var randomNum = Random();
    final byteData = await rootBundle.load(imgPath);
    Directory tempDir = await getTemporaryDirectory();

    final file = File("${tempDir.path}${randomNum.nextInt(1000000)}.png");
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    Response response = await ProfileService().uploadProfile(file);
    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: "Profile photo updated");
      await Provider.of<DashboardProvider>(context, listen: false)
          .getDashboardData();
      setState(() {});
    } else {
      Fluttertoast.showToast(msg: "Something went to wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _profile(),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Column(
                children: [
                  // Child Name with validation
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Name",
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_offsetAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: TextField(
                          controller: provider.chileNameController,
                          inputFormatters: [englishNameFormatter],
                          decoration: InputDecoration(
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
                            provider.chileNameController.selection =
                                TextSelection.fromPosition(
                                    TextPosition(offset: val.length)
                                );
                          },
                        ),
                      ),
                      if (!_isNameValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 8),
                          child: Text(
                            _nameErrorMsg,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Phone number
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Phone number",
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CustomTextField(
                        readOnly: true,
                        color: Colors.white,
                        fieldController: provider.mobileController,
                        hintName: StringHelper.chileName,
                      ),
                    ],
                  ),

                  // Grade
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        StringHelper.grade,
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CustomTextField(
                        readOnly: true,
                        color: Colors.white,
                        fieldController: provider.gradeController,
                        hintName: StringHelper.grade,
                        onTap: () {
                          MixpanelService.track("Grade Field Updated", properties: {
                            "new_value": provider.gradeController.text
                          });
                          profileGradeListBottomSheet(context, provider);
                        },
                      ),
                    ],
                  ),

                  // Section
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Section",
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CustomTextField(
                        readOnly: true,
                        color: Colors.white,
                        fieldController: provider.sectionController,
                        hintName: StringHelper.section,
                        onTap: () {
                          MixpanelService.track("Section Field Updated", properties: {
                            "new_value": provider.sectionController.text
                          });
                          sectionListBottomSheet(context, provider);
                        },
                      ),
                    ],
                  ),

                  // DOB
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DOB",
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CustomTextField(
                        readOnly: true,
                        color: Colors.white,
                        fieldController: provider.dobController,
                        hintName: "DOB",
                        suffix: const Icon(Icons.calendar_month_rounded),
                        onTap: () async {
                          MixpanelService.track("DOB Field Updated", properties: {
                            "new_value": provider.dobController.text
                          });

                          final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: provider.date,
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now());
                          if (picked != null) {
                            provider.date = picked;
                            provider.dobController.text =
                            "${picked.year}-${picked.month}-${picked.day}";
                            provider.notifyListeners();
                          } else {
                            Fluttertoast.showToast(
                                msg: "Please select Date of Birth");
                          }
                        },
                      ),
                    ],
                  ),

                  // Sex
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Gender",
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CustomTextField(
                        readOnly: true,
                        color: Colors.white,
                        fieldController: provider.sexController,
                        hintName: StringHelper.gender,
                        onTap: () {
                          MixpanelService.track("Gender Field Updated", properties: {
                            "new_value": provider.sexController.text
                          });

                          genderBottomSheet(
                              context: context, provider: provider);
                        },
                      ),
                    ],
                  ),
                  // School Code
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "School Code",
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              readOnly: !provider.isEditingSchoolCode,
                              color: Colors.white,
                              fieldController: provider.schoolCodeController,
                              hintName: "Enter school code",
                              onChange: (val) {
                                provider.isSchoolCodeValid = false;
                                provider.notifyListeners();
                              },
                            ),
                          ),
                          if (provider.isEditingSchoolCode && !provider.isSchoolCodeValid)
                            TextButton(
                              onPressed: () {
                                provider.verifySchoolCode(context);
                              },
                              child: const Text(
                                "Verify",
                                style: TextStyle(fontSize: 18, color: Colors.blue),
                              ),
                            ),
                          if (!provider.isEditingSchoolCode)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                provider.isEditingSchoolCode = true;
                                provider.notifyListeners();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),

// School Name (read-only)
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "School Name",
                        style: TextStyle(
                          color: ColorCode.textBlackColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CustomTextField(
                        readOnly: true,
                        color: Colors.white,
                        fieldController: provider.schoolNameController,
                        hintName: "School name",
                      ),
                    ],
                  ),

                  // Submit
                  const SizedBox(height: 40),
                  CustomButton(
                    name: "Update",
                    height: 50,
                    onTap: () async {
                      // Validate name before submission
                      _validateName(provider.chileNameController.text);
                      if (!_isNameValid) {
                        Fluttertoast.showToast(
                          msg: "Please enter a valid English name without symbols or numbers",
                          toastLength: Toast.LENGTH_LONG,
                        );
                        return;
                      }

                      if (provider.chileNameController.text != oldName) {
                        MixpanelService.track("Name Field Updated", properties: {
                          "new_value": provider.chileNameController.text,
                        });
                      }

                      provider.update(context);
                      // After update, refresh and navigate to home page
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const NavBarPage(currentIndex: 0)),
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: Colors.transparent,
    leading: IconButton(
      icon: Image.asset(
        "assets/images/back.png",
        height: 30,
        width: 30,
      ),
      color: Colors.white,
      iconSize: 25,
      onPressed: () {
        MixpanelService.track("Back Icon Clicked from Profile Page");
        Navigator.pop(context);
      },
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 15),
        child: InkWell(
          onTap: () async {
            Loader.show(
              context,
              progressIndicator: const CircularProgressIndicator(
                color: ColorCode.buttonColor,
              ),
              overlayColor: Colors.black54,
            );

            Response response = await ProfileService().logout();

            Loader.hide();

            if (response.statusCode == 200) {
              MixpanelService.track("User Logged Out", properties: {
                "timestamp": DateTime.now().toIso8601String(),
              });
              StorageUtil.clearData();
              Fluttertoast.showToast(msg: "Logout Successfully");
              push(
                context: context,
                page: const WelComePage(),
              );
            } else {
              Fluttertoast.showToast(msg: "Something went to wrong");
            }
          },
          child: Image.asset(
            "assets/images/logout.png",
            height: 25,
            width: 25,
          ),
        ),
      ),
    ],
    elevation: 0,
  );

  Widget _profile() => Container(
    width: MediaQuery.of(context).size.width,
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      color: ColorCode.buttonColor,
    ),
    child: Column(
      children: [
        const SizedBox(height: 90),
        Stack(
          children: [
            Provider.of<DashboardProvider>(context)
                .dashboardModel!
                .data!
                .user!
                .imagePath !=
                null
                ? CircleAvatar(
              radius: 80,
              child: CircleAvatar(
                radius: 80,
                backgroundImage: NetworkImage(ApiHelper.imgBaseUrl +
                    Provider.of<DashboardProvider>(context)
                        .dashboardModel!
                        .data!
                        .user!
                        .imagePath!),
              ),
            )
                : const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 80,
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 78,
                backgroundImage: AssetImage(ImageHelper.profileImg),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: () {
                  MixpanelService.track("Profile Photo Icon Clicked");
                  chooseImageBottomSheet();
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Image.asset(
                  "assets/images/cam.png",
                  height: 45,
                  width: 45,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "Mobile No: ${Provider.of<DashboardProvider>(context, listen: false).dashboardModel!.data!.user!.mobileNo}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              "Ranking: ${Provider.of<DashboardProvider>(context, listen: false).dashboardModel!.data!.user!.userRank}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Coins: ${Provider.of<DashboardProvider>(context, listen: false).dashboardModel!.data!.user!.earnCoins}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    ),
  );

  chooseImageBottomSheet() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding:
      const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 70),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload a photo",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          // Camera
          const SizedBox(height: 30),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              _loadPicker(ImageSource.camera);
            },
            child: Row(
              children: [
                Image.asset(
                  "assets/images/Camera.png",
                  height: 35,
                  width: 35,
                  color: ColorCode.buttonColor,
                ),
                const SizedBox(width: 15),
                const Text(
                  "Take a photo",
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),

          // Gallery
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              _loadPicker(ImageSource.gallery);
            },
            child: Row(
              children: [
                Image.asset(
                  "assets/images/gallery.png",
                  height: 35,
                  width: 35,
                  color: ColorCode.buttonColor,
                ),
                const SizedBox(width: 15),
                const Text(
                  "Choose from Gallery",
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),

          // or choose an avatar
          const SizedBox(height: 20),
          const Text(
            "or choose an avatar",
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Avatar Screen
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white70,
            ),
            child: ListView.builder(
              itemCount: StringHelper.AVTAR_LIST.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => InkWell(
                onTap: () {
                  Navigator.pop(context);
                  assetsToLogoFileImg(StringHelper.AVTAR_LIST[index]);
                },
                child: Container(
                  height: 50,
                  width: 50,
                  margin: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white70,
                  ),
                  child: Image.asset(
                    StringHelper.AVTAR_LIST[index],
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}