import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
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
import 'package:lifelab3/main.dart';
import '../../../Notifiction/models/models.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _selectedIdx = 0;
  int _unreadNotificationCount = 0;
  Timer? _timer;
  bool _hasProcessedDeepLinks = false;
  bool _isConnected = true;
  bool _isInitialLoading = true;
  bool _hasCheckedInternet = false; // NEW: Track if we've checked internet

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadUnreadNotifications() async {
    if (!_isConnected) return;

    final token = StorageUtil.getString(StringHelper.token);
    try {
      final rawNotifications =
      await NotificationService(token).fetchNotifications();
      final notifications = rawNotifications.cast<NotificationModel>();
      final unreadNotifications =
      notifications.where((n) => n.isUnread).toList();

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void _processPendingDeepLinks() {
    if (_hasProcessedDeepLinks || !_isConnected) return;

    final pendingContentId = deepLinkManager.getPendingDeepLink();
    if (pendingContentId != null && pendingContentId.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (deepLinkManager.canUserAccessVideos()) {
          deepLinkManager.processPendingDeepLinkAfterLogin();
          _hasProcessedDeepLinks = true;
        }
      });
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    // 1️⃣ Check internet FIRST
    final hasInternet = await _checkInternet();

    // 2️⃣ Sync internet state with Provider (CRITICAL)
    final dashboardProvider =
    Provider.of<TeacherDashboardProvider>(context, listen: false);

    dashboardProvider.setInternetStatus(hasInternet);

    // 3️⃣ Update local UI state
    if (mounted) {
      setState(() {
        _hasCheckedInternet = true;
        _isConnected = hasInternet;
      });
    }

    // 4️⃣ IF NO INTERNET → STOP EVERYTHING HERE
    if (!hasInternet) {
      // 🔥 FORCE provider to EXIT loading state
      dashboardProvider
        ..setInternetStatus(false)
        ..refreshAllData(); // this will safely exit without API

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
      return;
    }

    // 5️⃣ IF INTERNET IS AVAILABLE → NORMAL FLOW
    try {
      await Future.wait([
        _loadUnreadNotifications(),
        dashboardProvider.refreshAllData(),
        Provider.of<DashboardProvider>(context, listen: false)
            .checkSubscription(),
      ]);

      Provider.of<DashboardProvider>(context, listen: false).storeToken();
      _processPendingDeepLinks();
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
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
    Container(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();

      if (_isConnected) {
        _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
          if (_isConnected && mounted) {
            _loadUnreadNotifications();
          }
        });
      }
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
      bottomNavigationBar: _isInitialLoading ? null : _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navItemWidth = screenWidth / 5;

    // Get the bottom padding for devices with navigation bars
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final hasBottomNavigation = bottomPadding > 0;

    return Container(
      padding: EdgeInsets.only(bottom: hasBottomNavigation ? bottomPadding : 0),
      color: Colors.white,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
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
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index, double itemWidth,
      {bool showBadge = false}) {
    final bool isSelected = _selectedIdx == index;

    return Expanded(
      child: InkWell(
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
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Image.asset(
                      iconPath,
                      width: 20,
                      height: 20,
                      color: isSelected ? const Color(0xFF6574F9) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 14,
                    alignment: Alignment.topCenter,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? const Color(0xFF6574F9) : Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              if (showBadge)
                Positioned(
                  right: 10,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
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
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => __DashboardBodyState();
}

class __DashboardBodyState extends State<_DashboardBody> {
  Future<void> _onRefresh() async {
    final parentState = context.findAncestorStateOfType<_TeacherDashboardPageState>();
    if (parentState != null) {
      await parentState._refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherDashboardProvider>(context);
    final parentState = context.findAncestorStateOfType<_TeacherDashboardPageState>();

    // SIMPLE FIX: If no internet, show no internet screen immediately
    if (parentState != null && !parentState._isConnected && parentState._hasCheckedInternet) {
      return _buildNoInternetScreen();
    }

    // Show loading only if we're still checking internet AND loading data
    if (parentState != null && parentState._isInitialLoading && parentState._isConnected) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show provider loading state
    if (provider.isLoadingDashboard &&
        provider.dashboardModel == null &&
        parentState?._isConnected == true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard...'),
          ],
        ),
      );
    }

    // Show provider error state
    if (provider.dashboardError != null && provider.dashboardModel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Show no data state
    if (provider.dashboardModel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                provider.refreshAllData();
              },
              child: const Text('Load Data'),
            ),
          ],
        ),
      );
    }

    // If we have data, show the dashboard
    final user = provider.dashboardModel!.data!.user!;
    final userName = user.name ?? '';
    final userImg = user.imagePath ?? null;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildNoInternetScreen() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
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
    );
  }
}

class _TeacherResources extends StatelessWidget {
  const _TeacherResources();

  @override
  Widget build(BuildContext context) {
    final teacherProvider = Provider.of<TeacherDashboardProvider>(context);

    bool isLifeLabDemo = teacherProvider.dashboardModel != null
        ? teacherProvider.isTeacherLifeLabDemo
        : StorageUtil.getBool(StringHelper.isTeacherLifeLabDemo) ?? false;

    bool isJigyasa = teacherProvider.dashboardModel != null
        ? teacherProvider.isTeacherJigyasa
        : StorageUtil.getBool(StringHelper.isTeacherJigyasa) ?? false;

    bool isPragya = teacherProvider.dashboardModel != null
        ? teacherProvider.isTeacherPragya
        : StorageUtil.getBool(StringHelper.isTeacherPragya) ?? false;

    bool isLesson = teacherProvider.dashboardModel != null
        ? teacherProvider.isTeacherLesson
        : StorageUtil.getBool(StringHelper.isTeacherLesson) ?? false;

    bool isLoading = teacherProvider.dashboardModel == null;

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
              isSubscribe: isLifeLabDemo,
              isLoading: isLoading,
            ),
            TeacherResourceWidget(
              name: StringHelper.conceptCartoons,
              img: ImageHelper.conceptCartoon,
              isSubscribe: true,
            ),
            TeacherResourceWidget(
              name: StringHelper.jigyasaSelfDiy,
              img: ImageHelper.jigyasaLessonIcon,
              isSubscribe: isJigyasa,
              isLoading: isLoading,
            ),
            TeacherResourceWidget(
              name: StringHelper.pragyaDIYActivity,
              img: ImageHelper.pragyaLessonIcon,
              isSubscribe: isPragya,
              isLoading: isLoading,
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
              isSubscribe: isLesson,
              isLoading: isLoading,
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