import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../mission/presentations/pages/submit_mission_page.dart';
import '../../nav_bar/presentations/pages/nav_bar_page.dart';
import '../../questions/models/quiz_review_model.dart';
import '../../questions/services/que_services.dart';
import '../../subject_level_list/models/mission_list_model.dart';
import '../../subject_level_list/provider/subject_level_provider.dart';
import '../../vision/models/vision_video.dart';
import '../../vision/presentations/video_player.dart';
import '../../vision/providers/vision_provider.dart';
import '../model/notification_model.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

enum NotificationAction {
  mission,
  quiz,
  vision,
  admin,
  other,
  unknown,
}

String _safeString(dynamic value) => (value ?? '').toString().trim();

class NotificationActionHandler {
  /// Entry point for handling all notifications
  static Future<void> handleNotification(
      BuildContext context, NotificationData notification) async {
    final message = notification.data?.message ?? '';
    final title = notification.data?.title ?? '';
    final actionId = notification.data?.data?.action ?? -1;
    final lowerMessage = message.toLowerCase();

    debugPrint("=== Notification Received ===");
    debugPrint("Action ID: $actionId, Title: $title, Message: $message");

    final action = _getNotificationAction(actionId);
    switch (action) {
      case NotificationAction.admin:
        _showGiftCouponDialog(context, message);
        break;
      case NotificationAction.vision:
        if (lowerMessage.contains('vision has been approved')) {
          _showVisionStatusDialog(context, 'approved', notification);
        } else if (lowerMessage.contains('vision has been rejected')) {
          _showVisionStatusDialog(context, 'rejected', notification);
        } else if (lowerMessage.contains('a new vision has been assigned')) {
          MixpanelService.track('Vision Assigned Notification Clicked');
          _handleVisionVideo(context, notification);
        }
        break;

      case NotificationAction.mission:
        if (lowerMessage.contains('mission') && lowerMessage.contains('approved')) {
          MixpanelService.track('Mission Approved Notification Clicked');
          _showMissionStatusDialog(context, 'approved', notification);
        } else if (lowerMessage.contains('mission') && lowerMessage.contains('rejected')) {
          MixpanelService.track('Mission Rejected Notification Clicked');
          _showMissionStatusDialog(context, 'rejected', notification);
        } else if (lowerMessage.contains('mission') && lowerMessage.contains('assigned')) {
          MixpanelService.track('Mission Assigned Notification Clicked');
          _handleMissionAssigned(context, notification);
        }
        break;

      case NotificationAction.quiz:
        _handleQuizNotification(context, notification);
        break;

      case NotificationAction.other:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NavBarPage(currentIndex: 2)));
        break;

      case NotificationAction.unknown:
        debugPrint("No matching notification action found for ID: $actionId");
        break;
    }
  }

  static NotificationAction _getNotificationAction(int actionId) {
    switch (actionId) {
      case 2:
        return NotificationAction.mission;
      case 3:
        return NotificationAction.quiz;
      case 6:
        return NotificationAction.other;
      case 7:
        return NotificationAction.vision;
      case 8:
        return NotificationAction.admin;
      default:
        return NotificationAction.unknown;
    }
  }

  // ----------------- Admin -----------------
  static void _showGiftCouponDialog(BuildContext context, String message) {
    final linkRegex = RegExp(r'https?:\/\/[^\s]+');
    final match = linkRegex.firstMatch(message);
    final hasLink = match != null;
    final couponLink = hasLink ? match!.group(0)! : '';
    final displayMessage = message.replaceAll(linkRegex, '').trim();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCloseButton(context),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                child: hasLink
                    ? Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.blueAccent)
                    : Image.asset('assets/images/app_logo.png', width: 66, height: 66),
              ),
              const SizedBox(height: 24),
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              if (hasLink)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(couponLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        Fluttertoast.showToast(msg: "Could not open the link");
                      }
                    },
                    child: const Text(
                      'Redeem Now',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildCloseButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          try {
            Navigator.of(context, rootNavigator: true).pop(); // safely close the dialog
          } catch (_) {}
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ----------------- Mission -----------------
  static Future<void> _showMissionStatusDialog(
      BuildContext context,
      String status,
      NotificationData notification,
      )
  async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showNotificationLoader(context);

    try {
      final bool isApproved = status.toLowerCase() == 'approved';
      final bool isRejected = status.toLowerCase() == 'rejected';

      final Color color = isApproved
          ? Colors.green.shade600
          : isRejected
          ? Colors.red.shade600
          : Colors.blue.shade600;
      final IconData icon = isApproved
          ? Icons.check_circle
          : isRejected
          ? Icons.cancel
          : Icons.assignment;

      final subjectId = notification.data?.data?.laSubjectId?.toString() ?? '';
      final levelId = notification.data?.data?.laLevelId?.toString() ?? '';
      final missionId = notification.data?.data?.actionId;

      debugPrint("🔹 Mission dialog called with status: $status");
      debugPrint("🔹 SubjectId: $subjectId, LevelId: $levelId, MissionId: $missionId");

      if (missionId == null) {
        if (navigator.canPop()) navigator.pop();
        Fluttertoast.showToast(msg: "Mission ID is missing in notification");
        return;
      }

      final subjectProvider = Provider.of<SubjectLevelProvider>(context, listen: false);
      MissionDatum? mission;

      try {
        await subjectProvider.getMission({"mission_id": missionId});
        final list = subjectProvider.missionListModel?.data?.missions?.data;
        final matches = list?.where((m) =>m.id.toString() == missionId.toString());
        mission = (matches != null && matches.isNotEmpty) ? matches.first : null;
        debugPrint("⚠️ Fetch by mission_id found: ${mission != null}");
      } catch (e) {
        debugPrint("⚠️ Fetch by mission_id failed: $e");
      }

      if (mission == null && subjectId.isNotEmpty && levelId.isNotEmpty) {
        await subjectProvider.getMission({
          "type": 1,
          "la_subject_id": subjectId,
          "la_level_id": levelId,
        });

        final list = subjectProvider.missionListModel?.data?.missions?.data;
        debugPrint("📋 Missions fetched: ${list?.map((m) => m.id).toList()}");

        final matches = list?.where((m) => m.id == missionId);
        mission = (matches != null && matches.isNotEmpty) ? matches.first : null;
      }

      if (navigator.canPop()) navigator.pop();

      if (mission == null) {
        Fluttertoast.showToast(msg: "Mission not found for the given subject and level");
        debugPrint('❌ Mission not found for missionId: $missionId');
        return;
      }

      if (!isApproved && !isRejected) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SubmitMissionPage(mission: mission!)));
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, size: 50, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  isApproved ? "Mission Approved!" : "Mission Rejected",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  mission?.title ?? "Mission",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.data?.message ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Text(
                  isApproved
                      ? "+${mission?.level?.missionPoints ?? 0} coins earned 🎉"
                      : "-${mission?.level?.missionPoints ?? 0} coins missed 😢",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isApproved ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SubmitMissionPage(mission: mission!)));
                      },
                      child: Text(isApproved ? "Go to Mission" : "Redo"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      child: const Text("Done"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      Fluttertoast.showToast(msg: "Error loading mission details");
      debugPrint('❌ Error in _showMissionStatusDialog: $e');
    }
  }
  // ----------------- Vision -----------------
  static Future<void> _showVisionStatusDialog(BuildContext context, String status, NotificationData notification) async {
    final color = status.toLowerCase() == 'approved' ? Colors.green.shade600 : Colors.red.shade600;
    final icon = status.toLowerCase() == 'approved' ? Icons.check_circle : Icons.cancel;

    showNotificationLoader(context);

    try {
      final visionProvider = Provider.of<VisionProvider>(context, listen: false);
      final rawVisionId = notification.data?.data?.visionId ?? notification.data?.data?.actionId;
      final rawSubjectId = notification.data?.data?.laSubjectId;

      final video = await _fetchVisionVideo(visionProvider, rawVisionId, rawSubjectId);
      hideNotificationLoader(context);

      if (video == null || video.youtubeUrl == null || video.youtubeUrl!.isEmpty) {
        Fluttertoast.showToast(msg: "Video not found");
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 40, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 50, color: color)),
                const SizedBox(height: 16),
                Text(
                  status.toLowerCase() == 'approved' ? "Vision Approved!" : "Vision Rejected",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 12),
                Text(video.title ?? 'Vision', textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                  "Subject: ${video.subjectName ?? 'N/A'} | Level: ${video.levelId ?? 'N/A'}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  status.toLowerCase() == 'approved'
                      ? "+${video.visionTextImagePoints ?? 0} coins earned 🎉"
                      : "-${video.visionTextImagePoints ?? 0} coins missed 😢",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: status.toLowerCase() == 'approved' ? Colors.green : Colors.red,
                  ),
                ),

                Text(notification.data?.message ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        _openVisionVideo(context, video, rawSubjectId?.toString() ?? '');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text(
                          status.toLowerCase() == 'approved' ? "Go to Vision" : "Redo",
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Text("Done", style: TextStyle(fontSize: 13, color: Colors.white))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error loading vision details");
      debugPrint("❌ Vision dialog error: $e");
    }
  }

  static Future<void> _openVisionVideo(BuildContext context, VisionVideo video, String subjectId) async {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: Provider.of<VisionProvider>(context, listen: false),
          child: VideoPlayerPage(video: video, navName: "Notification", subjectId: subjectId, onVideoCompleted: () {}),
        ),
      ),
    );
  }

  static Future<VisionVideo?> _fetchVisionVideo(VisionProvider provider, dynamic visionIdRaw, dynamic subjectIdRaw) async {
    final visionId = _safeString(visionIdRaw);
    final subjectId = _safeString(subjectIdRaw);

    VisionVideo? video;
    for (int level = 1; level <= 4; level++) {
      await provider.initWithSubject(subjectId, level.toString());
      video = provider.getVideoById(visionId);
      if (video != null) break;
    }
    return video;
  }


  // ----------------- Mission Assigned -----------------
  static Future<void> _handleMissionAssigned(BuildContext context, NotificationData notification) async {
    showNotificationLoader(context);

    try {
      final subjectId = notification.data?.data?.laSubjectId?.toString();
      final levelId = notification.data?.data?.laLevelId?.toString();
      final missionId = notification.data?.data?.missionId ?? notification.data?.data?.actionId;

      if (subjectId == null || levelId == null || missionId == null) {
        hideNotificationLoader(context);
        Fluttertoast.showToast(msg: "Mission data incomplete");
        return;
      }

      final provider = Provider.of<SubjectLevelProvider>(context, listen: false);
      await provider.getMission({"type": 1, "la_subject_id": subjectId, "la_level_id": levelId});

      final mission = provider.missionListModel?.data?.missions?.data?.firstWhere((m) => m.id == missionId,);
      hideNotificationLoader(context);

      if (mission != null) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SubmitMissionPage(mission: mission)));
      } else {
        Fluttertoast.showToast(msg: "Mission not found");
      }
    } catch (e) {
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error loading mission");
      debugPrint("❌ _handleMissionAssigned error: $e");
    }
  }

  // ----------------- Vision Video -----------------
  static Future<void> _handleVisionVideo(BuildContext context, NotificationData notification) async {
    showNotificationLoader(context);

    try {
      final video = await _fetchVisionVideo(
        Provider.of<VisionProvider>(context, listen: false),
        notification.data?.data?.visionId ?? notification.data?.data?.actionId,
        notification.data?.data?.laSubjectId,
      );

      hideNotificationLoader(context);

      if (video == null || video.youtubeUrl == null || video.youtubeUrl!.isEmpty) {
        Fluttertoast.showToast(msg: "Video not found");
        return;
      }

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: Provider.of<VisionProvider>(context, listen: false),
          child: VideoPlayerPage(
            video: video,
            navName: "Notification",
            subjectId: notification.data?.data?.laSubjectId?.toString() ?? '',
            onVideoCompleted: () {},
          ),
        ),
      ));
    } catch (e) {
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error opening video");
      debugPrint("❌ _handleVisionVideo error: $e");
    }
  }

  // ----------------- Quiz -----------------
  static Future<void> _handleQuizNotification(BuildContext context, NotificationData notification) async {
    showNotificationLoader(context);

    try {
      final quizId = notification.data!.data!.actionId!.toString();
      Response response = await QueServices().quizReviewData(id: quizId);

      hideNotificationLoader(context);

      if (response.statusCode == 200) {
        QuizReviewModel model = QuizReviewModel.fromJson(response.data);
        final quizStatus = model.quizGame!.status;
        final participantStatus = model.quizGame!.gameParticipantStatus;

        if (quizStatus == 3) Fluttertoast.showToast(msg: "Quiz already completed");
        else if (quizStatus == 4) Fluttertoast.showToast(msg: "Quiz has been expired");
        else if (participantStatus == 3) Fluttertoast.showToast(msg: "You have rejected Quiz");
        else if (quizStatus == 1) Fluttertoast.showToast(msg: "Quiz is waiting to start");
        else if (quizStatus == 2) Fluttertoast.showToast(msg: "You have left the quiz");
        else Fluttertoast.showToast(msg: "Quiz has been expired");
      }
    } catch (e) {
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error loading quiz details");
      debugPrint('❌ _handleQuizNotification error: $e');
    }
  }
}

// ----------------- Loader functions -----------------
void showNotificationLoader(BuildContext context, {String? message}) {
  final displayMessage = message ?? 'Please wait while we open this notification';
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Loading',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim1, anim2) {
      return WillPopScope(
        onWillPop: () async => false,
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Circle Loader
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 🔥 FORCE fixed white/black text
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      decoration: TextDecoration.none, // prevent yellow debug underline
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

void hideNotificationLoader(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
