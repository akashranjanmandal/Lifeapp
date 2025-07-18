import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
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
import '../../../student_progress/presentations/pages/students_progress_page.dart';
import '../../../teacher_dashboard/presentations/widgets/teacher_drawer.dart';
import '../../../teacher_dashboard/presentations/widgets/teacher_home_app_bar.dart';
import '../../../teacher_tool/presentations/pages/teacher_class_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _selectedIdx = 0;

  final List<Widget> _tabs = [
    const _DashboardBody(),
    const TeacherClassPage(),
    ChangeNotifierProvider(
      create: (_) => ProductProvider(
        ProductService(StorageUtil.getString('auth_token')),
      )..loadProducts(),
      child: const ProductList(),
    ),
    ChangeNotifierProvider(
      create: (_) => LeaderboardProvider(StorageUtil.getString('auth_token'))..loadTeacherLeaderboard(),
      child: const TeacherLeaderboardScreen(),
    ),

    // const notification(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeacherDashboardProvider>(context, listen: false).getDashboardData();
      Provider.of<TeacherDashboardProvider>(context, listen: false).getSubjectsData();
      Provider.of<DashboardProvider>(context, listen: false).checkSubscription();
      Provider.of<DashboardProvider>(context, listen: false).storeToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const TeacherDrawerView(), // Single drawer/sidebar
      body: _tabs[_selectedIdx],
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  Widget _buildBottomNav() {
    return Container(
      height: 100, // Slightly taller to accommodate two-line text
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
        crossAxisAlignment: CrossAxisAlignment.start,  // Align children at top
        children: [
          _buildNavItem('assets/images/home_icon.png', 'Home', 0),
          _buildNavItem('assets/images/tracker_icon.png', 'Tracker', 1),
          _buildNavItem('assets/images/connect_icon.png', 'PBL', 2),
          _buildNavItem('assets/images/shop_icon.png', 'Shop', 3),
          _buildNavItem('assets/images/tracker_icon.png', 'Leaderboard', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {
    final bool isSelected = _selectedIdx == index;

    return InkWell(
      onTap: () => setState(() => _selectedIdx = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        width: 60, // fixed width to keep icons aligned
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon centered horizontally
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: isSelected ? const Color(0xFF6574F9) : Colors.grey,
            ),
            const SizedBox(height: 6),
            // Text aligned start but container takes full width to keep alignment consistent
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFF6574F9) : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),
          ],
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
    final userImg = user.profileImage != null
        ? user.profileImage!
        : null;

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
              isSubscribe: StorageUtil.getBool(StringHelper.isTeacherLifeLabDemo),
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
          children: [
            TeacherResourceWidget(
              name: StringHelper.lifeLabActivitiesPlan,
              img: ImageHelper.lessonPlanIcon,
              isSubscribe: StorageUtil.getBool(StringHelper.isTeacherLesson),
            ),
          ],
        ),
      ],
    );
  }
}