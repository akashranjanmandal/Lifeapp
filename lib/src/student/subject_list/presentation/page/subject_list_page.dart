import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/student/home/models/subject_model.dart';  // Import Subject model
import 'package:lifelab3/src/student/home/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
import '../widgets/subject_details_widget.dart';

class SubjectListPage extends StatefulWidget {
  final String navName;

  const SubjectListPage({super.key, required this.navName});

  @override
  State<SubjectListPage> createState() => _SubjectListPageState();
}

class _SubjectListPageState extends State<SubjectListPage> {
  late DateTime _startTime;
  TextEditingController _searchController = TextEditingController();
  List<Subject>? filteredSubjects;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    final provider = Provider.of<DashboardProvider>(context, listen: false);
    filteredSubjects = provider.subjectModel?.data?.subject ?? [];

    _searchController.addListener(() {
      filterSubjects();
    });

    MixpanelService.track("Subject Screen Viewed", properties: {
      "navName": widget.navName,
    });
  }

  void filterSubjects() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredSubjects = provider.subjectModel?.data?.subject ?? [];
      });
      return;
    }

    setState(() {
      filteredSubjects = provider.subjectModel?.data?.subject
          ?.where((subject) =>
      (subject.title?.toLowerCase().contains(query) ?? false) ||
          (subject.metatitle?.toLowerCase().contains(query) ?? false))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    final endTime = DateTime.now();
    final timeSpent = endTime.difference(_startTime).inSeconds;

    MixpanelService.track("Subject Screen Time", properties: {
      "timeSpent_seconds": timeSpent,
      "navName": widget.navName,
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        MixpanelService.track("Subject Back Button Clicked", properties: {
          "navName": widget.navName,
        });
        return true;
      },
      child: Scaffold(
        appBar: commonAppBar(context: context, name: StringHelper.subjects),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search subjects...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredSubjects?.length ?? 0,
                itemBuilder: (context, index) => SubjectDetailsWidget(
                  subject: filteredSubjects![index],
                  navName: widget.navName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
