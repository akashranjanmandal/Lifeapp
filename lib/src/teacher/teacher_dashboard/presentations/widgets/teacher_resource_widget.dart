import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/student/home/presentations/pages/subscribe_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/cartoon_header_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/lesson_plan_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_subject_page.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

import '../../../../common/helper/color_code.dart';
import '../../../../common/helper/string_helper.dart';
import '../pages/pbl_mapping.dart';

class TeacherResourceWidget extends StatelessWidget {
  final String name;
  final String img;
  final bool isSubscribe;
  final bool isLoading;

  const TeacherResourceWidget({
    super.key,
    required this.name,
    required this.img,
    required this.isSubscribe,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // If loading, show loading state
    if (isLoading) {
      return _buildLoadingWidget(context);
    }

    return InkWell(
      onTap: () => _handleResourceTap(context), // Pass context
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.width * .2,
                width: MediaQuery.of(context).size.width * .2,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSubscribe ? Colors.black54 : Colors.grey[300]!,
                  ),
                  color: isSubscribe ? Colors.white : Colors.grey[50],
                ),
                child: Center(
                  child: Opacity(
                    opacity: isSubscribe ? 1.0 : 0.5,
                    child: Image.asset(img),
                  ),
                ),
              ),
              if (!isSubscribe && name != StringHelper.conceptCartoons &&
                  name != StringHelper.pblTextBookMapping)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    width: MediaQuery.of(context).size.width * .13,
                    decoration: const BoxDecoration(
                      color: ColorCode.buttonColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        StringHelper.subscribe,
                        style: TextStyle(
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
          const SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width * .2,
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  color: isSubscribe ? Colors.black87 : Colors.grey,
                  fontWeight: isSubscribe ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.width * .2,
          width: MediaQuery.of(context).size.width * .2,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[200],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width * .2,
          child: Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _handleResourceTap(BuildContext context) { // Add context parameter
    // Mixpanel tracking
    MixpanelService.track("Teacher resource clicked", properties: {
      "resource_name": name,
      "is_subscribed": isSubscribe,
      "timestamp": DateTime.now().toIso8601String(),
    });

    // Always accessible resources
    if (name == StringHelper.conceptCartoons) {
      push(
        context: context,
        page: const CartoonHeaderPage(),
      );
    } else if (name == StringHelper.pblTextBookMapping) {
      push(
        context: context,
        page: const PblTextBookMappingPage(),
      );
    }
    // Subject-based resources
    else if (name == StringHelper.competencies ||
        name == StringHelper.assesments ||
        name == StringHelper.worksheet) {
      push(
        context: context,
        page: TeacherSubjectListPage(name: name),
      );
    }
    // Subscription-based resources
    else {
      // Check if subscribed
      if (isSubscribe) {
        _navigateToLessonPlan(context); // Pass context
      } else {
        _navigateToSubscribePage(context); // Pass context
      }
    }
  }

  void _navigateToLessonPlan(BuildContext context) { // Add context parameter
    String? lessonType;

    switch (name) {
      case StringHelper.lifeLabDemoModelLesson:
        lessonType = "1";
        break;
      case StringHelper.jigyasaSelfDiy:
        lessonType = "2";
        break;
      case StringHelper.pragyaDIYActivity:
        lessonType = "3";
        break;
      case StringHelper.lifeLabActivitiesPlan:
        lessonType = "4";
        break;
    }

    if (lessonType != null) {
      push(
        context: context,
        page: LessonPlanPage(type: lessonType),
      );
    }
  }

  void _navigateToSubscribePage(BuildContext context) { // Add context parameter
    String? subscribeType;

    switch (name) {
      case StringHelper.lifeLabDemoModelLesson:
        subscribeType = "1";
        break;
      case StringHelper.jigyasaSelfDiy:
        subscribeType = "2";
        break;
      case StringHelper.pragyaDIYActivity:
        subscribeType = "3";
        break;
      case StringHelper.lifeLabActivitiesPlan:
        subscribeType = "4";
        break;
      default:
        subscribeType = "0";
    }

    push(
      context: context,
      page: SubScribePage(type: subscribeType),
    );
  }
}