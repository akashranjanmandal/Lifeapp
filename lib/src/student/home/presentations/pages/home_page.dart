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
import 'package:lifelab3/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String appUrl = "";
  bool isAppUpdate = false;
  bool _hasProcessedDeepLinks = false;
  bool _isConnected = true;
  bool _isRefreshing = false;
  bool _isInitialLoading = true;

  // Simple internet check
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _retryConnection() async {
    setState(() {
      _isInitialLoading = true;
      _isConnected = true;
    });
    await _loadInitialData();
  }

  // Load initial data with internet check
  Future<void> _loadInitialData() async {
    if (!mounted) return;

    // Check internet first
    final hasInternet = await _checkInternet();
    if (!hasInternet) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isInitialLoading = false;
        });
      }
      return;
    }

    setState(() => _isConnected = true);

    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);

      // Load all data in parallel
      await Future.wait([
        provider.getDashboardData(),
        provider.getTodayCampaigns(),
        provider.getSubjectsData(),
        provider.checkSubscription(),
      ]);

      // Process deep links if any
      _processPendingDeepLinks();

      // Check for app updates
      checkStoreAppVersion();

    } on SocketException catch (_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  // Refresh all data
  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() => _isRefreshing = true);

    // Check internet first
    final hasInternet = await _checkInternet();
    if (!hasInternet) {
      setState(() {
        _isConnected = false;
        _isRefreshing = false;
      });
      return;
    }

    setState(() => _isConnected = true);

    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.getDashboardData();
      provider.getTodayCampaigns();
      provider.getSubjectsData();
      provider.checkSubscription();

      // Process deep links if any
      _processPendingDeepLinks();

    } on SocketException catch (_) {
      setState(() => _isConnected = false);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
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

  void _processPendingDeepLinks() {
    if (_hasProcessedDeepLinks) return;

    final pendingContentId = deepLinkManager.getPendingDeepLink();
    if (pendingContentId != null && pendingContentId.isNotEmpty) {
      debugPrint('🔄 Student Home: Processing pending deep link: $pendingContentId');

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Start loading data immediately
      await _loadInitialData();
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

    // Show loader during initial loading
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show no internet page when no connection
    if (!_isConnected) {
      return Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No Internet Connection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Please check your internet connection and try again',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Show loading if no user data yet
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      drawer: DrawerView(
        coin: user.earnCoins?.toString() ?? "0",
        name: getDisplayName(user.name),
      ),
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          MixpanelService.track('Drawer Closed');
        }
      },
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                HomeAppBar(
                  name: getDisplayName(user.name),
                  img: user.imagePath,
                ),
                const SizedBox(height: 20),

                // Rewards Widget
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
                InviteFriendWidget(
                  name: getDisplayName(user.name),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

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