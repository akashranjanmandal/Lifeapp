import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/mentor/code/provider/mentor_code_provider.dart';
import 'package:lifelab3/src/mentor/mentor_create_session/provider/mentor_create_session_provider.dart';
import 'package:lifelab3/src/mentor/mentor_home/presentations/pages/mentor_home_page.dart';
import 'package:lifelab3/src/mentor/mentor_home/provider/mentor_home_provider.dart';
import 'package:lifelab3/src/mentor/mentor_my_session_list/provider/mentor_my_session_list_provider_page.dart';
import 'package:lifelab3/src/mentor/mentor_profile/provider/mentor_profile_provider.dart';
import 'package:lifelab3/src/student/connect/provider/connect_provider.dart';
import 'package:lifelab3/src/student/friend/provider/friend_provider.dart';
import 'package:lifelab3/src/student/hall_of_fame/provider/hall_of_fame_provider.dart';
import 'package:lifelab3/src/student/notification/model/notification_model.dart';
import 'package:lifelab3/src/student/home/provider/dashboard_provider.dart';
import 'package:lifelab3/src/student/mission/provider/mission_provider.dart';
import 'package:lifelab3/src/student/nav_bar/presentations/pages/nav_bar_page.dart';
import 'package:lifelab3/src/student/notification/presentations/notification_handler.dart';
import 'package:lifelab3/src/student/profile/provider/profile_provider.dart';
import 'package:lifelab3/src/student/puzzle/provider/puzzle_provider.dart';
import 'package:lifelab3/src/student/questions/provider/question_provider.dart';
import 'package:lifelab3/src/student/quiz/provider/quiz_provider.dart';
import 'package:lifelab3/src/student/riddles/provider/riddle_provider.dart';
import 'package:lifelab3/src/student/sign_up/provider/sign_up_provider.dart';
import 'package:lifelab3/src/student/student_login/provider/student_login_provider.dart';
import 'package:lifelab3/src/student/subject_level_list/provider/subject_level_provider.dart';
import 'package:lifelab3/src/student/subject_list/provider/subject_list_provider.dart';
import 'package:lifelab3/src/student/tracker/provider/tracker_provider.dart';
import 'package:lifelab3/src/student/vision/models/vision_video.dart';
import 'package:lifelab3/src/student/vision/presentations/video_player.dart';
import 'package:lifelab3/src/teacher/Notifiction/Presentation/notification_handler.dart';
import 'package:lifelab3/src/teacher/shop/provider/provider.dart';
import 'package:lifelab3/src/teacher/shop/services/services.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_login/provider/teacher_login_provider.dart';
import 'package:lifelab3/src/teacher/teacher_profile/provider/teacher_profile_provider.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/provider/teacher_sign_up_provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/tool_mission_page.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:lifelab3/src/student/mission/presentations/pages/submit_mission_page.dart';
import 'package:lifelab3/src/student/subject_level_list/models/mission_list_model.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/teacher/vision/models/vision_model.dart';
import 'package:lifelab3/src/teacher/vision/presentations/video_player.dart';
import 'package:lifelab3/src/teacher/vision/providers/vision_provider.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';
import 'package:lifelab3/src/welcome/presentation/page/welcome_page.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/student/vision/providers/vision_provider.dart';
import 'package:lifelab3/src/common/utils/version_check_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

// Global variables for deep link handling
final navKey = GlobalKey<NavigatorState>();

// Enhanced Deep Link Manager with Proper Teacher/Student Routing
class DeepLinkManager {
  static final DeepLinkManager _instance = DeepLinkManager._internal();
  factory DeepLinkManager() => _instance;
  DeepLinkManager._internal();

  String? _pendingDeepLinkContentId;
  bool _isProcessing = false;
  String? _lastProcessedContentId;
  DateTime? _lastProcessedTime;
  OverlayEntry? _loadingOverlay;

  // Store pending deep link
  void storePendingDeepLink(String contentId) {
    if (_isDuplicateRequest(contentId)) {
      debugPrint('🔄 Ignoring duplicate deep link request: $contentId');
      return;
    }

    _pendingDeepLinkContentId = contentId;
    StorageUtil.putString('pending_deep_link', contentId);
    debugPrint('💾 Stored pending deep link: $contentId');
    _markAsProcessed(contentId);
  }

  // Check if this is a duplicate request (same content ID within 5 seconds)
  bool _isDuplicateRequest(String contentId) {
    if (_lastProcessedContentId == contentId && _lastProcessedTime != null) {
      final timeDiff = DateTime.now().difference(_lastProcessedTime!);
      if (timeDiff.inSeconds < 5) {
        return true;
      }
    }
    return false;
  }

  // ENHANCED: Token-based redirect handling for deferred deep linking
  Future<void> checkPendingTokenRedirect() async {
    try {
      debugPrint('🔍 Checking for pending token redirect...');

      // Get token from shared preferences (set by webview or manual entry)
      final token = await _getStoredToken();
      if (token == null || token.isEmpty) {
        debugPrint('📭 No pending token found');
        return;
      }

      debugPrint('🎯 Found pending token: $token');

      // Call backend API to get redirect data
      final redirectData = await _fetchPendingRedirect(token);
      if (redirectData != null) {
        await _processTokenRedirect(redirectData);
      }

      // Clear token after processing
      await _clearStoredToken();
    } catch (e) {
      debugPrint('❌ Token redirect check failed: $e');
    }
  }

  Future<String?> _getStoredToken() async {
    return StorageUtil.getString('lifeapp_qr_token');
  }

  Future<void> _clearStoredToken() async {
    StorageUtil.putString('lifeapp_qr_token', '');
  }

  Future<Map<String, dynamic>?> _fetchPendingRedirect(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiHelper.baseUrl}${ApiHelper.pendingRedirect}?token=$token'), // Use ApiHelper.pendingRedirect
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          debugPrint('✅ Found pending redirect: ${data['data']}');
          return data['data'];
        }
      }

      debugPrint('❌ No redirect found for token: $token');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching pending redirect: $e');
      return null;
    }
  }
  Future<void> _processTokenRedirect(Map<String, dynamic> redirectData) async {
    final type = redirectData['type']?.toString();
    final id = redirectData['id']?.toString();

    if (type == null || id == null) {
      debugPrint('❌ Invalid redirect data: $redirectData');
      return;
    }

    debugPrint('🔄 Processing token redirect: $type -> $id');

    if (type == 'vision') {
      // Handle vision content
      await _handleVisionRedirect(id);
    } else if (type == 'mission') {
      // Handle mission content
      await _handleMissionRedirect(id);
    } else {
      debugPrint('❌ Unknown redirect type: $type');
    }
  }

  Future<void> _handleVisionRedirect(String contentId) async {
    debugPrint('🎯 Handling vision redirect: $contentId');
    debugPrint('👤 User context: ${getUserContext()}');

    if (canUserAccessVideos()) {
      debugPrint('✅ User can access videos, opening vision: $contentId');
      // Store as pending deep link to be processed after navigation
      storePendingDeepLink(contentId);

      // If user is already logged in, handle immediately
      if (isUserLoggedIn()) {
        final context = navKey.currentState?.overlay?.context;
        if (context != null && context.mounted) {
          handleImmediateDeepLink(contentId);
        }
      }
    } else {
      debugPrint('⏳ User cannot access videos yet, storing vision: $contentId');
      storePendingDeepLink(contentId);
      PremiumToast.showInfo('Please login to access your video');
    }
  }

  Future<void> _handleMissionRedirect(String missionId) async {
    debugPrint('🎯 Handling mission redirect: $missionId');
    debugPrint('👤 User context: ${getUserContext()}');

    if (canUserAccessMissions()) {
      debugPrint('✅ User can access missions, storing mission: $missionId');
      // Store mission ID for later processing
      StorageUtil.putString('pending_mission_id', missionId);

      // If user is already logged in, handle immediately
      if (isUserLoggedIn()) {
        final context = navKey.currentState?.overlay?.context;
        if (context != null && context.mounted) {
          if (isTeacherUser()) {
            _openTeacherMission(context, missionId);
          } else {
            _openStudentMission(context, missionId);
          }
        }
      }
    } else {
      debugPrint('⏳ User cannot access missions yet, storing mission: $missionId');
      StorageUtil.putString('pending_mission_id', missionId);
      PremiumToast.showInfo('Please login to access this mission');
    }
  }

  // ENHANCED: Check both token and regular deep links
  Future<void> checkAllPendingLinks() async {
    debugPrint('🔍 Checking all pending links...');

    // First check token-based redirects (higher priority)
    await checkPendingTokenRedirect();

    // Then check regular deep links
    final pendingContentId = getPendingDeepLink();
    if (pendingContentId != null && pendingContentId.isNotEmpty) {
      debugPrint('🔄 Found regular pending deep link: $pendingContentId');

      if (canUserAccessVideos()) {
        debugPrint('✅ User can access videos, processing deep link');
        processPendingDeepLinkAfterLogin();
      }
    }

    // Check for pending missions
    final pendingMissionId = StorageUtil.getString('pending_mission_id');
    if (pendingMissionId != null && pendingMissionId.isNotEmpty) {
      debugPrint('🔄 Found pending mission: $pendingMissionId');

      if (canUserAccessMissions()) {
        debugPrint('✅ User can access missions, processing mission');
        _processPendingMission(pendingMissionId);
      }
    }
  }

  void _processPendingMission(String missionId) {
    final context = navKey.currentState?.overlay?.context;
    if (context != null && context.mounted) {
      if (isTeacherUser()) {
        _openTeacherMission(context, missionId);
      } else {
        _openStudentMission(context, missionId);
      }
    } else {
      // Retry after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _processPendingMission(missionId);
      });
    }
  }

  // 🎯 TEACHER MISSION NAVIGATION
  void _openTeacherMission(BuildContext context, String missionId) {
    debugPrint('👨‍🏫 Navigating to Teacher Mission UI');

    try {
      // Navigate to teacher mission page (type 1 for regular missions)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => ToolProvider(),
            child: ToolMissionPage(
              projectName: 'QR Mission',
              sectionId: _getTeacherSectionId(),
              gradeId: _getTeacherGradeId(),
              classId: _getTeacherClassId(),
              type: 1, // Regular mission type
            ),
          ),
        ),
      );

      PremiumToast.showInfo('Opening Teacher Mission: $missionId');

      MixpanelService.track("QR Teacher Mission Opened", properties: {
        'mission_id': missionId,
        'user_type': 'teacher',
        'section_id': _getTeacherSectionId(),
        'grade_id': _getTeacherGradeId(),
        'class_id': _getTeacherClassId(),
      });
    } catch (e) {
      debugPrint('❌ Error opening teacher mission: $e');
      PremiumToast.showError('Error opening teacher mission');
    }
  }

  // 🎯 STUDENT MISSION NAVIGATION
  void _openStudentMission(BuildContext context, String missionId) {
    debugPrint('👨‍🎓 Navigating to Student Mission UI');

    try {
      // For student, we need to fetch mission data first
      _fetchAndOpenStudentMission(context, missionId);
    } catch (e) {
      debugPrint('❌ Error opening student mission: $e');
      PremiumToast.showError('Error opening student mission');
    }
  }

  Future<void> _fetchAndOpenStudentMission(BuildContext context, String missionId) async {
    try {
      _showLoading();

      // Fetch mission data from API
      final missionData = await _fetchMissionData(missionId);

      _hideLoading();

      if (missionData != null) {
        // Navigate to student mission submission page
        push(
          context: context,
          page: SubmitMissionPage(mission: missionData),
        );

        PremiumToast.showInfo('Opening Student Mission: ${missionData.title}');

        MixpanelService.track("QR Student Mission Opened", properties: {
          'mission_id': missionId,
          'mission_title': missionData.title,
          'user_type': 'student',
        });
      } else {
        PremiumToast.showError('Mission not found');
      }
    } catch (e) {
      _hideLoading();
      debugPrint('❌ Error fetching mission data: $e');
      PremiumToast.showError('Error loading mission');
    }
  }

  // Helper method to fetch mission data
  Future<MissionDatum?> _fetchMissionData(String missionId) async {
    try {
      // TODO: Implement your API call to fetch mission data by ID
      // Example:
      // final response = await http.get(
      // );
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return MissionDatum.fromJson(data['data']);
      // }

      // For now, return a mock mission data
      return MissionDatum(
        id: int.tryParse(missionId) ?? 0,
        title: 'QR Code Mission',
        status: 'Get Started',
      );
    } catch (e) {
      debugPrint('❌ Error fetching mission data: $e');
      return null;
    }
  }

  // Mark a content ID as processed
  void _markAsProcessed(String contentId) {
    _lastProcessedContentId = contentId;
    _lastProcessedTime = DateTime.now();
  }

  // Get pending deep link
  String? getPendingDeepLink() {
    if (_pendingDeepLinkContentId != null) {
      return _pendingDeepLinkContentId;
    }
    return StorageUtil.getString('pending_deep_link');
  }

  // Clear pending deep link
  void clearPendingDeepLink() {
    _pendingDeepLinkContentId = null;
    StorageUtil.putString('pending_deep_link', '');
    debugPrint('🗑️ Cleared pending deep link');
  }

  // FIXED: Enhanced auth state detection
  bool isUserLoggedIn() {
    final isStudent = StorageUtil.getBool(StringHelper.isLoggedIn) ?? false;
    final isTeacher = StorageUtil.getBool(StringHelper.isTeacher) ?? false;
    final isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;

    return isStudent || isTeacher || isMentor;
  }

  // Enhanced user type detection
  String getUserType() {
    final isStudent = StorageUtil.getBool(StringHelper.isLoggedIn) ?? false;
    final isTeacher = StorageUtil.getBool(StringHelper.isTeacher) ?? false;
    final isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;

    if (isMentor) return 'mentor';
    if (isTeacher) return 'teacher';
    if (isStudent) return 'student';
    return 'not_logged_in';
  }

  bool isTeacherUser() {
    return StorageUtil.getBool(StringHelper.isTeacher) ?? false;
  }

  bool isStudentUser() {
    return StorageUtil.getBool(StringHelper.isLoggedIn) ?? false;
  }

  // Check if user can access videos (both students and teachers can access)
  bool canUserAccessVideos() {
    final isLoggedIn = isUserLoggedIn();
    final isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;
    return isLoggedIn && !isMentor; // Both students and teachers can access
  }

  // Check if user can access missions
  bool canUserAccessMissions() {
    final isLoggedIn = isUserLoggedIn();
    final isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;
    return isLoggedIn && !isMentor; // Both students and teachers can access
  }

  // Helper methods to get teacher context
  String _getTeacherSectionId() {
    return StorageUtil.getString('teacher_section_id') ?? '';
  }

  String _getTeacherGradeId() {
    return StorageUtil.getString('teacher_grade_id') ?? '';
  }

  String _getTeacherClassId() {
    return StorageUtil.getString('teacher_class_id') ?? '';
  }

  // Enhanced user context detection
  Map<String, dynamic> getUserContext() {
    return {
      'type': getUserType(),
      'isTeacher': isTeacherUser(),
      'isStudent': isStudentUser(),
      'sectionId': isTeacherUser() ? _getTeacherSectionId() : '',
      'gradeId': isTeacherUser() ? _getTeacherGradeId() : '',
      'classId': isTeacherUser() ? _getTeacherClassId() : '',
    };
  }

  // Process pending deep link after login
  void processPendingDeepLinkAfterLogin() {
    if (_isProcessing) {
      debugPrint('⏳ Already processing a deep link, skipping');
      return;
    }

    final pendingContentId = getPendingDeepLink();
    if (pendingContentId != null && pendingContentId.isNotEmpty) {
      if (_isDuplicateRequest(pendingContentId)) {
        debugPrint('🔄 Ignoring duplicate deep link after login: $pendingContentId');
        return;
      }

      debugPrint('🔄 Processing pending deep link after login: $pendingContentId');
      debugPrint('👤 User context after login: ${getUserContext()}');

      // Check if user can access videos after login
      if (!canUserAccessVideos()) {
        debugPrint('❌ User cannot access videos even after login');
        PremiumToast.showError('Your account type cannot access video content');
        clearPendingDeepLink();
        return;
      }

      _isProcessing = true;

      // Wait for navigation to complete and context to be available
      Future.delayed(const Duration(milliseconds: 2000), () {
        _processWithRetry(pendingContentId, retryCount: 0);
      });
    } else {
      debugPrint('📭 No pending deep links to process after login');
    }
  }

  void _processWithRetry(String contentId, {int retryCount = 0}) {
    if (retryCount >= 8) {
      debugPrint('💥 Failed to process deep link after $retryCount retries');
      _isProcessing = false;
      _hideLoading();
      PremiumToast.showError('Failed to open content. Please try again.');
      return;
    }

    final context = navKey.currentState?.overlay?.context;
    if (context != null && context.mounted) {
      debugPrint('✅ Context available (retry $retryCount), opening video: $contentId');
      _isProcessing = false;
      _openVisionVideoDirectly(context, contentId);
    } else {
      debugPrint('⏳ Context not available (retry $retryCount), waiting...');
      Future.delayed(Duration(milliseconds: 800 * (retryCount + 1)), () {
        _processWithRetry(contentId, retryCount: retryCount + 1);
      });
    }
  }

  // Handle immediate deep link (user is already logged in)
  void handleImmediateDeepLink(String contentId) {
    if (_isProcessing) {
      debugPrint('⏳ Already processing a deep link, skipping immediate handling');
      return;
    }

    if (_isDuplicateRequest(contentId)) {
      debugPrint('🔄 Ignoring duplicate immediate deep link: $contentId');
      return;
    }

    debugPrint('🎯 Handling immediate deep link: $contentId');
    debugPrint('👤 User context: ${getUserContext()}');

    _isProcessing = true;

    Future.delayed(const Duration(milliseconds: 1000), () {
      _processWithRetry(contentId, retryCount: 0);
    });
  }

  // Show loading using Overlay (more reliable than dialog)
  void _showLoading() {
    if (_loadingOverlay != null) return;

    final overlayState = navKey.currentState?.overlay;
    if (overlayState == null) {
      debugPrint('❌ Cannot show loading: overlay state is null');
      return;
    }

    _loadingOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text(
                  'Opening Content...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_loadingOverlay!);
    debugPrint('⏳ Loading overlay shown');
  }

  // Hide loading overlay
  void _hideLoading() {
    if (_loadingOverlay != null) {
      try {
        _loadingOverlay!.remove();
        debugPrint('✅ Loading overlay hidden');
      } catch (e) {
        debugPrint('❌ Error removing loading overlay: $e');
      }
      _loadingOverlay = null;
    }
  }

  Future<void> _openVisionVideoDirectly(BuildContext context, String contentId) async {
    debugPrint('🎬 Opening video directly with content ID: $contentId');
    debugPrint('👤 User context: ${getUserContext()}');

    // Mark as processed to prevent duplicates
    _markAsProcessed(contentId);

    try {
      _showLoading();

      // 🎯 USER-TYPE SPECIFIC VIDEO FETCHING
      dynamic video;
      if (isTeacherUser()) {
        // Use teacher vision provider to fetch video
        final teacherVisionProvider = Provider.of<TeacherVisionProvider>(context, listen: false);
        video = await teacherVisionProvider.getTeacherVisionVideoDirectly(contentId);
      } else {
        // Use student vision provider to fetch video
        final visionProvider = Provider.of<VisionProvider>(context, listen: false);
        video = await visionProvider.getVisionVideoDirectly(contentId);
      }

      _hideLoading();

      if (video != null) {
        debugPrint('✅ Video found: ${video.title}');

        // Clear pending deep link since we're successfully opening
        clearPendingDeepLink();

        PremiumToast.showSuccess('Opening: ${video.title}');

        // 🎯 USER-TYPE AWARE NAVIGATION
        if (isTeacherUser()) {
          await _openTeacherVision(context, video, contentId);
        } else {
          await _openStudentVision(context, video, contentId);
        }

        MixpanelService.track("QR Code Video Opened", properties: {
          'content_id': contentId,
          'video_title': video.title,
          'user_type': getUserType(),
          'user_context': getUserContext(),
          'method': 'deep_link'
        });
      } else {
        debugPrint('❌ Video not found with contentId: $contentId');
        PremiumToast.showError('Video not found. Please check the QR code.');
      }
    } catch (e, s) {
      debugPrint('💥 Error opening video: $e\n$s');
      _hideLoading();
      PremiumToast.showError('Error opening video. Please try again.');
    } finally {
      _isProcessing = false;
      _hideLoading();
    }
  }

  // 🎯 TEACHER VISION NAVIGATION
  Future<void> _openTeacherVision(BuildContext context, TeacherVisionVideo video, String contentId) async {
    debugPrint('👨‍🏫 Navigating to Teacher Vision UI');

    try {
      final teacherVisionProvider = Provider.of<TeacherVisionProvider>(context, listen: false);

      // Navigate to teacher video player
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: teacherVisionProvider,
            child: TeacherVideoPlayerPage(
              video: video,
              sectionId: _getTeacherSectionId(),
              gradeId: _getTeacherGradeId(),
              classId: _getTeacherClassId(),
              onBack: () {
                // Handle back callback
                debugPrint('Teacher video player closed');
              },
            ),
          ),
        ),
      );

      MixpanelService.track("QR Teacher Video Opened", properties: {
        'content_id': contentId,
        'video_title': video.title,
        'user_type': 'teacher',
        'section_id': _getTeacherSectionId(),
        'grade_id': _getTeacherGradeId(),
        'class_id': _getTeacherClassId(),
      });
    } catch (e) {
      debugPrint('❌ Error opening teacher vision: $e');
      PremiumToast.showError('Error opening teacher vision');
    }
  }

  // 🎯 STUDENT VISION NAVIGATION
  Future<void> _openStudentVision(BuildContext context, VisionVideo video, String contentId) async {
    debugPrint('👨‍🎓 Navigating to Student Vision UI');

    try {
      final visionProvider = Provider.of<VisionProvider>(context, listen: false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: visionProvider,
            child: VideoPlayerPage(
              video: video,
              navName: 'Vision',
              subjectId: 'default',
              onVideoCompleted: () {
                // Handle video completion for student
                debugPrint('Student video completed');
              },
            ),
          ),
        ),
      );

      MixpanelService.track("QR Student Video Opened", properties: {
        'content_id': contentId,
        'video_title': video.title,
        'user_type': 'student',
      });
    } catch (e) {
      debugPrint('❌ Error opening student vision: $e');
      PremiumToast.showError('Error opening student vision');
    }
  }
}

// Initialize deep link manager
final deepLinkManager = DeepLinkManager();

// Premium Toast Service
class PremiumToast {
  static void showSuccess(String message, {int duration = 4}) {
    _showToast(
      message: message,
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
      duration: duration,
    );
  }

  static void showError(String message, {int duration = 4}) {
    _showToast(
      message: message,
      backgroundColor: const Color(0xFFEF4444),
      textColor: Colors.white,
      duration: duration,
    );
  }

  static void showInfo(String message, {int duration = 4}) {
    _showToast(
      message: message,
      backgroundColor: const Color(0xFF3B82F6),
      textColor: Colors.white,
      duration: duration,
    );
  }

  static void showWarning(String message, {int duration = 4}) {
    _showToast(
      message: message,
      backgroundColor: const Color(0xFFF59E0B),
      textColor: Colors.white,
      duration: duration,
    );
  }

  static void _showToast({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required int duration,
  }) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: duration,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 14.0,
    );
  }
}

// Deep Link Handling
Future<void> initDeepLinks() async {
  debugPrint('🔄 Deep link handling initialized');

  final appLinks = AppLinks();

  try {
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('🎯 Initial deep link detected: $initialUri');
      handleIncomingLink(initialUri.toString());
    }
  } catch (e) {
    debugPrint('❌ Error getting initial deep link: $e');
  }

  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      debugPrint('🎯 Incoming deep link: $uri');
      handleIncomingLink(uri.toString());
    }
  }, onError: (err) {
    debugPrint('❌ Deep link stream error: $err');
  });
}

void handleIncomingLink(String link) {
  debugPrint('🔗 Processing incoming link: $link');

  try {
    final uri = Uri.parse(link);
    if (uri.host == 'api.life-lab.org' && uri.path.startsWith('/qr/content/')) {
      final segments = uri.pathSegments;
      if (segments.length >= 3) {
        final contentId = segments[2];
        debugPrint('📱 QR Content ID: $contentId');
        _handleDeepLinkContent(contentId);
      }
    }
  } catch (e) {
    debugPrint('❌ Error handling incoming link: $e');
    PremiumToast.showError('Invalid QR code link');
  }
}

void _handleDeepLinkContent(String contentId) {
  debugPrint('🎯 Handling deep link content: $contentId');

  // FIXED: Use the proper auth detection method
  final bool isLoggedIn = deepLinkManager.isUserLoggedIn();
  final bool isTeacher = StorageUtil.getBool(StringHelper.isTeacher) ?? false;
  final bool isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;

  debugPrint('🔐 Auth state - LoggedIn: $isLoggedIn, Teacher: $isTeacher, Mentor: $isMentor');
  debugPrint('👤 User type: ${deepLinkManager.getUserType()}');

  if (!isLoggedIn) {
    debugPrint('👤 User not logged in, storing deep link for later');
    PremiumToast.showInfo('Please login to access this content');
    deepLinkManager.storePendingDeepLink(contentId);

    // FIXED: Navigate to login screen when user is not logged in
    _navigateToLoginForDeepLink();
    return;
  }

  if (isMentor) {
    debugPrint('👨‍🏫 User is mentor, showing access denied');
    PremiumToast.showError('This content is only available for students and teachers');
    return;
  }

  // User is logged in as student or teacher - handle immediately
  debugPrint('✅ User logged in as ${isTeacher ? 'teacher' : 'student'}, handling deep link immediately');
  deepLinkManager.handleImmediateDeepLink(contentId);
}

// NEW: Navigate to login when deep link requires authentication
void _navigateToLoginForDeepLink() {
  final context = navKey.currentState?.overlay?.context;
  if (context != null && context.mounted) {
    // Navigate to welcome/login page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelComePage()),
          (route) => false,
    );
  }
}

// ENHANCED: Handle all pending links after login
void handlePostLoginDeepLinkProcessing() {
  debugPrint('🔄 Checking for all pending links after login');

  Future.delayed(const Duration(seconds: 2), () {
    // Check both token redirects and regular deep links
    deepLinkManager.checkAllPendingLinks();
  });
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  final payload = notificationResponse.payload;
  debugPrint("=== NOTIFICATION TAP BACKGROUND ===");
  debugPrint("Payload: $payload");
  if (payload == null) {
    debugPrint("Payload is null, returning");
    return;
  }

  try {
    final data = jsonDecode(payload);
    debugPrint("Parsed data: $data");
    if (data['type'] == 'image' && data['filePath'] != null) {
      debugPrint("Image notification detected, filePath: ${data['filePath']}");
      final file = File(data['filePath']);
      debugPrint("Checking if file exists: ${file.path}");
      if (await file.exists()) {
        debugPrint("File exists, opening with OpenFile.open");
        final result = await OpenFile.open(file.path);
        debugPrint("OpenFile result: ${result.message} - ${result.type}");
      } else {
        debugPrint("File not found: ${data['filePath']}");
      }
    } else {
      debugPrint("Non-image notification, navigating to screen");
      navigateToScreen(data);
    }
  } catch (e) {
    debugPrint("Error parsing JSON payload: $e");
    if (payload.endsWith('.png') || payload.endsWith('.jpg')) {
      debugPrint("Trying to open as direct file path: $payload");
      final result = await OpenFile.open(payload);
      debugPrint("OpenFile result: ${result.message} - ${result.type}");
    } else {
      debugPrint("Invalid notification payload: $payload");
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message ${message.messageId}');
  debugPrint('Handling a background message ${message.notification?.android?.channelId ?? "NA"}');
  debugPrint("PayLoad ${message.data}");
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set white system bars with dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);

  await StorageUtil.getInstance();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  channel = const AndroidNotificationChannel(
    'lifelab',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@drawable/launch_background'),
    iOS: DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("=== NOTIFICATION TAP (APP OPEN) ===");
      debugPrint("Payload: ${response.payload}");
      if (response.payload != null) {
        handleNotificationTap(response.payload!);
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  await MixpanelService.init();
  await initDeepLinks();

  runApp(const MyApp());
}

class VersionCheckWrapper extends StatefulWidget {
  final Widget child;

  const VersionCheckWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  final VersionCheckService _versionCheckService = VersionCheckService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _versionCheckService.checkAndPromptUpdate(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLogin;
  bool isMentor = false;
  bool isTeacher = false;
  late final AppLinks _appLinks;
  bool _isAppInitialized = false;

  @override
  void initState() {
    _appLinks = AppLinks();
    getFcmToken();
    _initializeAuthState();
    _setupDeepLinkRecovery();
    super.initState();
  }

  void _initializeAuthState() {
    // FIXED: Use the proper auth detection method
    isLogin = deepLinkManager.isUserLoggedIn();
    isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;
    isTeacher = StorageUtil.getBool(StringHelper.isTeacher) ?? false;
    debugPrint("🔐 Initial Auth State - LoggedIn: $isLogin, Teacher: $isTeacher, Mentor: $isMentor");
    debugPrint("👤 Initial User type: ${deepLinkManager.getUserType()}");
  }

  void _setupDeepLinkRecovery() {
    // Check for token-based redirects first
    Future.delayed(const Duration(seconds: 2), () {
      _checkTokenRedirects();
    });

    // Then check regular deep links
    Future.delayed(const Duration(seconds: 3), () {
      _processPendingDeepLinks();
      _isAppInitialized = true;
    });
  }

  void _checkTokenRedirects() async {
    debugPrint('🔍 Checking token redirects...');
    await deepLinkManager.checkPendingTokenRedirect();
  }

  void _processPendingDeepLinks() {
    final pendingContentId = deepLinkManager.getPendingDeepLink();
    if (pendingContentId != null && pendingContentId.isNotEmpty) {
      debugPrint('🔄 Found pending deep link on app start: $pendingContentId');

      if (deepLinkManager.canUserAccessVideos()) {
        debugPrint('✅ User can access videos, processing pending deep link');
        deepLinkManager.processPendingDeepLinkAfterLogin();
      } else {
        debugPrint('⏳ User cannot access videos yet, keeping deep link pending');
        PremiumToast.showInfo('Please login to access your video content');
      }
    } else {
      debugPrint('📭 No pending deep links found on app start');
    }
  }

  getFcmToken() async {
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((value) {
      StorageUtil.putString(StringHelper.fcmToken, value!);
      debugPrint("Fcm Token: $value");
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(message.notification?.title);
        Future.delayed(const Duration(milliseconds: 3000), () {
          navigateToScreen(message.data);
        });
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("LISTEN${message.data.toString()}");
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      debugPrint("LISTEN${(message.notification?.android?.channelId ?? "NA").toString()}");

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: 'launch_background',
              ),
            ),
            payload: jsonEncode(message.data));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigateToScreen(message.data);
    });

    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      await Firebase.initializeApp();
      navigateToScreen(message.data);
    });
  }

  Widget _buildHomeScreen() {
    // Check for pending deep links when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_isAppInitialized) {
          _processPendingDeepLinks();
        }
      });
    });

    // FIXED: Use proper auth detection for home screen
    final isLoggedIn = deepLinkManager.isUserLoggedIn();
    final isTeacher = StorageUtil.getBool(StringHelper.isTeacher) ?? false;
    final isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;

    Widget homeWidget = isLoggedIn
        ? (isTeacher ? const TeacherDashboardPage() : const NavBarPage(currentIndex: 0))
        : isMentor
        ? const MentorHomePage()
        : const WelComePage();

    return VersionCheckWrapper(child: homeWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentLoginProvider()),
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
        ChangeNotifierProvider(create: (_) => ConnectProvider()),
        ChangeNotifierProvider(create: (_) => SubjectListProvider()),
        ChangeNotifierProvider(create: (_) => SubjectLevelProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => RiddleProvider()),
        ChangeNotifierProvider(create: (_) => PuzzleProvider()),
        ChangeNotifierProvider(create: (_) => MentorOtpProvider()),
        ChangeNotifierProvider(create: (_) => MentorHomeProvider()),
        ChangeNotifierProvider(create: (_) => MentorCreateSessionProvider()),
        ChangeNotifierProvider(create: (_) => MentorMySessionListProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TeacherLoginProvider()),
        ChangeNotifierProvider(create: (_) => TeacherDashboardProvider()),
        ChangeNotifierProvider(create: (_) => TeacherSignUpProvider()),
        ChangeNotifierProvider(create: (_) => StudentProgressProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => HallOfFameProvider()),
        ChangeNotifierProvider(create: (_) => QuestionProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductService('https://your.api/baseurl')),
        ),
        ChangeNotifierProvider(create: (_) => MentorProfileProvider()),
        ChangeNotifierProvider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProfileProvider()),
        ChangeNotifierProvider(create: (_) => VisionProvider()),
        ChangeNotifierProvider(
          create: (_) => TeacherVisionProvider(gradeId: StorageUtil.getString('gradeId') ?? ''),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navKey,
        title: 'Life App',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        builder: (context, child) {
          return Material(
            type: MaterialType.transparency,
            child: child!,
          );
        },
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              color: ColorCode.defaultBgColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            elevation: 0,
            titleSpacing: 0,
            centerTitle: false,
            backgroundColor: ColorCode.defaultBgColor,
            scrolledUnderElevation: 0,
          ),
          scaffoldBackgroundColor: ColorCode.defaultBgColor,
          primaryColor: ColorCode.defaultBgColor,
          fontFamily: "Avenir",
          textTheme: const TextTheme().apply(displayColor: Colors.white),
        ),
        home: _buildHomeScreen(),
      ),
    );
  }
}

int _safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _safeString(dynamic value, {String fallback = ""}) {
  if (value == null) return fallback;
  return value.toString().trim();
}

void navigateToScreen(Map<String, dynamic> data) {
  debugPrint("=== Raw Notification Data ===");
  debugPrint(data.toString());

  final bool isStudent = StorageUtil.getBool(StringHelper.isLoggedIn) ?? false;
  final bool isTeacher = StorageUtil.getBool(StringHelper.isTeacher) ?? false;
  final bool isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;

  final context = navKey.currentState?.overlay?.context;
  if (context == null) {
    debugPrint("Navigator context is null, cannot navigate or show popup.");
    return;
  }

  if (isStudent) {
    try {
      dynamic rawDataDynamic = data['data'];
      Map<String, dynamic> rawData = {};

      if (rawDataDynamic is String) {
        try {
          final decoded = jsonDecode(rawDataDynamic);
          if (decoded is Map<String, dynamic>) rawData = decoded;
        } catch (e) {
          debugPrint("Failed to decode rawData string → $e");
        }
      } else if (rawDataDynamic is Map<String, dynamic>) {
        rawData = rawDataDynamic;
      }

      final studentPayload = {
        "id": null,
        "type": _safeString(data['type']),
        "data": {
          "title": _safeString(data['title'], fallback: "Notification"),
          "message": _safeString(data['message']),
          "data": {
            "action": _safeInt(rawData['action']),
            "actionId": _safeInt(rawData['action_id'] ?? rawData['actionId']),
            "laSubjectId": _safeInt(rawData['la_subject_id'] ?? rawData['laSubjectId']),
            "laLevelId": _safeInt(rawData['la_level_id'] ?? rawData['laLevelId']),
            "missionId": _safeInt(rawData['mission_id'] ?? rawData['missionId']),
            "visionId": _safeInt(rawData['vision_id'] ?? rawData['visionId']),
            "admin_message_id": _safeInt(rawData['admin_message_id']),
            "time": _safeInt(rawData['time']),
          },
        },
      };

      debugPrint("=== Notification Payload Sent to Handler ===");
      debugPrint(jsonEncode(studentPayload));

      final notification = NotificationData.fromJson(studentPayload);

      debugPrint("=== Parsed NotificationData Object ===");
      debugPrint("Title: ${notification.data?.title}");
      debugPrint("Message: ${notification.data?.message}");
      debugPrint("Action ID: ${notification.data?.data?.actionId}");
      debugPrint("Mission ID: ${notification.data?.data?.missionId}");
      debugPrint("Vision ID: ${notification.data?.data?.visionId}");
      debugPrint("Subject ID: ${notification.data?.data?.laSubjectId}");
      debugPrint("Level ID: ${notification.data?.data?.laLevelId}");

      NotificationActionHandler.handleNotification(context, notification);
    } catch (e, s) {
      debugPrint("Error parsing notification for student: $e\n$s");
    }
  } else if (isTeacher) {
    TeacherNotificationHandler.show(context, data);
  } else if (isMentor) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MentorHomePage()),
    );
  } else {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelComePage()),
    );
  }
}

void handleNotificationTap(String payload) async {
  debugPrint("=== NOTIFICATION TAP (FOREGROUND) ===");
  debugPrint("Payload: $payload");
  try {
    final data = jsonDecode(payload);
    debugPrint("Parsed data: $data");
    if (data['type'] == 'image' && data['filePath'] != null) {
      debugPrint("Image notification detected, filePath: ${data['filePath']}");
      final file = File(data['filePath']);
      debugPrint("Checking if file exists: ${file.path}");
      if (await file.exists()) {
        debugPrint("File exists, opening with OpenFile.open");
        final result = await OpenFile.open(file.path);
        debugPrint("OpenFile result: ${result.message} - ${result.type}");
      } else {
        debugPrint("File not found: ${data['filePath']}");
        PremiumToast.showError("File not found");
      }
    } else {
      debugPrint("Non-image notification, navigating to screen");
      navigateToScreen(data);
    }
  } catch (e) {
    debugPrint("Error parsing JSON payload: $e");
    debugPrint("Invalid notification payload: $payload");
  }
}