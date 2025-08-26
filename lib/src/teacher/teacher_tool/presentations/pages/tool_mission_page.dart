import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/assign_mission_page.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:provider/provider.dart';

import '../../../../common/helper/color_code.dart';
import '../../../../common/widgets/loading_widget.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

import '../../../student_progress/provider/student_progress_provider.dart';

class ToolMissionPage extends StatefulWidget {
  final String projectName;
  final String classId;
  final String subjectId;
  final String gradeId;
  final String sectionId;
  final String levelId;

  const ToolMissionPage(
      {super.key,
        required this.projectName,
        required this.classId,
        required this.subjectId,
        required this.gradeId,
        required this.sectionId,
        required this.levelId});

  @override
  State<ToolMissionPage> createState() => _ToolMissionPageState();
}

class _ToolMissionPageState extends State<ToolMissionPage> {
  late DateTime _startTime;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAssignedMissions = false; // Toggle state

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.projectName == "Mission") {
        Map<String, dynamic> data = {
          "type": 1,
          "la_subject_id": widget.subjectId,
          "la_level_id": widget.levelId,
        };
        Provider.of<ToolProvider>(context, listen: false).getMission(data);
        Provider.of<StudentProgressProvider>(context, listen: false).getTeacherMission();
      } else if (widget.projectName == "Quiz") {
        Provider.of<ToolProvider>(context, listen: false).getTopic("2");
      } else if (widget.projectName == "Riddle") {
        Provider.of<ToolProvider>(context, listen: false).getTopic("3");
      } else if (widget.projectName == "Puzzle") {
        Provider.of<ToolProvider>(context, listen: false).getTopic("4");
      }
      MixpanelService.track("MissionListingScreen_View", properties: {
        "project_name": widget.projectName,
        "class_id": widget.classId,
        "subject_id": widget.subjectId,
        "grade_id": widget.gradeId,
        "section_id": widget.sectionId,
        "level_id": widget.levelId,
      });
    });
    super.initState();
    _startTime = DateTime.now();

    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;

    // Track time spent on the page
    MixpanelService.track("MissionListingScreen_ActivityTime", properties: {
      "duration_seconds": duration,
      "project_name": widget.projectName,
      "class_id": widget.classId,
      "subject_id": widget.subjectId,
      "grade_id": widget.gradeId,
      "section_id": widget.sectionId,
      "level_id": widget.levelId,
    });

    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Track back icon clicked
    MixpanelService.track("MissionListingScreen_BackIconClicked", properties: {
      "project_name": widget.projectName,
      "class_id": widget.classId,
      "subject_id": widget.subjectId,
      "grade_id": widget.gradeId,
      "section_id": widget.sectionId,
      "level_id": widget.levelId,
    });
    return true; // allow pop
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToolProvider>(context);
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: widget.projectName,
      ),
      body: Column(
        children: [
          // Search and Toggle Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Toggle Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAssignedMissions = false;
                          });
                          MixpanelService.track("MissionListingScreen_AllMissionsClicked");
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showAssignedMissions ? Colors.white : Colors.blue, // selected blue
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue, width: 1), // border blue
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'All Missions',
                            style: TextStyle(
                              color: _showAssignedMissions ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAssignedMissions = true;
                          });
                          MixpanelService.track("MissionListingScreen_TrackAssignedClicked");
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showAssignedMissions ? Colors.blue : Colors.white, // selected blue
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue, width: 1), // border blue
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Track Assigned',
                            style: TextStyle(
                              color: _showAssignedMissions ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: _showAssignedMissions
                ? _trackAssignedMissions() // Show track assigned missions
                : widget.projectName == "Mission" && provider.missionListModel != null
                ? _mission(provider)
                : provider.topicModel != null
                ? _topic(provider)
                : const LoadingWidget(),
          ),
        ],
      ),
    );
  }

  // Dummy UI for Track Assigned Missions
  Widget _trackAssignedMissions() {
    final provider = Provider.of<StudentProgressProvider>(context);

    // Use teacher-assigned mission list
    final assignedMissions = provider.teacherMissionListModel?.data?.missions?.data ?? [];

    // Filter based on search query
    final filteredMissions = assignedMissions.where((mission) {
      final title = (mission.title ?? '').toLowerCase();
      final description = (mission.description ?? '').toLowerCase();
      return title.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList();

    if (filteredMissions.isEmpty) {
      return const Center(
        child: Text(
          'No assigned missions found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: filteredMissions.length,
      itemBuilder: (context, index) {
        final mission = filteredMissions[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left image
              if (mission.image?.url != null && mission.image!.url!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Image.network(
                    ApiHelper.imgBaseUrl + mission.image!.url!,
                    width: 120,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 120,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.image, color: Colors.white),
                ),

              // Right side content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Review button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mission.title ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Review',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mission.description ?? 'No Description',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mission(ToolProvider provider) {
    // Filter missions based on search query
    final filteredMissions = provider.missionListModel!.data!.missions!.data!
        .where((mission) =>
    mission.title!.toLowerCase().contains(_searchQuery) ||
        (mission.description != null &&
            mission.description!.toLowerCase().contains(_searchQuery)))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 0, bottom: 20),
      itemCount: filteredMissions.length,
      itemBuilder: (context, index) {
        final mission = filteredMissions[index];

        return InkWell(
          onTap: () {
            MixpanelService.track("MissionListingScreen_MissionClicked",
                properties: {
                  "mission_id": mission.id.toString(),
                  "mission_title": mission.status ?? "",
                  "project_name": widget.projectName,
                });
            push(
              context: context,
              page: AssignMissionPage(
                img: ApiHelper.imgBaseUrl + (mission.image?.url ?? ''),
                missionId: mission.id!.toString(),
                subjectId: widget.subjectId,
                gradeId: widget.gradeId,
                sectionId: widget.sectionId,
                type: "1",
              ),
            );
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        ApiHelper.imgBaseUrl + mission.image!.url!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mission.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Assign button on top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Assign",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _topic(ToolProvider provider) {
    // Filter topics based on search query - only using title since description doesn't exist
    final filteredTopics = provider.topicModel!.data!.laTopics!
        .where((topic) =>
        topic.title!.toLowerCase().contains(_searchQuery))
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: filteredTopics.length,
      itemBuilder: (context, index) {
        final topic = filteredTopics[index];

        return InkWell(
          onTap: () {
            MixpanelService.track("MissionListingScreen_MissionClicked",
                properties: {
                  "mission_id": topic.id.toString(),
                  "mission_title": topic.title ?? "",
                  "project_name": widget.projectName,
                });
            push(
              context: context,
              page: AssignMissionPage(
                img: topic.image!.url!,
                missionId: topic.id!.toString(),
                subjectId: widget.subjectId,
                gradeId: widget.gradeId,
                sectionId: widget.sectionId,
                type: widget.projectName == "Mission"
                    ? "1"
                    : widget.projectName == "Quiz"
                    ? "2"
                    : widget.projectName == "Riddle"
                    ? "3"
                    : "4",
              ),
            );
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorCode.levelListColor1,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Removed description since it doesn't exist in LaTopic
              ],
            ),
          ),
        );
      },
    );
  }
}