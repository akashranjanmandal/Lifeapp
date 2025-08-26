import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/student/subject_level_list/models/mission_list_model.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class CompletedMissionWidget extends StatelessWidget {
  final MissionDatum data;

  const CompletedMissionWidget({super.key, required this.data});

  String _getStatus() {
    return "Completed"; // ✅ Always show Completed
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();

    return Container(
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
                    color: Colors.green.withOpacity(0.8), // ✅ Green for completed
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

          // Title
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              data.title ?? "Untitled Mission",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
