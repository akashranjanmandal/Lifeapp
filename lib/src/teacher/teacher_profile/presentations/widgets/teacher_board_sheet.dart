import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_profile/provider/teacher_profile_provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

void teacherBoardListBottomSheet(
    BuildContext context,
    TeacherProfileProvider provider,
    ) {
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
      String searchQuery = "";

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
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
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header
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
                      const SizedBox(width: 40),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Select Board',
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
                          MixpanelService.track(
                            "Profile Board bottom sheet closed via close button",
                            properties: {"timestamp": DateTime.now().toIso8601String()},
                          );
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.close,
                              color: Colors.white.withOpacity(0.9), size: 28),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search board...",
                    prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade400),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Scrollable list
                Expanded(
                  child: ListenableBuilder(
                    listenable: provider,
                    builder: (context, _) {
                      if (provider.boardModel?.data?.boards == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final boards = provider.boardModel!.data!.boards!;
                      final filteredBoards = boards
                          .where((board) =>
                      board.name != null &&
                          board.name!.toLowerCase().contains(searchQuery))
                          .toList();

                      if (filteredBoards.isEmpty) {
                        return const Center(
                          child: Text(
                            "No boards found",
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filteredBoards.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 12,
                          thickness: 1,
                          color: Colors.deepPurple.shade100,
                          indent: 12,
                          endIndent: 12,
                        ),
                        itemBuilder: (context, index) {
                          final board = filteredBoards[index];
                          final isSelected = provider.boardId == board.id;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            splashColor: Colors.deepPurple.shade100,
                            highlightColor: Colors.deepPurple.shade50,
                            onTap: () {
                              if (board.id != null && board.name != null) {
                                MixpanelService.track(
                                  "Board column in form updated",
                                  properties: {
                                    "board_id": board.id,
                                    "board_name": board.name,
                                    "timestamp":
                                    DateTime.now().toIso8601String(),
                                  },
                                );
                                provider.updateBoard(board.id!, board.name!);
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepPurple.shade50
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      board.name ?? "",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isSelected
                                            ? Colors.deepPurple.shade700
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle,
                                        color: Colors.deepPurple.shade600,
                                        size: 22),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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
