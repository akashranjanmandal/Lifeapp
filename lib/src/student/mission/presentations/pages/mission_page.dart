import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/student/subject_level_list/models/mission_list_model.dart';
import 'package:provider/provider.dart';
import '../../../subject_level_list/provider/subject_level_provider.dart';
import '../widgets/completed_mission_widget.dart';
import '../widgets/get_started_mission_widget.dart';
import '../widgets/in_review_mission_widget.dart';
import '../widgets/rejected_mission_widget.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

import '../widgets/skipped_mission_widget.dart';

class MissionPage extends StatefulWidget {
  MissionListModel missionListModel;
  final String? subjectId;
  final String? levelId;

  MissionPage({super.key, required this.missionListModel, this.subjectId, this.levelId});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  DateTime? _screenOpenedTime;
  ScrollController scrollController = ScrollController();
  int page = 1;
  bool isLoading = false;

  // search & filter state
  String _searchQuery = "";
  bool _filterAll = true;
  bool _filterSkipped = true;
  bool _filterTeacherAssigned = true;
  bool _filterStart = true;
  bool _filterPending = true;
  bool _filterCompleted = true;
  bool _filterRejected = true;

  @override
  void initState() {
    super.initState();
    _screenOpenedTime = DateTime.now();

    MixpanelService.track("Mission Listing Screen Opened", properties: {
      "subjectId": widget.subjectId,
      "levelId": widget.levelId,
    });

    if (widget.subjectId != null) {
      scrollController.addListener(() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent) {
          page++;
          getData();
        }
      });
    }
  }

  @override
  void dispose() {
    if (_screenOpenedTime != null) {
      final duration = DateTime.now().difference(_screenOpenedTime!);
      MixpanelService.track("Mission Listing Screen Closed", properties: {
        "duration_seconds": duration.inSeconds,
        "subjectId": widget.subjectId,
        "levelId": widget.levelId,
      });
    }
    scrollController.dispose();
    super.dispose();
  }

  getData() async {
    isLoading = true;
    setState(() {});
    await Provider.of<SubjectLevelProvider>(context, listen: false).getMission({
      "type": 1,
      "la_subject_id": widget.subjectId,
      "la_level_id": widget.levelId,
    }, params: '?page=$page');

    (widget.missionListModel.data!.missions!.data ?? []).addAll(
        Provider.of<SubjectLevelProvider>(context, listen: false)
            .missionListModel
            ?.data
            ?.missions
            ?.data ?? []
    );
    isLoading = false;
    setState(() {});
  }

  // Determine mission category
  String _getMissionCategory(MissionDatum m) {
    // Check if mission was skipped
    if (m.status != null && m.status!.trim().toLowerCase() == "skipped") {
      return "skipped";
    }

    // Check submission first
    if (m.submission != null) {
      if (m.submission!.approvedAt != null) return "completed";
      if (m.submission!.rejectedAt != null) return "rejected";
      return "inReview"; // submitted but not approved/rejected
    }

    // Check if teacher assigned
    if (m.assignedBy != null && m.assignedBy!.isNotEmpty) {
      return "teacherAssigned";
    }

    // Status for untouched missions
    if (m.status != null) {
      final status = m.status!.trim().toLowerCase();
      if (status == "start") return "start";
      if (status == "submitted") return "inReview";
      if (status == "skipped") return "skipped";
    }

    return "unknown";
  }

  // Apply search & filters
  List<MissionDatum> get _filteredMissions {
    List<MissionDatum> missions = widget.missionListModel.data?.missions?.data ?? [];

    // Search
    if (_searchQuery.isNotEmpty) {
      missions = missions
          .where((m) =>
          (m.title ?? "").toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filters
    if (!_filterAll) {
      missions = missions.where((m) {
        final category = _getMissionCategory(m);
        if (_filterTeacherAssigned && category == "teacherAssigned") return true;
        if (_filterStart && category == "start") return true;
        if (_filterPending && category == "inReview") return true;
        if (_filterCompleted && category == "completed") return true;
        if (_filterRejected && category == "rejected") return true;
        if (_filterSkipped && category == "skipped") return true;
        return false;
      }).toList();
    }

    return missions;
  }

  Widget _buildMissionWidget(MissionDatum m) {
    switch (_getMissionCategory(m)) {
      case "completed":
        return CompletedMissionWidget(data: m);
      case "inReview":
        return InReviewMissionWidget(data: m);
      case "rejected":
        return RejectedMissionWidget(data: m);
      case "skipped":
        return SkippedMissionWidget(data: m); // <-- new widget
      default:
        return GetStartedMissionWidget(data: m);
    }
  }

  // Open full-screen filter page
  Future<void> _openFilterDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FilterPage(
          filterAll: _filterAll,
          filterTeacherAssigned: _filterTeacherAssigned,
          filterStart: _filterStart,
          filterPending: _filterPending,
          filterCompleted: _filterCompleted,
          filterRejected: _filterRejected,
          filterSkipped: _filterSkipped,
        ),
      ),
    );

    if (result != null && result is Map<String, bool>) {
      setState(() {
        _filterAll = result["all"]!;
        _filterTeacherAssigned = result["teacherAssigned"]!;
        _filterStart = result["start"]!;
        _filterPending = result["pending"]!;
        _filterCompleted = result["completed"]!;
        _filterRejected = result["rejected"]!;
        _filterSkipped = result["skipped"]!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final missions = _filteredMissions;

    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: StringHelper.mission,
      ),
      body: Column(
        children: [
          // Search + Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search missions...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Filter Button
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 28),
                  onPressed: _openFilterDialog,
                ),
              ],
            ),
          ),

          // Missions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (widget.subjectId != null) {
                  (widget.missionListModel.data?.missions?.data ?? []).clear();
                  page = 1;
                  getData();
                }
              },
              child: missions.isNotEmpty
                  ? Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: scrollController,
                      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 50),
                      itemCount: missions.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {},
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: _buildMissionWidget(missions[index]),
                        );
                      },
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 30, top: 10),
                      child: CircularProgressIndicator(),
                    )
                ],
              )
                  : Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                  "No missions found!",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Full-screen Filter Page
class FilterPage extends StatefulWidget {
  final bool filterAll;
  final bool filterTeacherAssigned;
  final bool filterStart;
  final bool filterPending;
  final bool filterCompleted;
  final bool filterRejected;
  final bool filterSkipped;

  const FilterPage({
    super.key,
    required this.filterAll,
    required this.filterTeacherAssigned,
    required this.filterStart,
    required this.filterPending,
    required this.filterCompleted,
    required this.filterRejected,
    required this.filterSkipped,
  });
  @override
  State<FilterPage> createState() => _FilterPageState();
}
class _FilterPageState extends State<FilterPage> {
  late bool all;
  late bool teacherAssigned;
  late bool start;
  late bool pending;
  late bool completed;
  late bool rejected;
  late bool skipped;
  @override
  void initState() {
    super.initState();
    all = widget.filterAll;
    teacherAssigned = widget.filterTeacherAssigned;
    start = widget.filterStart;
    pending = widget.filterPending;
    completed = widget.filterCompleted;
    rejected = widget.filterRejected;
    skipped = widget.filterSkipped;
  }

  void _toggleAll(bool value) {
    setState(() {
      all = value;
      teacherAssigned = start = pending = completed = rejected = skipped = value;
    });
  }

  void _resetFilters() {
    _toggleAll(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Mission Filters", style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Filters",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text("All"),
                  value: all,
                  onChanged: _toggleAll,
                ),
                SwitchListTile(
                  title: const Text("Teachers Assigned"),
                  value: teacherAssigned,
                  onChanged: (val) => setState(() => teacherAssigned = val),
                ),
                SwitchListTile(
                  title: const Text("Start"),
                  value: start,
                  onChanged: (val) => setState(() => start = val),
                ),
                SwitchListTile(
                  title: const Text("Submitted (In Review)"),
                  value: pending,
                  onChanged: (val) => setState(() => pending = val),
                ),
                SwitchListTile(
                  title: const Text("Completed"),
                  value: completed,
                  onChanged: (val) => setState(() => completed = val),
                ),
                SwitchListTile(
                  title: const Text("Rejected"),
                  value: rejected,
                  onChanged: (val) => setState(() => rejected = val),
                ),
                SwitchListTile(
                  title: const Text("Skipped"),
                  value: skipped,
                  onChanged: (val) => setState(() => skipped = val),
                ),

              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text("Reset"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        "all": all,
                        "teacherAssigned": teacherAssigned,
                        "start": start,
                        "pending": pending,
                        "completed": completed,
                        "rejected": rejected,
                        "skipped": skipped,
                      });
                    },
                    child: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
