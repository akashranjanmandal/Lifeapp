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
import '../../subject_level_list/provider/subject_level_provider.dart';
import '../../vision/models/vision_video.dart';
import '../../vision/presentations/video_player.dart';
import '../../vision/providers/vision_provider.dart';
import '../model/notification_model.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class NotificationActionHandler {
  static Future<void> handleNotification(
      BuildContext context, NotificationData notification) async {

    final message = notification.data?.message ?? '';
    final title = notification.data?.title ?? '';
    final action = notification.data?.data?.action?.toString() ?? '';
    final type = notification.type ?? '';
    final lowerMessage = message.toLowerCase();

    debugPrint("=== Notification Received ===");
    debugPrint("Type: $type");
    debugPrint("Action: $action");
    debugPrint("Title: $title");
    debugPrint("Message: $message");

    // ----------------- Admin -----------------
    if (type.contains('AdminMessageNotification')) {
      debugPrint("Admin notification detected");
      _showGiftCouponDialog(context, message);
      return;
    }

    // ----------------- Vision Approved/Rejected -----------------
    if (lowerMessage.contains('vision has been approved')) {
      debugPrint("Vision approved notification detected");
      _showVisionStatusDialog(context, 'approved', notification);
      return;
    } else if (lowerMessage.contains('vision has been rejected')) {
      debugPrint("Vision rejected notification detected");
      _showVisionStatusDialog(context, 'rejected', notification);
      return;
    }
    // ----------------- Vision Assigned -----------------
    else if (lowerMessage.contains('a new vision has been assigned to you')) {
      debugPrint("Vision assigned notification detected");
      MixpanelService.track('Vision Assigned Notification Clicked');
      _handleVisionVideo(context, notification);
      return;
    }

    // ----------------- Mission Approved/Rejected -----------------
    else if (lowerMessage.contains('mission') && lowerMessage.contains('approved')) {
      debugPrint("Mission approved notification detected");
      MixpanelService.track('Mission Approved Notification Clicked');
      _showMissionStatusDialog(context, 'approved', notification);
      return;
    } else if (lowerMessage.contains('mission') && lowerMessage.contains('rejected')) {
      debugPrint("Mission rejected notification detected");
      MixpanelService.track('Mission Rejected Notification Clicked');
      _showMissionStatusDialog(context, 'rejected', notification);
      return;
    }
    // ----------------- Mission Assigned -----------------
    else if (lowerMessage.contains('mission') && lowerMessage.contains('assigned')) {
      debugPrint("Mission assigned notification detected");
      MixpanelService.track('Mission Assigned Notification Clicked');
      _handleMissionAssigned(context, notification);
      return;
    }

    // ----------------- Quiz -----------------
    if (action == '3' &&
        notification.data?.data?.actionId != null &&
        notification.data?.data?.time != null) {

      debugPrint("Quiz notification detected");
      _handleQuizNotification(context, notification);
      return;
    }

    // ----------------- Other actions -----------------
    if (action == '6') {
      debugPrint("Other action (6) notification detected");
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const NavBarPage(currentIndex: 2)));
      return;
    }

    debugPrint("No matching notification type found");
  }

  static void _showGiftCouponDialog(BuildContext context, String message) {
    final linkRegex = RegExp(r'https?:\/\/[^\s]+');
    final match = linkRegex.firstMatch(message);
    final hasLink = match != null;
    final couponLink = hasLink ? match!.group(0)! : '';
    final displayMessage = message.replaceAll(linkRegex, '').trim();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.deepPurpleAccent,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  child: hasLink
                      ? Icon(
                    Icons.card_giftcard_outlined,
                    size: 64,
                    color: Colors.blueAccent,
                  )
                      : Image.asset(
                    'assets/images/app_logo.png',
                    width: 66,
                    height: 66,
                  ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.6),
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
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showMissionStatusDialog(
      BuildContext context, String status, NotificationData notification) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    // Loader while fetching mission data
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

      // Check if missionId is null
      if (missionId == null) {
        hideNotificationLoader(context);
        Fluttertoast.showToast(msg: "Mission ID is missing in notification");
        debugPrint('❌ Mission ID is null, cannot find specific mission');
        return;
      }

      final subjectProvider =
      Provider.of<SubjectLevelProvider>(context, listen: false);

      var mission;

      // Fetch missions only if we have valid subject and level IDs
      if (subjectId.isNotEmpty && levelId.isNotEmpty) {
        Map<String, dynamic> missionData = {
          "type": 1,
          "la_subject_id": subjectId,
          "la_level_id": levelId,
        };
        await subjectProvider.getMission(missionData);

        // Find specific mission
        mission = subjectProvider.missionListModel?.data?.missions?.data
            ?.firstWhere((m) => m.id == missionId, );
      }

      hideNotificationLoader(context);

      // If mission is null or not found, show error and return
      if (mission == null) {
        Fluttertoast.showToast(msg: "Mission not found for the given subject and level");
        debugPrint('❌ Mission not found for missionId: $missionId');
        return;
      }

      // Otherwise show dialog for approved/rejected
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
                  isApproved
                      ? "Mission Approved!"
                      : "Mission Rejected",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  mission.title ?? "Mission",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.data?.message ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),

                // Show earned/missed coins
                Text(
                  isApproved
                      ? "+${mission.level?.missionPoints ?? 0} coins earned 🎉"
                      : "-${mission.level?.missionPoints ?? 0} coins missed 😢",
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
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop(); // Close dialog first
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SubmitMissionPage(mission: mission),
                          ),
                        );
                      },
                      child: Text(isApproved ? "Go to Mission" : "Redo"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error loading mission details");
      debugPrint('❌ Error in showMissionStatusDialog: $e');
    }
  }

  static Future<void> _showVisionStatusDialog(
      BuildContext context, String status, NotificationData notification) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showNotificationLoader(context);

    try {
      debugPrint("🟢 showVisionStatusDialog called with status: $status");
      final bool isApproved = status.toLowerCase() == 'approved';
      final Color color =
      isApproved ? Colors.green.shade600 : Colors.red.shade600;
      final IconData icon = isApproved ? Icons.check_circle : Icons.cancel;

      final visionProvider =
      Provider.of<VisionProvider>(context, listen: false);
      VisionVideo? video;

      final rawVisionId =
          notification.data?.data?.visionId ?? notification.data?.data?.actionId;
      final rawSubjectId = notification.data?.data?.laSubjectId;

      debugPrint('🔍 Raw Vision ID: $rawVisionId');
      debugPrint('🔍 Raw Subject ID: $rawSubjectId');

      final visionId = rawVisionId?.toString();
      final subjectId = rawSubjectId?.toString();

      if (visionId == null || visionId.isEmpty) {
        debugPrint('❌ Vision ID is missing.');
        hideNotificationLoader(context);
        Fluttertoast.showToast(msg: "Vision ID is missing");
        return;
      }

      if (subjectId == null || subjectId.isEmpty) {
        debugPrint('⚠️ Subject ID is empty. Trying all levels...');
        for (int level = 1; level <= 4; level++) {
          debugPrint('🔄 Trying level $level...');
          await visionProvider.initWithSubject('', level.toString());
          video = visionProvider.getVideoById(visionId);
          if (video != null) {
            debugPrint('✅ Video found at level $level: ${video.title}');
            break;
          }
        }
      } else {
        debugPrint('🔄 Trying levels with subjectId: $subjectId');
        for (int level = 1; level <= 4; level++) {
          debugPrint(
              '🔄 Fetching videos for subjectId: $subjectId, level: $level');
          await visionProvider.initWithSubject(subjectId, level.toString());
          video = visionProvider.getVideoById(visionId);
          if (video != null) {
            debugPrint('✅ Video found at level $level: ${video.title}');
            break;
          }
        }
      }
      final String title = video?.title ?? 'Vision';
      debugPrint('📌 Final video title to show in dialog: $title');
      debugPrint("🪙 Coin points: ${video?.visionTextImagePoints}");

      if (!context.mounted) {
        debugPrint('🚫 Context is not mounted. Aborting.');
        return;
      }

      hideNotificationLoader(context); // Close loader

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(22),
              width: MediaQuery.of(context).size.width * 0.2,
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
                    '$title',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  isApproved
                      ? RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87),
                      children: [
                        const TextSpan(
                            text:
                            'Brilliant work—your vision has been approved and '),
                        TextSpan(
                          text: '${video!.visionTextImagePoints} coins',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const TextSpan(
                            text:
                            ' have been added to your treasure chest. On to the next adventure!'),
                      ],
                    ),
                  )
                      : RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 16, color: Colors.black87),
                      children: [
                        TextSpan(
                            text:
                            'No worries—every pro started right where you are! Tap Redo to give it another go and earn '),
                        TextSpan(
                          text: '+25 coins',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        TextSpan(
                            text:
                            ' when you succeed.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isApproved && (video?.visionTextImagePoints ?? 0) > 0) ...[
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  if (video != null) ...[
                    Text(
                      "Subject: ${video.subjectName ?? ''}",
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Level: ${video.levelId ?? 'N/A'}",
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (video != null) {
                            debugPrint(
                                '🚀 Navigating to VideoPlayerPage with video ID: ${video.id}');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChangeNotifierProvider.value(
                                      value: visionProvider,
                                      child: VideoPlayerPage(
                                        video: video!,
                                        navName: "Notification",
                                        subjectId: subjectId ?? '',
                                        onVideoCompleted: () {},
                                      ),
                                    ),
                              ),
                            );
                          } else {
                            Fluttertoast.showToast(msg: "Video not found");
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: Text(
                            isApproved ? "Go to Vision" : "Redo",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (video != null) {
                            MixpanelService.track(
                              isApproved
                                  ? 'Vision Approved Notification Clicked'
                                  : 'Vision Rejected Notification Clicked',
                              properties: {
                                'video_id': video.id,
                                'title': video.title,
                                'subject': video.subjectName,
                              },
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: Text(
                            "Done",
                            style: TextStyle(
                                fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error loading vision details");
      debugPrint('Error in showVisionStatusDialog: $e');
    }
  }

  static Future<void> _handleMissionAssigned(
      BuildContext context, NotificationData notification) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showNotificationLoader(context);

    try {
      MixpanelService.track('Mission Assigned Notification Clicked');

      if (notification.data?.data?.laLevelId != null &&
          notification.data?.data?.laSubjectId != null &&
          notification.data?.data?.missionId != null) {
        // Prepare API request
        Map<String, dynamic> missionData = {
          "type": 1,
          "la_subject_id": notification.data!.data!.laSubjectId.toString(),
          "la_level_id": notification.data!.data!.laLevelId.toString(),
        };

        // Fetch all missions for subject + level
        final provider =
        Provider.of<SubjectLevelProvider>(context, listen: false);
        await provider.getMission(missionData);

        hideNotificationLoader(context); // close loader

        // Find the exact mission by ID
        final mission = provider.missionListModel?.data?.missions?.data
            ?.firstWhere(
              (m) => m.id == notification.data!.data!.missionId,
        );

        if (mission != null) {
          // ✅ Open mission directly like GetStartedMissionWidget
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SubmitMissionPage(mission: mission),
            ),
          );
        } else {
          Fluttertoast.showToast(msg: "Mission not found");
        }
      } else {
        hideNotificationLoader(context);
        Fluttertoast.showToast(msg: "Mission data is incomplete");
      }
    } catch (e) {
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error loading mission");
      debugPrint('Error in _handleMissionAssigned: $e');
    }
  }

  static Future<void> _handleVisionVideo(
      BuildContext context, NotificationData notification) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showNotificationLoader(context);

    try {
      final rawVisionId = notification.data?.data?.visionId;
      final rawSubjectId = notification.data?.data?.laSubjectId;
      final rawActionId = notification.data?.data?.actionId;

      debugPrint('🔍 Raw visionId: $rawVisionId');
      debugPrint('🔍 Raw subjectId: $rawSubjectId');
      debugPrint('🔍 Raw actionId: $rawActionId');

      final visionId = (rawVisionId is String && rawVisionId.trim().isNotEmpty)
          ? rawVisionId.trim()
          : (rawVisionId?.toString().trim().isNotEmpty == true
          ? rawVisionId.toString().trim()
          : (rawActionId != null ? rawActionId.toString() : null));

      final subjectId =
      (rawSubjectId is String && rawSubjectId.trim().isNotEmpty)
          ? rawSubjectId.trim()
          : (rawSubjectId?.toString().trim().isNotEmpty == true
          ? rawSubjectId.toString().trim()
          : null);
      debugPrint('✅ Parsed visionId: $visionId');
      debugPrint('✅ Parsed subjectId: $subjectId');
      if (visionId == null || visionId.isEmpty) {
        hideNotificationLoader(context);
        Fluttertoast.showToast(msg: "Vision ID is missing");
        debugPrint('❌ Vision ID missing, aborting.');
        return;
      }

      final visionProvider =
      Provider.of<VisionProvider>(context, listen: false);
      VisionVideo? video;

      if (subjectId == null) {
        debugPrint(
            '⚠️ Subject ID is null, fetching videos without subject filtering');
        for (int level = 1; level <= 4; level++) {
          await visionProvider.initWithSubject('', level.toString());
          video = visionProvider.getVideoById(visionId);
          if (video != null) {
            debugPrint('🎯 Video found at level $level: ${video.title}');
            break;
          }
        }
      } else {
        for (int level = 1; level <= 4; level++) {
          debugPrint(
              '🔄 Fetching videos for subjectId: $subjectId, level: $level');
          await visionProvider.initWithSubject(subjectId, level.toString());

          video = visionProvider.getVideoById(visionId);
          if (video != null) {
            debugPrint('🎯 Video found at level $level: ${video.title}');
            break;
          }
        }
      }

      if (video == null) {
        hideNotificationLoader(context);
        Fluttertoast.showToast(msg: "Video not found for vision");
        debugPrint('❌ Video not found for visionId: $visionId');
        return;
      }

      hideNotificationLoader(context); // Close loader

      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: visionProvider,
            child: VideoPlayerPage(
              video: video!,
              navName: "Notification",
              subjectId: rawSubjectId?.toString() ?? '',
              onVideoCompleted: () {},
            ),
          ),
        ),
      );
    } catch (e, stacktrace) {
      hideNotificationLoader(context);
      debugPrint('❌ Error opening video: $e');
      debugPrint('$stacktrace');
      Fluttertoast.showToast(msg: "Error opening video");
    }
  }

  static Future<void> _handleQuizNotification(
      BuildContext context, NotificationData notification)
  async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showNotificationLoader(context);

    try {
      final quizId = notification.data!.data!.actionId!.toString();
      debugPrint("Quiz ID: $quizId");
      Response response = await QueServices().quizReviewData(id: quizId);

      hideNotificationLoader(context); // Close loader

      if (response.statusCode == 200) {
        QuizReviewModel model = QuizReviewModel.fromJson(response.data);
        if (model.quizGame!.status == 3) {
          Fluttertoast.showToast(msg: "Quiz already completed");
        } else if (model.quizGame!.status == 4) {
          Fluttertoast.showToast(msg: "Quiz has been expired");
        } else if (model.quizGame!.gameParticipantStatus == 3) {
          Fluttertoast.showToast(msg: "You have rejected Quiz");
        } else if (model.quizGame!.status == 1) {
          // TODO: Implement waiting screen if needed
        } else if (model.quizGame!.status == 2) {
          Fluttertoast.showToast(msg: "You have left the quiz");
        } else {
          Fluttertoast.showToast(msg: "Quiz has been expired");
        }
      }
    } catch (e) {
      hideNotificationLoader(context);
      Fluttertoast.showToast(msg: "Error loading quiz details");
      debugPrint('Error in getQuizAnswer: $e');
    }
  }
}

void showNotificationLoader(BuildContext context, {String? message}) {
  final displayMessage = message ?? 'Please wait while we open this notification';

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Loading',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) {
      return WillPopScope(
        onWillPop: () async => false,
        child: SafeArea(
          child: Stack(
            children: [
              // blurred backdrop
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                  child: Container(color: Colors.black54.withOpacity(0.2)),
                ),
              ),

              // centered card
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular capsule with spinner
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Loading notification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        displayMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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