import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/student/tracker/provider/tracker_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/tracker_app_bar_widget.dart';
import '../widgets/tracker_profile_widget.dart';
import '../widgets/tracker_subject_widget.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  late DateTime _startTime;
  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // Record entry time

    MixpanelService.track('Tracker Screen Viewed'); // Optional: track entry event

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TrackerProvider>(context, listen: false).trackerData();
    });
  }
  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;

    MixpanelService.track('Tracker Screen Time', properties: {
      'duration_seconds': duration,
    });

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TrackerProvider>(context);
    return Scaffold(
      body: provider.trackerModel != null ? SingleChildScrollView(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 80),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            const TrackerAppbarWidget(),

            const TrackerProfileWidget(),

            const SizedBox(height: 20),
            ...provider.trackerModel!.data!.subjects.entries.map((entry) {
              return Column(
                children: [
                  TrackerSubjectWidget(
                    title: entry.key,
                    data: entry.value,
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),

          ],
        ),
      ) : const LoadingWidget(),
    );
  }
}
