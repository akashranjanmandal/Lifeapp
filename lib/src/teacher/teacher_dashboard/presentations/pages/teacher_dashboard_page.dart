import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import '../../../Notifiction/Presentation/notification.dart';
import '../../../Notifiction/Services/services.dart';
import '../../../leaderboard/presentation/teacher_leaderboard.dart';
import 'package:lifelab3/src/student/home/provider/dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/widgets/teacher_resource_widget.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/widgets/teacher_tool_widget.dart';
import '../../../leaderboard/provider/provider.dart';
import '../../../../utils/storage_utils.dart';
import '../../../shop/presentation/product_list.dart';
import '../../../shop/provider/provider.dart';
import '../../../shop/services/services.dart';
import '../../../teacher_dashboard/presentations/widgets/teacher_drawer.dart';
import '../../../teacher_dashboard/presentations/widgets/teacher_home_app_bar.dart';
import '../../../teacher_tool/presentations/pages/teacher_class_page.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
// ADD THIS IMPORT
import 'package:lifelab3/main.dart'; // Import main.dart to access deepLinkManager

import '../../../Notifiction/models/models.dart'; // NotificationModel import

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _selectedIdx = 0;
  int _unreadNotificationCount = 0;
  Timer? _timer;
  bool _hasProcessedDeepLinks = false; // ADD THIS

  Future<void> _loadUnreadNotifications() async {
    final token = StorageUtil.getString(StringHelper.token);
    try {
      final rawNotifications =
      await NotificationService(token).fetchNotifications();

      // Cast the notifications list
      final notifications = rawNotifications.cast<NotificationModel>();

      // Filter unread notifications
      final unreadNotifications =
      notifications.where((n) => n.isUnread).toList();

      // Debug prints
      debugPrint('Total notifications count: ${notifications.length}');
      debugPrint('Unread notifications count: ${unreadNotifications.length}');

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  // ADD THIS METHOD: Process pending deep links after login
  void _processPendingDeepLinks() {
    if (_hasProcessedDeepLinks) return;

    final pendingContentId = deepLinkManager.getPendingDeepLink();
    if (pendingContentId != null && pendingContentId.isNotEmpty) {
      debugPrint('🔄 Teacher Home: Processing pending deep link: $pendingContentId');

      // Wait for the UI to settle
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (deepLinkManager.canUserAccessVideos()) {
          debugPrint('✅ Teacher can access videos, opening deep link');
          deepLinkManager.processPendingDeepLinkAfterLogin();
          _hasProcessedDeepLinks = true;
        } else {
          debugPrint('❌ Teacher cannot access videos');
        }
      });
    } else {
      debugPrint('📭 Teacher Home: No pending deep links');
    }
  }

  List<Widget> get _tabs => [
    const _DashboardBody(),
    TeacherClassPage(
      onBackToHome: () {
        setState(() {
          _selectedIdx = 0;
        });
      },
    ),
    ChangeNotifierProvider(
      create: (_) => ProductProvider(
        ProductService(StorageUtil.getString('auth_token')),
      )..loadProducts(),
      child: const ProductList(),
    ),
    ChangeNotifierProvider(
      create: (_) =>
      LeaderboardProvider(StorageUtil.getString('auth_token'))
        ..loadTeacherLeaderboard(),
      child: const TeacherLeaderboardScreen(),
    ),
    Container(), // Placeholder for NotificationPage, handled via Navigator
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initial unread notifications load
      _loadUnreadNotifications();

      // Start periodic timer to refresh unread notifications every 30 seconds
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _loadUnreadNotifications();
      });

      // Other initialization
      Provider.of<TeacherDashboardProvider>(context, listen: false)
          .getDashboardData();
      Provider.of<DashboardProvider>(context, listen: false)
          .checkSubscription();
      Provider.of<DashboardProvider>(context, listen: false).storeToken();

      // ADD THIS: Process pending deep links when home page loads
      _processPendingDeepLinks();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const TeacherDrawerView(),
      body: _tabs[_selectedIdx],
      bottomNavigationBar: _buildBottomNav(context), // Pass context here
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navItemWidth = screenWidth / 5; // Divide equally among 5 items

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavItem('assets/images/home_icon.png', 'Home', 0, navItemWidth),
          _buildNavItem('assets/images/connect_icon.png', 'PBL', 1, navItemWidth),
          _buildNavItem('assets/images/shop_icon.png', 'Shop', 2, navItemWidth),
          _buildNavItem('assets/images/tracker_icon.png', 'Leaderboard', 3, navItemWidth),
          _buildNavItem(
            'assets/images/notification_icon.png',
            'Notification',
            4,
            navItemWidth,
            showBadge: _unreadNotificationCount > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index, double itemWidth,
      {bool showBadge = false}) {
    final bool isSelected = _selectedIdx == index;

    // Calculate responsive padding based on screen width
    final horizontalPadding = itemWidth > 80 ? 12.0 : 8.0;

    return InkWell(
      onTap: () {
        MixpanelService.track("Dashboard bottom tab clicked", properties: {
          "tab_label": label,
          "tab_index": index,
          "timestamp": DateTime.now().toIso8601String(),
        });

        if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationPage(
                  token: StorageUtil.getString(StringHelper.token)),
            ),
          ).then((_) => _loadUnreadNotifications());
          return;
        }

        setState(() => _selectedIdx = index);
      },
      child: SizedBox(
        width: itemWidth, // Use responsive width
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: horizontalPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: isSelected ? const Color(0xFF6574F9) : Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF6574F9) : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (showBadge)
                Positioned(
                  right: 0,
                  top: -6,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherDashboardProvider>(context);

    if (provider.dashboardModel == null) {
      return const LoadingWidget();
    }

    final user = provider.dashboardModel!.data!.user!;
    final userName = user.name ?? '';
    final userImg = user.imagePath ?? null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            TeacherHomeAppBar(name: userName, img: userImg),
            const SizedBox(height: 20),
            const _TeacherResources(),
            const SizedBox(height: 20),
            const TeacherToolWidget(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class _TeacherResources extends StatelessWidget {
  const _TeacherResources();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          StringHelper.teacherResources,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TeacherResourceWidget(
              name: StringHelper.lifeLabDemoModelLesson,
              img: ImageHelper.demoModelIcon,
              isSubscribe:
              StorageUtil.getBool(StringHelper.isTeacherLifeLabDemo),
            ),
            const TeacherResourceWidget(
              name: StringHelper.conceptCartoons,
              img: ImageHelper.conceptCartoon,
              isSubscribe: true,
            ),
            TeacherResourceWidget(
              name: StringHelper.jigyasaSelfDiy,
              img: ImageHelper.jigyasaLessonIcon,
              isSubscribe: StorageUtil.getBool(StringHelper.isTeacherJigyasa),
            ),
            TeacherResourceWidget(
              name: StringHelper.pragyaDIYActivity,
              img: ImageHelper.pragyaLessonIcon,
              isSubscribe: StorageUtil.getBool(StringHelper.isTeacherPragya),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TeacherResourceWidget(
              name: StringHelper.lifeLabActivitiesPlan,
              img: ImageHelper.lessonPlanIcon,
              isSubscribe: StorageUtil.getBool(StringHelper.isTeacherLesson),
            ),
            const SizedBox(width: 15),
            TeacherResourceWidget(
              name: StringHelper.pblTextBookMapping,
              img: "assets/images/B2 1.png",
              isSubscribe: true,
            ),
          ],
        ),
      ],
    );
  }
}