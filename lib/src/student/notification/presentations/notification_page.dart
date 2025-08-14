import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/student/notification/services/notification_services.dart';
import 'package:lifelab3/src/student/questions/services/que_services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../student/vision/providers/vision_provider.dart';
import '../../vision/models/vision_video.dart';
import '../../vision/presentations/video_player.dart';
import '../../../common/widgets/common_navigator.dart';
import '../../home/provider/dashboard_provider.dart';
import '../../mission/presentations/pages/mission_page.dart';
import '../../nav_bar/presentations/pages/nav_bar_page.dart';
import '../../questions/models/quiz_review_model.dart';
import '../../subject_level_list/provider/subject_level_provider.dart';
import '../model/notification_model.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  NotificationModel? notificationModel;
  bool isLoading = true;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    MixpanelService.track('Notification Screen Viewed');
    getNotificationData();
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime);
    MixpanelService.track('Notification Screen Time Spent', properties: {
      'duration_seconds': duration.inSeconds,
    });
    super.dispose();
  }

  Future<void> getNotificationData() async {
    try {
      final response = await NotificationServices().getNotification();
      debugPrint('Notification Response: $response');
      notificationModel = NotificationModel.fromJson(response.data);
      await NotificationServices().clearNotification();
      if (mounted) {
        Provider.of<DashboardProvider>(context, listen: false).getDashboardData();
      }
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      Fluttertoast.showToast(msg: "Failed to load notifications");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showGiftCouponDialog(BuildContext context, String message) {
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

  Future<void> showVisionStatusDialog(
      BuildContext context, String status, NotificationData notification) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NotificationLoader(),
    );

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
        navigator.pop();
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

      if (!mounted) {
        debugPrint('🚫 Context is not mounted. Aborting.');
        return;
      }

      navigator.pop(); // Close loader

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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationPage(),
                            ),
                          );
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
      navigator.pop();
      Fluttertoast.showToast(msg: "Error loading vision details");
      debugPrint('Error in showVisionStatusDialog: $e');
    }
  }

  Future<void> _handleMissionAssigned(
      BuildContext context, NotificationData notification) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NotificationLoader(),
    );

    try {
      MixpanelService.track('Mission Assigned Notification Clicked');
      if (notification.data!.data!.laLevelId != null &&
          notification.data!.data!.laSubjectId != null) {
        Map<String, dynamic> missionData = {
          "type": 1,
          "la_subject_id":
          notification.data!.data!.laSubjectId.toString(),
          "la_level_id":
          notification.data!.data!.laLevelId.toString(),
        };

        await Provider.of<SubjectLevelProvider>(context, listen: false)
            .getMission(missionData);

        navigator.pop(); // Close loader
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MissionPage(
              missionListModel:
              Provider.of<SubjectLevelProvider>(context, listen: false)
                  .missionListModel!,
              subjectId: notification.data!.data!.laSubjectId.toString(),
              levelId: notification.data!.data!.laLevelId.toString(),
            ),
          ),
        );
      } else {
        navigator.pop();
        Fluttertoast.showToast(msg: "Mission data is incomplete");
      }
    } catch (e) {
      navigator.pop();
      Fluttertoast.showToast(msg: "Error loading mission");
      debugPrint('Error in _handleMissionAssigned: $e');
    }
  }

  Future<void> getQuizAnswer(
      BuildContext context, String quizId, int index) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NotificationLoader(),
    );

    try {
      debugPrint("Quiz ID: $quizId");
      Response response = await QueServices().quizReviewData(id: quizId);

      navigator.pop(); // Close loader

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
      navigator.pop();
      Fluttertoast.showToast(msg: "Error loading quiz details");
      debugPrint('Error in getQuizAnswer: $e');
    }
  }

  Future<void> _handleVisionVideo(
      BuildContext context, NotificationData notification) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NotificationLoader(),
    );

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
        navigator.pop();
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
        navigator.pop();
        Fluttertoast.showToast(msg: "Video not found for vision");
        debugPrint('❌ Video not found for visionId: $visionId');
        return;
      }

      navigator.pop(); // Close loader

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
      navigator.pop();
      debugPrint('❌ Error opening video: $e');
      debugPrint('$stacktrace');
      Fluttertoast.showToast(msg: "Error opening video");
    }
  }

  Widget _buildButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _getActionButton(
      BuildContext context, NotificationData notification, int index) {
    final message = notification.data?.message ?? '';
    final title = notification.data?.title ?? '';
    final action = notification.data?.data?.action?.toString() ?? '';
    final type = notification.type ?? '';

    final lowerMessage = message.toLowerCase();
    final hasLink = RegExp(r'https?:\/\/[^\s]+').hasMatch(message);

    if (type.contains('AdminMessageNotification')) {
      if (lowerMessage.contains('gift coupon') && hasLink) {
        return _buildButton(context, 'View', () {
          showGiftCouponDialog(context, message);
        });
      } else if (lowerMessage.contains('lifeapp update') ||
          lowerMessage.contains('new update has been rolled out')) {
        return _buildButton(context, 'View', () {
          showGiftCouponDialog(context, message);
        });
      } else {
        return _buildButton(context, 'View', () {
          showGiftCouponDialog(context, message);
        });
      }
    }

    if (lowerMessage.contains('vision has been approved')) {
      return _buildButton(context, 'View', () {
        showVisionStatusDialog(context, 'approved', notification);
      });
    } else if (lowerMessage.contains('vision has been rejected')) {
      return _buildButton(context, 'View', () {
        showVisionStatusDialog(context, 'rejected', notification);
      });
    } else if (lowerMessage.contains('mission have been rejected')) {
      return _buildButton(context, 'View', () {
        MixpanelService.track('Mission Rejected Notification Clicked');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mission has been rejected"),
            duration: Duration(seconds: 2),
          ),
        );
      });
    } else if (lowerMessage.contains('mission has been approved')) {
      return _buildButton(context, 'View', () {
        Fluttertoast.showToast(msg: "Mission has been approved");
        MixpanelService.track('Mission Approved Notification Clicked');
        _handleMissionAssigned(context, notification);
      });
    } else if (lowerMessage
        .contains('teacher have assigned you a mission')) {
      return _buildButton(context, 'View',
              () => _handleMissionAssigned(context, notification));
    } else if (lowerMessage
        .contains('a new vision has been assigned to you')) {
      MixpanelService.track('Vision Assigned Notification Clicked');
      return _buildButton(context, 'View',
              () => _handleVisionVideo(context, notification));
    } else if (action == '6') {
      return _buildButton(context, 'View', () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NavBarPage(currentIndex: 2),
          ),
        );
      });
    } else if (action == '3' &&
        notification.data?.data?.actionId != null &&
        notification.data?.data?.time != null) {
      return _buildButton(context, 'View', () {
        getQuizAnswer(
            context, notification.data!.data!.actionId!.toString(), index);
      });
    }

    return const SizedBox.shrink();
  }

  Widget _notificationWidget() => ListView.separated(
    shrinkWrap: true,
    padding: const EdgeInsets.only(bottom: 50),
    itemCount: notificationModel!.data!.length,
    itemBuilder: (context, index) {
      final notification = notificationModel!.data![index];
      final title = notification.data?.title ?? '';
      final message = notification.data?.message ?? '';
      final createdAt = notification.createdAt ?? '';

      DateTime? date;
      try {
        date = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }

      String formattedDate = '';
      String formattedTime = '';
      if (date != null) {
        formattedDate =
        '${date.day} ${_getMonthName(date.month)} ${date.year}';
        formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
      }

      final isAdminMessage = (notification.type ?? '')
          .contains('AdminMessageNotification');

      return InkWell(
        onTap: () {
          if (isAdminMessage) {
            showGiftCouponDialog(context, message);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
          BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
          )],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate, $formattedTime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  if (!isAdminMessage) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _getActionButton(context, notification, index),
          ],
        ),
      ),
      );
    },
    separatorBuilder: (context, index) => const SizedBox(height: 8),
  );

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _emptyData() => SizedBox(
    height: MediaQuery.of(context).size.height,
    child: const Center(
      child: Text(
        "No data available",
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: "Notification",
        onBack: () => push(context: context, page: const NavBarPage(currentIndex: 0)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationModel != null && notificationModel!.data!.isNotEmpty
          ? _notificationWidget()
          : _emptyData(),
    );
  }
}

class _NotificationLoader extends StatelessWidget {
  const _NotificationLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}