import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_profile/provider/teacher_profile_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../common/helper/api_helper.dart';
import '../../../../common/helper/color_code.dart';
import '../../../../common/helper/image_helper.dart';
import '../../../../common/helper/string_helper.dart';
import '../../../../student/profile/services/profile_services.dart';
import '../../../../utils/storage_utils.dart';
import '../../../../welcome/presentation/page/welcome_page.dart';
import '../../../teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import '../widgets/teacher_board_sheet.dart';
import '../widgets/teacher_grade_sheet.dart';
import '../widgets/teacher_section_sheet.dart';
import '../widgets/teacher_subject_sheet.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late TeacherProfileProvider _profileProvider;
  Future<void> _loadPicker(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (picked != null) {
        await _cropImage(picked);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to pick image: $e");
    }
  }
  Widget _buildTextLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: ColorCode.textBlackColor,
          fontSize: 18,
        ),
      ),
    );
  }

  Future<void> _cropImage(XFile picked) async {
    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
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
        await _uploadProfileImage(File(cropped.path));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to crop image: $e");
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(
        color: ColorCode.buttonColor,
      ),
      overlayColor: Colors.black54,
    );

    try {
      Response response = await ProfileService().uploadProfile(imageFile);
      Loader.hide();

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Profile photo updated");
        MixpanelService.track("Profile photo updated", properties: {
          "timestamp": DateTime.now().toIso8601String(),
        });
        await Provider.of<TeacherDashboardProvider>(context, listen: false)
            .getDashboardData();
        setState(() {});
      } else {
        Fluttertoast.showToast(msg: "Failed to update profile photo");
      }
    } catch (e) {
      Loader.hide();
      Fluttertoast.showToast(msg: "Error uploading image: $e");
    }
  }

  Future<void> assetsToLogoFileImg(String imgPath) async {
    try {
      Loader.show(
        context,
        progressIndicator: const CircularProgressIndicator(
          color: ColorCode.buttonColor,
        ),
        overlayColor: Colors.black54,
      );

      final byteData = await rootBundle.load(imgPath);
      final tempDir = await getTemporaryDirectory();
      final file = File("${tempDir.path}${Random().nextInt(1000000)}.png");
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      final Response response = await ProfileService().uploadProfile(file);
      Loader.hide();

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Profile photo updated");
        await Provider.of<TeacherDashboardProvider>(context, listen: false)
            .getDashboardData();
        setState(() {});
      } else {
        Fluttertoast.showToast(msg: "Failed to update profile photo");
      }
    } catch (e) {
      Loader.hide();
      Fluttertoast.showToast(msg: "Error using avatar: $e");
    }
  }
  DateTime? _startTime;
  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final provider = Provider.of<TeacherProfileProvider>(context, listen: false);
      final user = Provider.of<TeacherDashboardProvider>(context, listen: false)
          .dashboardModel!
          .data!
          .user!;

      debugPrint("User ID: ${user.id}");
      debugPrint("School Name from API: ${user.school?.name}");

      // Fetch leaderboard data first
      await provider.fetchLeaderboardData(user.id!, user.school?.name ?? "");

      // Now load the rest of the data
      provider.getSchoolList();
      provider.getStateCityList();
      provider.getSectionList();
      provider.getBoardList().then((_) {
        if (user.la_board_id?.isNotEmpty == true && user.board_name?.isNotEmpty == true) {
          provider.setInitialBoard(user.la_board_id, user.board_name);
        }
      });
      provider.getSubjectList();

      provider.schoolNameController.text = user.school?.name ?? "";
      provider.teacherNameController.text = user.name ?? "";
      provider.sectionController.text = user.section?.name ?? "";
      provider.sectionId = user.section?.id;
      provider.dobController.text = user.dob ?? "";
      provider.gradeController.text = user.grade?.name.toString() ?? "";
      provider.stateController.text = user.state ?? "";
      provider.cityController.text = user.city ?? "";
      provider.schoolCodeController.text = user.school?.code?.toString() ?? "";

      provider.setInitialDOB(user.dob);
      provider.gradeMapList.clear(); // Prevent duplicates

      if (user.laTeacherGrades != null && user.laTeacherGrades!.isNotEmpty) {
        for (var element in user.laTeacherGrades!) {
          provider.gradeMapList.add({
            "la_grade_id": element.grade?.id?.toString() ?? "",
            "la_section_id": element.section?.id?.toString() ?? "",
            "la_section_name": element.section?.name ?? "",
            "subjects": element.subject?.id?.toString() ?? "",
            "subject_name": element.subject?.title ?? ""
          });
        }
      } else {
        provider.initializeGradeMapList();
      }

      provider.gradeList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

      // Force a rebuild after all data is loaded
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }
  @override
  void dispose() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      MixpanelService.track("Profile information screen activity time", properties: {
        "duration_seconds": duration,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    _scrollController.dispose();
    super.dispose();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileProvider = Provider.of<TeacherProfileProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = Provider.of<TeacherProfileProvider>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _appBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _profile(), // Your existing profile header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // 👤 Edit label
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF0FF), Color(0xFFDDE5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF5C6BFF).withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C6BFF).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFF5C6BFF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Wrap title and subtitle in a Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "Edit your data",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Color(0xFF3C4FE0),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Modify your profile and subject details",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5C6BFF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === Teacher Name ===
                  _buildTextLabel("Teacher Name"),
                  CustomTextField(
                    readOnly: false,
                    fieldController: provider.teacherNameController,
                    hintName: "Enter Teacher Name",
                    suffix: const Icon(Icons.person_outline),
                    onChange: (val) {
                      if (val.trim().isNotEmpty) {
                        MixpanelService.track("Teacher name field edited", properties: {
                          "teacher_name": val.trim(),
                          "timestamp": DateTime.now().toIso8601String(),
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  // === School Code ===
                  _buildTextLabel("School Code"),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          readOnly: false,
                          fieldController: provider.schoolCodeController,
                          hintName: "Enter School Code",
                          suffix: const Icon(Icons.school_outlined),
                          onChange: (val) {
                            MixpanelService.track("School code column updated in profile information form", properties: {
                              "school_code": val.trim(),
                              "timestamp": DateTime.now().toIso8601String(),
                            });
                            provider.updateSchoolCode(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!provider.isSchoolCodeValid)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3E1E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onPressed: () async {
                            final code = provider.schoolCodeController.text.trim();

                            if (code.isEmpty) {
                              Fluttertoast.showToast(msg: "Please enter a school code");
                              return; // Don't proceed
                            }

                            Loader.show(
                              context,
                              progressIndicator: const CircularProgressIndicator(
                                color: ColorCode.buttonColor,
                              ),
                              overlayColor: Colors.black54,
                            );

                            try {
                              await provider.verifySchoolCode(context);
                              Loader.hide();

                              if (provider.isSchoolCodeValid) {
                                MixpanelService.track("School code verified", properties: {
                                  "school_code": code,
                                  "timestamp": DateTime.now().toIso8601String(),
                                });
                              }
                            } catch (e) {
                              Loader.hide();
                              Fluttertoast.showToast(msg: "Error verifying school code: $e");
                            }
                          },


                          icon: const Icon(Icons.verified_outlined, size: 18),
                          label: const Text(
                            "Verify",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // === School Info
                  if (provider.isSchoolCodeValid)
                    _buildTextLabel("School Address"),
                    CustomTextField(
                      readOnly: true,
                      fieldController: TextEditingController(
                        text: "${provider.schoolNameController.text}, ${provider.stateController.text}, ${provider.cityController.text}",
                      ),
                      hintName: "School Address",
                      suffix: const Icon(Icons.location_on_outlined),
                      onChange: (val) {
                        // Optionally handle changes if you want editable
                      },
                    ),
                  if (provider.isSchoolCodeValid) const SizedBox(height: 28),

// === Add Grade Section Button ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          MixpanelService.track("Add new class button clicked", properties: {
                            "current_class_count": provider.gradeMapList.length,
                            "timestamp": DateTime.now().toIso8601String(),
                          });
                          setState(() {
                            provider.gradeMapList.insert(0, {
                              "la_grade_id": "",
                              "la_section_id": "",
                              "subjects": "",
                              "la_section_name": "",
                              "subject_name": ""
                            });
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              final offset = _scrollController.offset;
                              _scrollController.jumpTo(offset + 150); // or animateTo if smoother effect desired
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5C6BFF), Color(0xFF906EFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                "Add New Class",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

// === Dynamic Grade-Section-Subject Fields ===
                  ...provider.gradeMapList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 15),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextLabel("Grade"),
                                    const SizedBox(height: 6),
                                    CustomTextField(
                                      readOnly: true,
                                      fieldController: TextEditingController(text: e["la_grade_id"]),
                                      hintName: "Select Grade",
                                      suffix: const Icon(Icons.grade_outlined),
                                      onTap: () {
                                        MixpanelService.track("Grade selected", properties: {
                                          "grade_id": e["la_grade_id"] ?? "",
                                          "timestamp": DateTime.now().toIso8601String(),
                                        });
                                        teacherProfileGradeListBottomSheet(context, provider, e);
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    _buildTextLabel("Section"),
                                    const SizedBox(height: 6),
                                    CustomTextField(
                                      readOnly: true,
                                      fieldController: TextEditingController(text: e["la_section_name"]),
                                      hintName: "Select Section",
                                      suffix: const Icon(Icons.view_agenda_outlined),
                                      onTap: () {
                                        MixpanelService.track("Section selected", properties: {
                                          "grade_id": e["la_grade_id"] ?? "",
                                          "section_id": e["la_section_id"] ?? "",
                                          "section_name": e["la_section_name"] ?? "",
                                          "timestamp": DateTime.now().toIso8601String(),
                                        });
                                        teacherProfileSectionListBottomSheet(context, provider, e);
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    _buildTextLabel("Subject"),
                                    const SizedBox(height: 6),
                                    CustomTextField(
                                      readOnly: true,
                                      fieldController: TextEditingController(text: e["subject_name"]),
                                      hintName: "Select Subject",
                                      suffix: const Icon(Icons.book_outlined),
                                      onTap: () {
                                        MixpanelService.track("Subject selected", properties: {
                                          "grade_id": e["la_grade_id"] ?? "",
                                          "section_id": e["la_section_id"] ?? "",
                                          "section_name": e["la_section_name"] ?? "",
                                          "subject_id": e["subjects"] ?? "",
                                          "subject_name": e["subject_name"] ?? "",
                                          "timestamp": DateTime.now().toIso8601String(),
                                        });
                                        teacherSubjectListBottomSheet(context, provider, e);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Delete Button
                        if (provider.gradeMapList.length > 1)
                          Positioned(
                            right: 10,
                            top: 25,
                            child: GestureDetector(
                              onTap: () => setState(() => provider.gradeMapList.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete, color: Colors.red, size: 25),
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 28),

                  // === Board ===
                  _buildTextLabel("Board"),
                  CustomTextField(
                    readOnly: true,
                    fieldController: provider.boardNameController,
                    hintName: "Select Board",
                    suffix: const Icon(Icons.apartment_outlined),
                    onTap: () {
                      MixpanelService.track("Board selected", properties: {
                        "board_name": provider.boardNameController.text,
                        "timestamp": DateTime.now().toIso8601String(),
                      });
                      teacherBoardListBottomSheet(context, provider);
                    },
                  ),
                  const SizedBox(height: 28),
                  // === DOB ===
                  _buildTextLabel("DOB"),
                  CustomTextField(
                    readOnly: true,
                    fieldController: provider.dobController,
                    hintName: "Select DOB",
                    suffix: const Icon(Icons.calendar_month_rounded, color: Colors.grey),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: provider.dobController.text.isNotEmpty
                            ? DateTime.parse(provider.dobController.text)
                            : provider.date,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        MixpanelService.track("DOB column updated in profile information form", properties: {
                          "dob": picked.toIso8601String(),
                          "timestamp": DateTime.now().toIso8601String(),
                        });
                        provider.updateDOB(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 48),
                  // === Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5C6BFF), Color(0xFF936DFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                      onPressed: () {
    MixpanelService.track("Profile form submitted", properties: {
    "teacher_name": provider.teacherNameController.text,
    "school_code": provider.schoolCodeController.text,
    "board_name": provider.boardNameController.text,
    "dob": provider.dobController.text,
    "grades_count": provider.gradeMapList.length,
    "timestamp": DateTime.now().toIso8601String(),
    });
    provider.updateTeacher(
    context,
    Provider.of<TeacherDashboardProvider>(context, listen: false)
        .dashboardModel!
        .data!
        .user!
        .mobileNo!,
    );
    Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => TeacherDashboardPage()),
    (route) => false,
    );
    }     ,icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text(
                          StringHelper.submit,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _profile() {
    final user = Provider.of<TeacherDashboardProvider>(context).dashboardModel!.data!.user!;

    return Consumer<TeacherProfileProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF957DFF),
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  user.imagePath != null
                      ? CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(ApiHelper.imgBaseUrl + user.imagePath!),
                  )
                      : const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(ImageHelper.profileImg),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        MixpanelService.track("Profile photo icon clicked", properties: {
                          "timestamp": DateTime.now().toIso8601String(),
                        });
                        chooseImageBottomSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/cam.png",
                          height: 30,
                          width: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                user.name ?? "Teacher Name",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                "Mobile: ${user.mobileNo ?? "N/A"}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "School Code: ${user.school?.id ?? "N/A"}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoRow(
                      "Teacher Rank",
                      provider.teacherRankEntry?.rank != null && provider.teacherRankEntry!.rank > 0
                          ? "#${provider.teacherRankEntry!.rank}"
                          : "Not Ranked",
                    ),
                    const Divider(height: 25),
                    _infoRow(
                      "School Rank",
                      provider.schoolRankEntry?.rank != null && provider.schoolRankEntry!.rank > 0
                          ? "#${provider.schoolRankEntry!.rank}"
                          : "Not Ranked",
                    ),
                    const Divider(height: 25),
                    _infoRow(
                        "Teacher Level",
                        Provider.of<TeacherDashboardProvider>(context)
                            .dashboardModel?.data?.user?.engagementBadge ?? "No badge"
                    ),
                    const Divider(height: 25),
                    // School Name with better handling for long names
                    _infoRow("School Name", user.school?.name ?? "N/A"),
                    const Divider(height: 25),
                    _infoRow(
                        "Board",
                        provider.boardNameController.text.isNotEmpty
                            ? provider.boardNameController.text
                            : user.board_name ?? "N/A"
                    ),
                    const Divider(height: 25),
                    _infoRow(
                        "DOB",
                        provider.dobController.text.isNotEmpty
                            ? provider.dobController.text
                            : user.dob ?? "N/A"
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _infoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2, // Allow school name to wrap
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorCode.buttonColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
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
      onPressed: () {
        MixpanelService.track("Back icon from profile information page clicked to go back", properties: {
          "timestamp": DateTime.now().toIso8601String(),
        });
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
            try {
              Response response = await ProfileService().logout();
              Loader.hide();
              if (response.statusCode == 200) {
                StorageUtil.clearData();
                Fluttertoast.showToast(msg: "Logout Successfully");
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelComePage()),
                      (route) => false,
                );
              }
            } catch (e) {
              Loader.hide();
              Fluttertoast.showToast(msg: "Logout failed: $e");
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
          const SizedBox(height: 20),
          const Text(
            "or choose an avatar",
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
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
class CustomTextField extends StatelessWidget {
  final TextEditingController fieldController;
  final String hintName;
  final bool readOnly;
  final Widget? suffix;
  final Function(String)? onChange;
  final VoidCallback? onTap;

  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomTextField({
    super.key,
    required this.fieldController,
    required this.hintName,
    this.readOnly = false,
    this.suffix,
    this.onChange,
    this.onTap,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: fieldController,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChange,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintName,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 10),
            suffix!,
          ]
        ],
      ),
    );
  }
}
