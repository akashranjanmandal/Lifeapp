  import 'package:dio/dio.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
  import 'package:fluttertoast/fluttertoast.dart';
  import '../../../common/helper/color_code.dart';
  import '../../../common/helper/string_helper.dart';
  import '../../../student/home/models/subject_model.dart';
  import '../../../student/home/services/dashboard_services.dart';
  import '../../../student/profile/services/profile_services.dart';
  import '../../../student/sign_up/model/school_list_model.dart';
  import '../../../student/sign_up/model/section_model.dart';
  import '../../../student/sign_up/model/state_city_model.dart';
  import '../../../student/sign_up/model/verify_school_model.dart';
  import '../../../student/sign_up/services/sign_up_services.dart';
  import '../../../utils/storage_utils.dart';
  import '../../leaderboard/model/model.dart';
  import '../../leaderboard/services/services.dart';
  import '../../teacher_sign_up/model/board_model.dart';
  import '../../teacher_sign_up/services/teacher_sign_up_services.dart';
  import '../../teacher_dashboard/provider/teacher_dashboard_provider.dart';
  import 'package:provider/provider.dart';

  class TeacherProfileProvider extends ChangeNotifier {
    SchoolListModel? schoolListModel;
    SectionModel? sectionModel;
    BoardModel? boardModel;
    SubjectModel? subjectModel;
    VerifySchoolModel? verifySchoolModel;
    LeaderboardEntry? teacherRankEntry;
    LeaderboardEntry? schoolRankEntry;


    List<StateCityListModel> listOfLocation = [];
    List<StateCityListModel> searchListOfLocation = [];
    List<City> cityList = [];
    List<City> searchCityList = [];
    List<Map<String, dynamic>> gradeMapList = [];

    TextEditingController teacherNameController = TextEditingController();
    TextEditingController schoolNameController = TextEditingController();
    TextEditingController boardNameController = TextEditingController();
    TextEditingController subjectController = TextEditingController();
    TextEditingController sectionController = TextEditingController();
    TextEditingController gradeController = TextEditingController();
    TextEditingController stateController = TextEditingController();
    TextEditingController cityController = TextEditingController();
    TextEditingController stateSearchCont = TextEditingController();
    TextEditingController citySearchCont = TextEditingController();
    TextEditingController dobController = TextEditingController();
    TextEditingController schoolCodeController = TextEditingController();

    List<int> gradeList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    List<int> subjectIdList = [];
    Future<void> fetchLeaderboardData(int teacherId, String schoolName) async {
      try {
        final token = await StorageUtil.getString(StringHelper.token);
        final leaderboardService = LeaderboardService(token);

        final teacherList = await leaderboardService.fetchTeacherLeaderboard();
        final schoolList = await leaderboardService.fetchSchoolLeaderboard();


        // More flexible school name matching
        final normalizedSchoolName = schoolName.trim().toLowerCase();

        // Find teacher rank
        teacherRankEntry = teacherList.firstWhere(
              (entry) => entry.teacherId == teacherId,
          orElse: () => LeaderboardEntry(
            rank: 0,
            teacherId: teacherId,
            name: '',
            schoolName: '',
            totalEarnedCoins: 0,
          ),
        );

        // Find school rank with more flexible matching
        schoolRankEntry = schoolList.firstWhere(
              (entry) {
            final entryName = entry.name?.trim().toLowerCase() ?? '';
            return entryName.contains(normalizedSchoolName) ||
                normalizedSchoolName.contains(entryName);
          },
          orElse: () => LeaderboardEntry(
            rank: 0,
            teacherId: null,
            name: schoolName,
            schoolName: '',
            totalEarnedCoins: 0,
          ),
        );

        debugPrint("Teacher Rank: ${teacherRankEntry?.rank}");
        debugPrint("School Rank: ${schoolRankEntry?.rank}");

        safeNotifyListeners();
      } catch (e) {
        debugPrint("Error fetching leaderboard data: $e");
        // Set default values on error
        teacherRankEntry = LeaderboardEntry(
          rank: 0,
          teacherId: teacherId,
          name: '',
          schoolName: '',
          totalEarnedCoins: 0,
        );
        schoolRankEntry = LeaderboardEntry(
          rank: 0,
          teacherId: null,
          name: schoolName,
          schoolName: '',
          totalEarnedCoins: 0,
        );
        safeNotifyListeners();
      }
    }

    void updateSchoolCode(String val) {
      isSchoolCodeValid = false;
      schoolCodeController.text = val;
      safeNotifyListeners();
    }

    int? boardId;
    String? boardName;

    int gender = 0;

    int? sectionId;

    bool isSchoolCodeValid = true;

    DateTime date = DateTime.now();

    bool _isInitialized = false;
    bool _isDisposed = false;

    @override
    void dispose() {
      _isDisposed = true;
      teacherNameController.dispose();
      schoolNameController.dispose();
      boardNameController.dispose();
      subjectController.dispose();
      sectionController.dispose();
      gradeController.dispose();
      stateController.dispose();
      cityController.dispose();
      stateSearchCont.dispose();
      citySearchCont.dispose();
      dobController.dispose();
      schoolCodeController.dispose();
      super.dispose();
    }

    void safeNotifyListeners() {
      if (!_isDisposed) {
        notifyListeners();
      }
    }

    Future<void> getSchoolList() async {
      Response? response = await TeacherSignUpServices().getSchoolList();

      if (response?.statusCode == 200) {
        schoolListModel = SchoolListModel.fromJson(response!.data);
        safeNotifyListeners();
      }
    }

    Future<void> getSectionList() async {
      Response response = await SignUpServices().getSectionList();

      if (response.statusCode == 200) {
        sectionModel = SectionModel.fromJson(response.data);
        safeNotifyListeners();
      }
    }
    Future<void> getBoardList() async {
      Response response = await TeacherSignUpServices().getBoard();
      if (response.statusCode == 200) {
        boardModel = BoardModel.fromJson(response.data);

        // Only set initial board if NO board is currently set
        if ((boardId == null || boardName == null) &&
            boardModel?.data?.boards != null &&
            boardModel!.data!.boards!.isNotEmpty) {
          final firstBoard = boardModel!.data!.boards!.first;
          setInitialBoard(firstBoard.id.toString(), firstBoard.name);
        }

        safeNotifyListeners();
      }
    }

    Future<void> getSubjectList() async {
      Response response = await DashboardServices().getSubjectData();

      if (response.statusCode == 200) {
        subjectModel = SubjectModel.fromJson(response.data);
        safeNotifyListeners();
      }
    }

    Future<void> getStateCityList() async {
      Response? response = await TeacherSignUpServices().getStateList();

      if (response?.statusCode == 200) {
        for (var i in response!.data) {
          StateCityListModel data = StateCityListModel.fromJson(i);
          if (data.active! == 1) {
            listOfLocation.add(data);
            searchListOfLocation.add(data);
          }
        }

        int index = listOfLocation.indexWhere((element) =>
        element.stateName!.toLowerCase() ==
            stateController.text.toLowerCase());
        if (index > 0) getCityData(index);
        safeNotifyListeners();
      }
    }

    void getCityData(int index) {
      cityList = listOfLocation[index].cities!;
      searchCityList = listOfLocation[index].cities!;
      safeNotifyListeners();
    }

    void resetState() {
      _isInitialized = false;
      gradeMapList.clear();
      safeNotifyListeners();
    }

    void initializeGradeMapList() {
      if (!_isInitialized) {
        gradeMapList.clear();
        gradeMapList.add({
          "la_grade_id": "",
          "la_section_id": "",
          "subjects": "",
          "la_section_name": "",
          "subject_name": ""
        });
        _isInitialized = true;
        safeNotifyListeners();
      }
    }

    bool isGradeEntryValid(Map<String, dynamic> grade) {
      return grade["la_grade_id"].toString().isNotEmpty &&
          grade["la_section_id"].toString().isNotEmpty &&
          grade["subjects"].toString().isNotEmpty;
    }

    void syncBoardWithDashboard(BuildContext context) {
      if (boardId != null && boardName != null) {
        final dashboardProvider =
        Provider.of<TeacherDashboardProvider>(context, listen: false);
        dashboardProvider.setSelectedBoard(boardId!, boardName!);
      }
    }

    void updateTeacher(BuildContext context, String contact) async {
      try {
        bool hasValidData = gradeMapList.any((grade) =>
        grade["la_grade_id"].toString().isNotEmpty &&
            grade["la_section_id"].toString().isNotEmpty &&
            grade["subjects"].toString().isNotEmpty);

        if (!hasValidData) {
          Fluttertoast.showToast(
              msg: "Please add at least one grade with section and subject",
              backgroundColor: Colors.red,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG);
          return;
        }

        String formattedDob = dobController.text.trim();
        if (formattedDob.isEmpty) {
          Fluttertoast.showToast(
              msg: "Please select date of birth",
              backgroundColor: Colors.red,
              textColor: Colors.white);
          return;
        }

        if (boardId == null || boardName == null || boardName!.isEmpty) {
          Fluttertoast.showToast(
              msg: "Please select a board",
              backgroundColor: Colors.red,
              textColor: Colors.white);
          return;
        }

        if (context.mounted) {
          Loader.show(
            context,
            progressIndicator: const CircularProgressIndicator(
              color: ColorCode.buttonColor,
            ),
            overlayColor: Colors.black54,
          );
        }

        final cleanGradeMapList = gradeMapList
            .where((grade) => grade["subjects"].toString().isNotEmpty)
            .map((grade) => {
          "la_grade_id": grade["la_grade_id"],
          "la_section_id": grade["la_section_id"],
          "subjects": grade["subjects"],
        })
            .toList();

        final currentBoardId = boardId;
        final currentBoardName = boardName;

        final schoolData = verifySchoolModel?.data?.school;
        final schoolId = schoolData?.id;
        final schoolCode = schoolData?.code;

        Map<String, dynamic> body = {
          "mobile_no": contact,
          "type": 5,
          "name": teacherNameController.text.trim(),
          "school_id": schoolId,
          "school": schoolData?.name,
          "school_code": schoolCode,
          "state": stateController.text,
          "city": cityController.text,
          "la_board_id": currentBoardId,
          "board_name": currentBoardName,
          "dob": dobController.text.trim(),
          "grades": cleanGradeMapList,
        };

        debugPrint("Update request body: $body");

        Response response = await ProfileService().updateProfileData(body);
        debugPrint("Update Profile Response: ${response.data}");

        Loader.hide();

        if (response.statusCode == 200) {
          final updatedDob = formattedDob;

          if (context.mounted) {
            await Provider.of<TeacherDashboardProvider>(context, listen: false)
                .getDashboardData();

            Provider.of<TeacherDashboardProvider>(context, listen: false)
                .setSelectedBoard(currentBoardId!, currentBoardName!);
          }

          if (currentBoardId != null && currentBoardName != null) {
            setInitialBoard(currentBoardId.toString(), currentBoardName);
          }

          debugPrint("Profile updated. New DOB: $updatedDob");
          debugPrint(
              "Current Board ID: $boardId, Current Board Name: $boardName");

          if (context.mounted) {
            Fluttertoast.showToast(
                msg: "Profile updated successfully",
                backgroundColor: Colors.green,
                textColor: Colors.white,
                toastLength: Toast.LENGTH_LONG);

            Navigator.pop(context);
          }
        } else {
          Fluttertoast.showToast(
              msg: "Failed to update profile. Please try again.",
              backgroundColor: Colors.red,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG);
        }
      } catch (e) {
        Loader.hide();
        debugPrint("Error updating teacher profile: $e");

        if (context.mounted) {
          Fluttertoast.showToast(
              msg: "An error occurred while updating profile",
              backgroundColor: Colors.red,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG);
        }
      }
    }

    void addNewGradeEntry() {
      gradeMapList.add({
        "la_grade_id": "",
        "la_section_id": "",
        "subjects": "",
        "la_section_name": "",
        "subject_name": ""
      });
      safeNotifyListeners();
    }

    void updateGradeMapList(String gradeId, String sectionId, String subjectId,
        String sectionName, String subjectName, int index) {
      if (index < gradeMapList.length) {
        gradeMapList[index] = {
          "la_grade_id": gradeId,
          "la_section_id": sectionId,
          "subjects": subjectId,
          "la_section_name": sectionName,
          "subject_name": subjectName
        };
      }
      safeNotifyListeners();
    }

    void updateDOB(DateTime picked) {
      date = picked;
      dobController.text =
      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      safeNotifyListeners();
    }

    void setInitialDOB(String? dob) {
      if (dob != null && dob.isNotEmpty) {
        try {
          final DateTime dobDate = DateTime.parse(dob);
          date = dobDate;
          dobController.text =
          "${dobDate.year}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.day.toString().padLeft(2, '0')}";
        } catch (e) {
          debugPrint("Error parsing DOB: $e");
          date = DateTime.now();
          dobController.text = "";
        }
      } else {
        date = DateTime.now();
        dobController.text = "";
      }
      safeNotifyListeners();
    }

    void setInitialBoard(String? id, String? name) {
      if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
        try {
          boardId = int.parse(id);
          boardName = name;
          boardNameController.text = name;
          debugPrint("Board set - ID: $boardId, Name: $boardName");
          safeNotifyListeners();
        } catch (e) {
          debugPrint("Error setting board: $e");
        }
      } else {
        debugPrint("Invalid board data provided - ID: $id, Name: $name");
      }
    }

    void updateBoard(int id, String name) {
      try {
        if (id > 0 && name.isNotEmpty) {
          boardId = id;
          boardName = name;
          boardNameController.text = name;
          debugPrint("Board updated - ID: $id, Name: $name");
          safeNotifyListeners();
        }
      } catch (e) {
        debugPrint("Error updating board: $e");
      }
    }

    Future<void> verifySchoolCode(BuildContext context) async {
      Loader.show(
        context,
        progressIndicator: const CircularProgressIndicator(
          color: ColorCode.buttonColor,
        ),
        overlayColor: Colors.black54,
      );

      Response response =
      await SignUpServices().verifyCode(schoolCodeController.text);

      Loader.hide();

      if (response.statusCode == 200) {
        isSchoolCodeValid = true;
        verifySchoolModel = VerifySchoolModel.fromJson(response.data);
        schoolNameController.text = verifySchoolModel!.data!.school!.name!;
        stateController.text = verifySchoolModel!.data!.school!.state!;
        cityController.text = verifySchoolModel!.data!.school!.city!;
      } else {
        isSchoolCodeValid = false;
        schoolCodeController.text = "";
        stateController.text = "";
        cityController.text = "";
      }
      safeNotifyListeners();
    }
  }
