import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/student/mission/presentations/pages/submit_mission_page.dart';
import 'package:lifelab3/src/student/subject_level_list/models/mission_list_model.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class GetStartedMissionWidget extends StatelessWidget {
  final MissionDatum data;

  const GetStartedMissionWidget({super.key, required this.data});

  String _getStatus() {
    if (data.assignedBy != null && data.assignedBy!.isNotEmpty) {
      return "Assigned"; // 👈 Show "Assigned" if teacher assigned
    }
    return data.status ?? "Get Started";
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        MixpanelService.track("Mission Card Clicked", properties: {
          "mission_id": data.id,
          "mission_title": data.title,
          "status": status,
        });
        push(
          context: context,
          page: SubmitMissionPage(mission: data),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Status Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    data.image?.url != null
                        ? ApiHelper.imgBaseUrl + data.image!.url!
                        : "https://via.placeholder.com/300",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              ],
            ),

            // Title / Assigned By
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title ?? "Untitled Mission",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
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
