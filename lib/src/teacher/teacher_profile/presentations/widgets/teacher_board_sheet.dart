import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_profile/provider/teacher_profile_provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

void teacherBoardListBottomSheet(
    BuildContext context,
    TeacherProfileProvider provider,
    ) {
  // Track bottom sheet opened
  MixpanelService.track("Profile Board bottom sheet opened", properties: {
    "timestamp": DateTime.now().toIso8601String(),
  });

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 28,
              bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient header with title and close button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // for spacing balance
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Select Board', // or use StringHelper.board or similar
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // Track close via close button
                          MixpanelService.track("Profile Board bottom sheet closed via close button", properties: {
                            "timestamp": DateTime.now().toIso8601String(),
                          });
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.9),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: ListenableBuilder(
                      listenable: provider,
                      builder: (context, _) {
                        if (provider.boardModel?.data?.boards == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(
                          children: provider.boardModel!.data!.boards!.map((board) {
                            bool isSelected = provider.boardId == board.id;
                            return Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: Colors.deepPurple.shade100,
                                  highlightColor: Colors.deepPurple.shade50,
                                  onTap: () {
                                    if (board.id != null && board.name != null) {
                                      // Track board selection
                                      MixpanelService.track("Board column in form updated", properties: {
                                        "board_id": board.id,
                                        "board_name": board.name,
                                        "timestamp": DateTime.now().toIso8601String(),
                                      });
                                      provider.updateBoard(board.id!, board.name!);
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.deepPurple.shade50
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            board.name ?? "",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: isSelected
                                                  ? Colors.deepPurple.shade700
                                                  : Colors.black87,
                                              fontWeight:
                                              isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.deepPurple.shade600,
                                            size: 22,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (board != provider.boardModel!.data!.boards!.last)
                                  Divider(
                                    height: 12,
                                    thickness: 1,
                                    color: Colors.deepPurple.shade100,
                                    indent: 12,
                                    endIndent: 12,
                                  ),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
