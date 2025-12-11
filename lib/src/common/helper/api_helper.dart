class ApiHelper {
  ApiHelper._();

  // static const String baseUrl = "https://staging.life-lab.org";
  static const String baseUrl = "https://api.life-lab.org";

  static const String imgBaseUrl =
      "https://lifeappmedia.blr1.digitaloceanspaces.com/";

  /// [Student]
  static const String sendOtp = "/v3/otp/send";
  static const String verifyOtp = "/v3/otp/verify";
  static const String getSchoolList = "/v3/schools";
  static const String getSectionList = "/v3/sections";
  static const String getGradesList = "/v3/grades";
  static const String getStateList = "/api/v1/states/India";
  static const String verifySchoolCode = "/v3/school/code-verify";
  static const String register = "/v3/register";
  static const String dashboard = "/v3/dashboard";
  static const String subjects = "/v3/subjects";
  static const String levels = "/v3/levels";
  static const String mission = "/v3/mission";
  static const String vision = "/v3/vision/list";
  static const String topic = "/v3/topics";
  static const String coinHistory = "/v3/coin-history";
  static const String searchFriend = "/v3/users?search=";
  static const String sendRequest = "/v3/friend-requests/send";
  static const String unfriend = "/v3/friends/";
  static const String getMyFriends = "/v3/friends";
  static const String getSentFriends = "/v3/friend-requests/invite";
  static const String getFriendReq = "/v3/friend-requests";
  static const String acceptFriendReq = "/v3/friend-requests/";
  static const String getHallOfFame = "/v3/hall-of-fame";
  static const String completeMission = "/v3/mission/complete";
  static const String getMissionDetails = "/v3/mission/";
  static const String getQue = "/v3/quiz-games/";
  static const String addQuiz = "/v3/quiz-games";
  static const String submitQuiz = "/v3/quiz-games/";
  static const String quizHistory = "/v3/quiz-games";
  static const String couponList = "/v3/coupon/list";
  static const String redeemCoupon = "/v3/coupon/";
  static const String notification = "/v3/notifications";
  static const String clearNotification = "/v3/notifications/clear";
  static const String tracker = "/v3/game-reports";
  static const String logout = "/api/v1/users/logout";
  static const String uploadImage = "/v3/profile/image";
  static const String uploadProfile = "/v3/profile";
  static const String uploadTeacherProfile = "/v3/profile/teacher";
  static const String campaignsToday = "/v3/campaigns/today";
  static const String updateMentorProfile = "/v3/mentor-profile";
  static const String createSession = "/v3/sessions/create";
  static const String upcomingSession = "/v3/sessions/upcoming";
  static const String sessionDetails = "/v3/sessions/";
  static const String attendSession = "/v3/sessions/attended";
  static const String mySession = "/v3/sessions";
  static const String subscribeCode = "/v3/game-enrollments";
  static const String checkSubscription = "/v3/check-game-enrollments";
  static const String getBoard = "/v3/boards";
  static const String getCompetency = "/v3/competencies";
  static const String getConceptCartoon = "/v3/concept-cartoons";
  static const String getConceptCartoonHeader = "/v3/concept-cartoon-header";
  static const String getAssessment = "/v3/assessments";
  static const String getWorksheet = "/v3/work-sheets";
  static const String lessonLanguage = "/v3/lession-plan-languages";
  static const String lessonPlan = "/v3/lession-plans";
  static const String getClassStudent = "/v3/teachers/class-students";
  static const String getAllStudent = "/v3/reports/all-students";
  static const String classStudent = "/v3/reports/class-students/";

  // Staging endpoints
  static const String classStudentStaging = "/v3/reports/class-students/";
  static const String getAllStudentStaging = "/v3/reports/all-students";
  static const String PblLanguage = "/v3/languages/";
  static const String assignMission = "/v3/teachers/assign-missions";
  static const String assignTopic = "/v3/teachers/assign-topics";
  static const String teachersGrade = "/v3/teachers/grade-sections";
  static const String getTeacherMission = "/v3/teachers/missions";
  static const String pblmapping = "/v3/pbl-textbook-mappings/";
  static const String getTeacherMissionParticipant = "/v3/teachers/mission-participants/";
  static const String teacherMissionApproveReject = "/v3/teachers/submission/";
  static const String getStudentMissions = "/v3/mission/submission";
  static const String storeToken = "/api/v1/device-token";
  static const String appVersion = "/api/app-version";
  static const String faqs = "/v3/faqs";
  static const String pendingRedirect = "/api/pending-redirect";
  static const String teacherSubjectGrade = "/v3/TeacherSubjectGrade/";
  static const String visionComplete = "/v3/vision/complete";
  static const String visionResult = "/v3/vision/result";
  static const String visionSkip = "/v3/vision/skip";
  static const String visionPending = "/v3/vision/pending";
  static const String couponTeacherList = "/v3/coupon/teacher/list";
  static const String couponTeacherPurchaseHistory = "/v3/coupon/teacher/purchase-history";
  static const String couponTeacherCoinHistory = "/v3/coupon/teacher/coin-history";
  static const String couponRedeem = "/v3/coupon";
}