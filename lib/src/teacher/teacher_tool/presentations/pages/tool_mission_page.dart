import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/student/mission/models/mission_details_model.dart' as details;
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/assign_mission_page.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';

import '../../../../common/widgets/common_navigator.dart';
import '../../../student_progress/presentations/pages/student_submission_page.dart';
import '../../../student_progress/provider/student_progress_provider.dart';

class ToolMissionPage extends StatefulWidget {
  final String projectName;
  final String classId;
  final String? subjectId;
  final String gradeId;
  final String sectionId;
  final String? levelId;

  const ToolMissionPage({
    super.key,
    required this.projectName,
    required this.classId,
    this.subjectId,
    required this.gradeId,
    required this.sectionId,
    this.levelId,
  });

  @override
  State<ToolMissionPage> createState() => _ToolMissionPageState();
}

class _ToolMissionPageState extends State<ToolMissionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAssignedMissions = false;
  String? selectedLevel;
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    selectedLevel = widget.levelId;
    selectedSubject = widget.subjectId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchMissions();
      Provider.of<ToolProvider>(context, listen: false).getLevel();
      Provider.of<ToolProvider>(context, listen: false).getSubjectsData();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void fetchMissions() {
    final toolProvider = Provider.of<ToolProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProgressProvider>(context, listen: false);

    // Fetch all missions
    toolProvider.getMission({
      "type": 1,
      "la_subject_id": selectedSubject ?? '',
      "la_level_id": selectedLevel ?? '',
    });

    // Fetch assigned missions if toggle active
    if (_showAssignedMissions) {
      studentProvider.getTeacherMission({
        "type": 1,
        "la_subject_id": selectedSubject ?? '',
        "la_level_id": selectedLevel ?? '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolProvider = Provider.of<ToolProvider>(context);
    final studentProvider = Provider.of<StudentProgressProvider>(context);

    return Scaffold(
      appBar: commonAppBar(context: context, name: widget.projectName),
      body: Column(
        children: [
          Padding (
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Buttons (pill style)
                Row(
                  children: [
                    _toggleButton("All Missions", !_showAssignedMissions, () {
                      setState(() => _showAssignedMissions = false);
                      fetchMissions();
                      MixpanelService.track("MissionListingScreen_AllMissionsClicked");
                    }),
                    const SizedBox(width: 12),
                    _toggleButton("Track Assigned", _showAssignedMissions, () {
                      setState(() => _showAssignedMissions = true);
                      fetchMissions();
                      MixpanelService.track("MissionListingScreen_TrackAssignedClicked");
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Dropdown Filters Row
                Row(
                  children: [
                    Expanded(
                      child: _chipDropdown(
                        label: "Subject", // 👈 fixed name
                        value: selectedSubject,
                        items: toolProvider.subjectModel?.data?.subject,
                        onChanged: (v) {
                          setState(() => selectedSubject = v);
                          fetchMissions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _chipDropdown(
                        label: "Level", // 👈 fixed name
                        value: selectedLevel,
                        items: toolProvider.level?.data?.laLevels,
                        onChanged: (v) {
                          setState(() => selectedLevel = v);
                          fetchMissions();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showAssignedMissions
                ? _trackAssignedMissions(studentProvider)
                : toolProvider.missionListModel != null
                ? _allMissions(toolProvider)
                : const LoadingWidget(),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipDropdown({
    required String label, // 👈 fixed name (Subject / Level / Chapter)
    required String? value,
    required List<dynamic>? items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(label), // 👈 always shows the predefined name
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            const DropdownMenuItem(value: null, child: Text("All")),
            if (items != null)
              ...items.map((item) {
                return DropdownMenuItem(
                  value: item?.id?.toString(),
                  child: Text(item?.title ?? ""),
                );
              }).toList(),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _allMissions(ToolProvider provider) {
    final missions = provider.missionListModel?.data?.missions?.data ?? [];
    final filtered = missions.where((m) {
      final title = m.title?.toLowerCase() ?? '';
      final desc = m.description?.toLowerCase() ?? '';
      return title.contains(_searchQuery) || desc.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const Center(child: Text('No missions found'));

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final m = filtered[i];
        return _missionCard(
          title: m.title ?? '',
          description: m.description,
          imageUrl: m.image?.url,
          assignTap: () => push(
            context: context,
            page: AssignMissionPage(
              img: m.image?.url ?? '',
              resources: (m.resources ?? []).map<details.Resource>((res) {
                return details.Resource(media: res.media != null ? details.En(url: res.media!.url) : null);
              }).toList(),
              missionId: m.id!.toString(),
              subjectId: widget.subjectId.toString(),
              gradeId: widget.gradeId,
              sectionId: widget.sectionId,
              type: '1',
            ),
          ),
        );
      },
    );
  }

  Widget _trackAssignedMissions(StudentProgressProvider provider) {
    final missions = provider.teacherMissionListModel?.data?.missions?.data ?? [];
    final filtered = missions.where((m) {
      final title = m.title?.toLowerCase() ?? '';
      final desc = m.description?.toLowerCase() ?? '';
      return title.contains(_searchQuery) || desc.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const Center(child: Text('No assigned missions found'));

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final m = filtered[i];
        return _missionCard(
          title: m.title ?? '',
          description: m.description,
          imageUrl: m.image?.url,
          reviewTap: () => push(
            context: context,
            page: StudentSubmissionPage(missionId: m.id.toString()),
          ),
        );
      },
    );
  }

  Widget _missionCard({
    required String title,
    String? description,
    String? imageUrl,
    VoidCallback? assignTap,
    VoidCallback? reviewTap,
  }) {
    return InkWell(
      onTap: assignTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(ApiHelper.imgBaseUrl + imageUrl, width: double.infinity, height: 180, fit: BoxFit.cover)
                  : Container(width: double.infinity, height: 180, color: Colors.grey, child: const Icon(Icons.image, color: Colors.white, size: 50)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (reviewTap != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: reviewTap,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
                          child: const Text('Review', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
