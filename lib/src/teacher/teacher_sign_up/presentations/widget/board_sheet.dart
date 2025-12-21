import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/provider/teacher_sign_up_provider.dart';

void boardListBottomSheet(BuildContext context, TeacherSignUpProvider provider) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      String searchQuery = "";

      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Center(
                  child: Text(
                    "Select Board",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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

                // Board List
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
                        separatorBuilder: (_, __) => const Divider(
                          color: Colors.black26,
                          height: 0.5,
                        ),
                        itemBuilder: (context, index) {
                          final board = filteredBoards[index];
                          final isSelected = provider.selectedBoardId == board.id; // Changed from boardId to selectedBoardId

                          return InkWell(
                            onTap: () {
                              if (board.id != null && board.name != null) {
                                // CRITICAL FIX: Call setSelectedBoard instead of setting directly
                                provider.setSelectedBoard(board.id!, board.name!);
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
                                borderRadius: BorderRadius.circular(12),
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