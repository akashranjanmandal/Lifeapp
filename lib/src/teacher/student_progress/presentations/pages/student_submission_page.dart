import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/teacher/student_progress/presentations/pages/teacher_mission_submission_page.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:provider/provider.dart';

class StudentSubmissionPage extends StatefulWidget {
  final String missionId;

  const StudentSubmissionPage({super.key, required this.missionId});

  @override
  State<StudentSubmissionPage> createState() => _StudentSubmissionPageState();
}

class _StudentSubmissionPageState extends State<StudentSubmissionPage> {
  String? selectedClass;
  String? selectedStatus;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProgressProvider>(context, listen: false)
          .getTeacherMissionParticipant(widget.missionId);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProgressProvider>(context);

    /// Participants
    final participants =
        provider.teacherMissionParticipantModel?.data?.data ?? [];
    /// Available classes (unique grade names only)
    final availableClasses = [
      "All",
      ...participants
          .map((p) => p.user?.grade?.name ?? "")
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList(),
    ];
    /// Apply filters
    var filteredList = participants.where((p) {
      // Filter by class
      if (selectedClass != null &&
          selectedClass!.isNotEmpty &&
          selectedClass != "All") {
        if ((p.user?.grade?.name ?? "") != selectedClass) return false;
      }

      // Filter by status
      if (selectedStatus != null && selectedStatus!.isNotEmpty) {
        final sub = p.submission;
        String status;
        if (sub == null) {
          status = "Assigned";
        } else if (sub.approvedAt != null) {
          status = "Approved";
        } else if (sub.rejectedAt != null) {
          status = "Rejected";
        } else {
          status = "Review";
        }
        if (status != selectedStatus) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: commonAppBar(
        context: context,
        name: StringHelper.submission,
        action: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Text(
            "Total ${filteredList.length}",
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          /// Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  /// Class Filter
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: selectedClass ?? "All",
                      isExpanded: true,
                      hint: const Text(
                        "Select Class",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      items: availableClasses
                          .map(
                            (cls) => DropdownMenuItem<String>(
                          value: cls,
                          child: Text(
                            cls,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedClass = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down,
                          size: 22, color: Colors.black54),
                      dropdownColor: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Status Filter
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      hint: const Text(
                        "Status",
                        style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: "",
                          child: Text("All"),
                        ),
                        ...["Assigned", "Review", "Approved", "Rejected"].map(
                              (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(
                                () => selectedStatus = val!.isEmpty ? null : val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down,
                          size: 22, color: Colors.black54),
                      dropdownColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                Provider.of<StudentProgressProvider>(context, listen: false)
                    .getTeacherMissionParticipant(widget.missionId);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final participant = filteredList[index];
                  final submission = participant.submission;

                  // Status setup
                  String statusText;
                  Color statusColor;
                  IconData statusIcon;

                  if (submission == null) {
                    statusText = "Assigned";
                    statusColor = Colors.blueAccent;
                    statusIcon = Icons.assignment_outlined;
                  } else if (submission.approvedAt != null) {
                    statusText = "Approved";
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                  } else if (submission.rejectedAt != null) {
                    statusText = "Rejected";
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                  } else {
                    statusText = "Review";
                    statusColor = Colors.orange;
                    statusIcon = Icons.rate_review;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: participant.user?.profileImage !=
                              null &&
                              participant.user!.profileImage!.isNotEmpty
                              ? NetworkImage(ApiHelper.imgBaseUrl +
                              participant.user!.profileImage!)
                              : const AssetImage(ImageHelper.profileIcon)
                          as ImageProvider,
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                participant.user?.name ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (submission != null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              elevation: 0,
                            ),
                            onPressed: () {
                              push(
                                context: context,
                                page: TeacherMissionSubmissionPage(
                                  missionIndex: index,
                                  missionStatus: submission.approvedAt == null &&
                                      submission.rejectedAt == null,
                                  missionId: widget.missionId,
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text(
                              "Details",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
