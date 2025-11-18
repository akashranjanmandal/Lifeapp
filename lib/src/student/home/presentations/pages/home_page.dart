import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lifelab3/src/student/home/provider/dashboard_provider.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../../../common/helper/color_code.dart';
import '../widgets/explore_challenges_widget.dart';
import '../widgets/explore_subjects_widget.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/invire_friend_widget.dart';
import '../widgets/mentor_connect_widget.dart';
import '../widgets/reward_widget.dart';
import '../widgets/campaign_widget.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
// ADD THIS IMPORT
import 'package:lifelab3/main.dart'; // Import main.dart to access deepLinkManager

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String appUrl = "";
  bool isAppUpdate = false;
  bool _hasProcessedDeepLinks = false; // ADD THIS

  void checkStoreAppVersion() async {
    final status = await NewVersionPlus(
      androidId: "com.life.lab",
      iOSId: "com.hejtech.lifelab",
    ).getVersionStatus();

    isAppUpdate = status?.canUpdate ?? false;
    appUrl = status?.appStoreLink ?? "";
    debugPrint("Version: ${status?.canUpdate ?? false}");

    if (isAppUpdate) {
      showMsgDialog();
    }
  }

  /// Helper function to get first name (or first 10 letters if no space)
  String getDisplayName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return "";
    String firstName = fullName.split(" ").first;
    if (firstName.length > 10) {
      firstName = firstName.substring(0, 10);
    }
    return firstName;
  }

  // ADD THIS METHOD: Process pending deep links after login
  void _processPendingDeepLinks() {
    if (_hasProcessedDeepLinks) return;

    final pendingContentId = deepLinkManager.getPendingDeepLink();
    if (pendingContentId != null && pendingContentId.isNotEmpty) {
      debugPrint('🔄 Student Home: Processing pending deep link: $pendingContentId');

      // Wait for the UI to settle
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (deepLinkManager.canUserAccessVideos()) {
          debugPrint('✅ Student can access videos, opening deep link');
          deepLinkManager.processPendingDeepLinkAfterLogin();
          _hasProcessedDeepLinks = true;
        } else {
          debugPrint('❌ Student cannot access videos');
        }
      });
    } else {
      debugPrint('📭 Student Home: No pending deep links');
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkStoreAppVersion();
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.storeToken();
      provider.getDashboardData();
      provider.getTodayCampaigns(); // Fetch campaigns
      provider.getSubjectsData();
      provider.checkSubscription();

      // ADD THIS: Process pending deep links when home page loads
      _processPendingDeepLinks();
    });

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final user = provider.dashboardModel?.data?.user;

    return Scaffold(
      drawer: user != null
          ? DrawerView(
        coin: user.earnCoins?.toString() ?? "0",
        name: getDisplayName(user.name),
      )
          : null,
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          MixpanelService.track('Drawer Closed');
        }
      },
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              if (user != null)
                HomeAppBar(
                  name: getDisplayName(user.name),
                  img: user.imagePath,
                ),
              const SizedBox(height: 20),

              // Rewards Widget
              if (user != null)
                RewardsWidget(
                  coin: user.earnCoins?.toString() ?? "0",
                  friends: user.friends?.toString() ?? "0",
                  ranking: user.userRank?.toString() ?? "0",
                ),
              const SizedBox(height: 20),

              // Campaigns
              if (provider.campaigns.isNotEmpty)
                const CampaignSliderWidget(),
              const SizedBox(height: 20),

              // Subjects
              if (provider.subjectModel != null)
                ExploreSubjectsWidget(
                  subjects: provider.subjectModel!.data!.subject!,
                ),
              const SizedBox(height: 20),

              const ExploreChallengesWidget(),
              const SizedBox(height: 30),

              MentorConnectWidget(),
              const SizedBox(height: 30),

              // Invite Friends
              if (user != null)
                InviteFriendWidget(
                  name: getDisplayName(user.name),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void showMsgDialog() {
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            height: 200,
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "App Update Available",
                    style: TextStyle(
                      color: ColorCode.textBlackColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "A new version of the app is available",
                    style: TextStyle(
                      color: ColorCode.grey,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  InkWell(
                    onTap: () {
                      if (Platform.isAndroid) {
                        launch(appUrl);
                      } else {
                        launchUrl(Uri.parse(appUrl));
                      }
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: ColorCode.buttonColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          "Update",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero);
        return SlideTransition(
          position: tween.animate(anim),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }
}