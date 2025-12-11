import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import 'package:provider/provider.dart';
import '../model/model.dart';
import '../provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class TeacherLeaderboardScreen extends StatefulWidget {
  const TeacherLeaderboardScreen({super.key});

  @override
  State<TeacherLeaderboardScreen> createState() =>
      _TeacherLeaderboardScreenState();
}

class _TeacherLeaderboardScreenState extends State<TeacherLeaderboardScreen> {
  int? _selectedIndex;
  bool isTeacherView = true;
  String filter = 'Monthly';

  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollController2 = ScrollController();

  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    /*
    _startTime = DateTime.now();
    Future.microtask(_loadData);

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
    _scrollController2.addListener(_onScroll);
    */
  }

  @override
  void dispose() {
    /*
    _scrollController.removeListener(_onScroll);
    _scrollController2.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollController2.dispose();
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      MixpanelService.track("Leaderboard screen activity time", properties: {
        "duration_seconds": duration,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    */
    super.dispose();
  }

  /*
  void _onScroll() {
    final currentController = isTeacherView ? _scrollController : _scrollController2;
    if (currentController.position.pixels ==
        currentController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  void _loadData() {
    final provider = Provider.of<LeaderboardProvider>(context, listen: false);
    provider.setFilter(filter);
    isTeacherView
        ? provider.loadTeacherLeaderboard()
        : provider.loadSchoolLeaderboard();
  }

  void _loadMoreData() {
    final provider = Provider.of<LeaderboardProvider>(context, listen: false);
    if (isTeacherView) {
      if (provider.hasMoreTeachers && !provider.isLoadMoreTeachers) {
        provider.loadTeacherLeaderboard(loadMore: true);
      }
    } else {
      if (provider.hasMoreSchools && !provider.isLoadMoreSchools) {
        provider.loadSchoolLeaderboard(loadMore: true);
      }
    }
  }

  void _onSwitch(bool teacher) {
    if (isTeacherView != teacher) {
      setState(() => isTeacherView = teacher);
      _loadData();
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    /*
    final provider = Provider.of<LeaderboardProvider>(context);
    final isLoading =
    isTeacherView ? provider.isLoadingTeachers : provider.isLoadingSchools;
    final error =
    isTeacherView ? provider.errorTeachers : provider.errorSchools;
    final items = isTeacherView ? provider.teachers : provider.schools;
    final isSchool = !isTeacherView;
    final isLoadMore = isTeacherView
        ? provider.isLoadMoreTeachers
        : provider.isLoadMoreSchools;
    final hasMore = isTeacherView
        ? provider.hasMoreTeachers
        : provider.hasMoreSchools;
    */

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            /*
            MixpanelService.track("Back icon clicked", properties: {
              "timestamp": DateTime.now().toIso8601String(),
            });
            */
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherDashboardPage()),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Leaderboard',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filter,
                  icon: const Icon(Icons.filter_alt_outlined),
                  onChanged: (val) {
                    /*
                    if (val != null) {
                      setState(() {
                        filter = val;
                      });

                      // Track filter option clicked
                      MixpanelService.track("Filter option clicked",
                          properties: {
                            "filter": val,
                            "timestamp": DateTime.now().toIso8601String(),
                          });

                      _loadData();
                    }
                    */
                  },
                  items: ['Monthly', 'Quarterly', 'Half Yearly', 'Yearly']
                      .map((label) =>
                      DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'), fit: BoxFit.cover),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _styledChoiceChip(
                        label: 'Teacher Board',
                        selected: isTeacherView,
                        onTap: () {
                          /*
                          MixpanelService.track("Teacher board tab button clicked",
                              properties: {
                                "timestamp": DateTime.now().toIso8601String(),
                              });
                          _onSwitch(true);
                          */
                        },
                      ),
                      const SizedBox(width: 8),
                      _styledChoiceChip(
                        label: 'School Board',
                        selected: !isTeacherView,
                        onTap: () {
                          /*
                          MixpanelService.track("School board tab button clicked",
                              properties: {
                                "timestamp": DateTime.now().toIso8601String(),
                              });
                          _onSwitch(false);
                          */
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  /*
                  if (isLoading && items.isEmpty)
                    const Expanded(
                        child: Center(child: CircularProgressIndicator()))
                  else if (error != null && items.isEmpty)
                    Expanded(child: Center(child: Text(error)))
                  else if (items.isNotEmpty) ...[
                      _buildTopThree(items, isSchool),
                      const SizedBox(height: 8),
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent) {
                              _loadMoreData();
                            }
                            return false;
                          },
                          child: ListView(
                            controller: isTeacherView ? _scrollController : _scrollController2,
                            children: [
                              _buildRemainingList(items, isSchool),
                              if (isLoadMore)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              if (!hasMore && items.length > 3)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No more data',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                    const Expanded(child: Center(child: Text('No data available'))),
                  */
                  // Placeholder content
                  Expanded(
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),

          // Coming Soon Overlay
          Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const SizedBox(height: 30),

                    // Title with gradient text
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.blue.shade600,
                            Colors.purple.shade600,
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'COMING SOON',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Description
                    Text(
                      'Leaderboard feature is under development',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'We\'re working on exciting improvements to bring you the best experience. Stay tuned for updates!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 35),



                  ],
                ),
              ),
            ),
          ),        ],
      ),
    );
  }

  Widget _styledChoiceChip(
      {required String label,
        required bool selected,
        required VoidCallback onTap}) =>
      ChoiceChip(
        label: Text(label,
            style: TextStyle(color: selected ? Colors.white : Colors.black87)),
        selected: selected,
        selectedColor: Colors.blueAccent,
        backgroundColor: Colors.grey.shade200,
        onSelected: (_) => onTap(),
      );

/*
  Widget _buildRemainingList(List<LeaderboardEntry> items, bool isSchool) {
    return Column(
      children: [
        for (int index = 0; index < items.length - 3; index++)
          GestureDetector(
            onTap: () {
              final person = items[index + 3];
              setState(() => _selectedIndex = index + 3);
              MixpanelService.track("Profile/rank button clicked", properties: {
                "rank": person.rank,
                "name": person.name,
                "timestamp": DateTime.now().toIso8601String(),
              });
              showProfileDialog(
                context,
                entry: person,
                isSchool: isSchool,
              );
            },
            child: _LeaderboardListItem(
              rank: items[index + 3].rank,
              name: items[index + 3].name,
              score: items[index + 3].totalEarnedCoins,
              tScore: items[index + 3].tScore,
              sScore: items[index + 3].sScore,
              isSelected: _selectedIndex == index + 3,
              profileImage: items[index + 3].profileImage,
              isSchool: isSchool,
              assignTaskCoins: items[index + 3].assignTaskCoins,
              correctSubmissionCoins: items[index + 3].correctSubmissionCoins,
              studentCoins: items[index + 3].studentCoins,
              teacherCoins: items[index + 3].teacherCoins,
            ),
          ),
      ],
    );
  }

  Widget _buildTopThree(List<LeaderboardEntry> items, bool isSchool) {
    return SizedBox(
      height: 190,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (items.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  MixpanelService.track("Profile/rank button clicked",
                      properties: {
                        "rank": items[1].rank,
                        "name": items[1].name,
                        "timestamp": DateTime.now().toIso8601String(),
                      });
                  showProfileDialog(
                    context,
                    entry: items[1],
                    isSchool: isSchool,
                  );
                },
                child: _LeaderboardTopThree(
                  rank: items[1].rank,
                  badgeAsset: 'assets/images/2.png',
                  name: items[1].name,
                  schoolName: items[1].schoolName,
                  score: items[1].totalEarnedCoins,
                  profileImage: items[1].profileImage,
                  isSecond: true,
                  isSchool: isSchool,
                  tScore: items[1].tScore,
                  sScore: items[1].sScore,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: GestureDetector(
              onTap: () {
                MixpanelService.track("Profile/rank button clicked",
                    properties: {
                      "rank": items[0].rank,
                      "name": items[0].name,
                      "timestamp": DateTime.now().toIso8601String(),
                    });
                showProfileDialog(
                  context,
                  entry: items[0],
                  isSchool: isSchool,
                );
              },
              child: _LeaderboardTopThree(
                rank: items[0].rank,
                badgeAsset: 'assets/images/1.png',
                name: items[0].name,
                schoolName: items[0].schoolName,
                score: items[0].totalEarnedCoins,
                profileImage: items[0].profileImage,
                isSchool: isSchool,
                tScore: items[0].tScore,
                sScore: items[0].sScore,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (items.length > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  MixpanelService.track("Profile/rank button clicked",
                      properties: {
                        "rank": items[2].rank,
                        "name": items[2].name,
                        "timestamp": DateTime.now().toIso8601String(),
                      });
                  showProfileDialog(
                    context,
                    entry: items[2],
                    isSchool: isSchool,
                  );
                },
                child: _LeaderboardTopThree(
                  rank: items[2].rank,
                  badgeAsset: 'assets/images/3.png',
                  name: items[2].name,
                  schoolName: items[2].schoolName,
                  score: items[2].totalEarnedCoins,
                  profileImage: items[2].profileImage,
                  isThird: true,
                  isSchool: isSchool,
                  tScore: items[2].tScore,
                  sScore: items[2].sScore,
                ),
              ),
            ),
        ],
      ),
    );
  }
  */
}

/*
void showProfileDialog(
    BuildContext context, {
      required LeaderboardEntry entry,
      required bool isSchool,
    })
{
  // Helper function to format score without unnecessary trailing zeros
  String formatScorePrecisely(double score) {
    if (score == 0) return "0";

    // Convert to string
    String scoreStr = score.toString();

    // If the score is an integer, show as integer
    if (score == score.toInt()) {
      return score.toInt().toString();
    }

    // Remove trailing zeros
    if (scoreStr.contains('.')) {
      scoreStr = scoreStr.replaceAll(RegExp(r'0+$'), ''); // Remove trailing zeros
      scoreStr = scoreStr.replaceAll(RegExp(r'\.$'), ''); // Remove trailing dot
    }

    return scoreStr;
  }

  // Get the formatted score value
  final scoreValue = isSchool ? entry.sScore : entry.tScore;
  final formattedScore = formatScorePrecisely(scoreValue);

  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rank badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Rank #${entry.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.purple.shade100,
                backgroundImage: (entry.profileImage != null && entry.profileImage!.isNotEmpty)
                    ? NetworkImage(
                    'https://lifeappmedia.blr1.digitaloceanspaces.com/${entry.profileImage}')
                    : AssetImage(
                  isSchool
                      ? 'assets/images/school-3.png'
                      : 'assets/images/placeholder.jpg',
                ) as ImageProvider,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  entry.name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              if (entry.schoolName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entry.schoolName,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 20),

              // Main Score Card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSchool ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSchool ? Colors.green.shade200 : Colors.blue.shade200,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSchool ? Icons.school : Icons.leaderboard,
                          color: isSchool ? Colors.green : Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isSchool ? 'SCHOOL SCORE' : 'TEACHER SCORE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSchool ? Colors.green : Colors.blue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedScore,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isSchool ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Additional details in a compact format
              // Wrap the Row with SingleChildScrollView for horizontal scrolling if needed
              SizedBox(
                height: 70, // Fixed height for the chips row
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 4),
                        if (!isSchool) ...[
                          _buildDetailChip(
                            label: 'Tasks',
                            value: '${entry.assignTaskCoins}',
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _buildDetailChip(
                            label: 'Submissions',
                            value: '${entry.correctSubmissionCoins}',
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          if (entry.maxPossibleCoins > 0)
                            _buildDetailChip(
                              label: 'Max Possible',
                              value: '${entry.maxPossibleCoins}',
                              color: Colors.red,
                            ),
                          if (entry.maxPossibleCoins > 0) const SizedBox(width: 8),
                        ],
                        if (isSchool) ...[
                          _buildDetailChip(
                            label: 'Students',
                            value: '${entry.studentCoins}',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildDetailChip(
                            label: 'Teachers',
                            value: '${entry.teacherCoins}',
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildDetailChip(
                          label: 'Total Coins',
                          value: '${entry.totalEarnedCoins}',
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      MixpanelService.track(
                          "Close button in Rank details popup clicked",
                          properties: {
                            "timestamp": DateTime.now().toIso8601String(),
                            "rank": entry.rank,
                            "name": entry.name,
                          });
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildDetailChip({
  required String label,
  required String value,
  required Color color,
}) {
  return Container(
    constraints: const BoxConstraints(
      minWidth: 70,
      maxWidth: 100,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
*/

/*
class _LeaderboardListItem extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final bool isSelected;
  final String? profileImage;
  final bool isSchool;
  final double tScore;
  final double sScore;
  final int assignTaskCoins;
  final int correctSubmissionCoins;
  final int studentCoins;
  final int teacherCoins;

  const _LeaderboardListItem({
    required this.rank,
    required this.name,
    required this.score,
    this.isSelected = false,
    this.profileImage,
    this.isSchool = false,
    required this.tScore,
    required this.sScore,
    required this.assignTaskCoins,
    required this.correctSubmissionCoins,
    required this.studentCoins,
    required this.teacherCoins,
  });

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  // Helper method to format score without unnecessary trailing zeros
  String _formatScore(double score) {
    // Convert to string
    String scoreStr = score.toString();

    // If the score is an integer, show as integer
    if (score == score.toInt()) {
      return score.toInt().toString();
    }

    // Remove trailing zeros
    if (scoreStr.contains('.')) {
      scoreStr = scoreStr.replaceAll(RegExp(r'0+$'), ''); // Remove trailing zeros
      scoreStr = scoreStr.replaceAll(RegExp(r'\.$'), ''); // Remove trailing dot
    }

    return scoreStr;
  }

  @override
  Widget build(BuildContext context) {
    final scoreValue = isSchool ? sScore : tScore;
    final formattedScore = _formatScore(scoreValue);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.purple.shade100,
            backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                ? NetworkImage(
                'https://lifeappmedia.blr1.digitaloceanspaces.com/$profileImage')
                : AssetImage(
              isSchool
                  ? 'assets/images/school-3.png'
                  : 'assets/images/placeholder.jpg',
            ) as ImageProvider,
          ),
          const SizedBox(width: 12),
          Text(_ordinal(rank),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    formattedScore,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSchool ? Colors.black : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Use appropriate icon
                  Icon(
                    isSchool ? Icons.school : Icons.leaderboard,
                    color: isSchool ? Colors.black : Colors.blue,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
*/

/*
class _LeaderboardTopThree extends StatelessWidget {
  final int rank;
  final String badgeAsset;
  final String name;
  final String schoolName;
  final int score;
  final String? profileImage;
  final bool isSecond;
  final bool isThird;
  final bool isSchool;
  final double tScore;
  final double sScore;

  const _LeaderboardTopThree({
    required this.rank,
    required this.badgeAsset,
    required this.name,
    required this.schoolName,
    required this.score,
    this.profileImage,
    this.isSecond = false,
    this.isThird = false,
    this.isSchool = false,
    required this.tScore,
    required this.sScore,
  });

  // Helper method to format score without unnecessary trailing zeros
  String _formatScore(double score) {
    // Convert to string
    String scoreStr = score.toString();

    // If the score is an integer, show as integer
    if (score == score.toInt()) {
      return score.toInt().toString();
    }

    // Remove trailing zeros
    if (scoreStr.contains('.')) {
      scoreStr = scoreStr.replaceAll(RegExp(r'0+$'), ''); // Remove trailing zeros
      scoreStr = scoreStr.replaceAll(RegExp(r'\.$'), ''); // Remove trailing dot
    }

    return scoreStr;
  }

  @override
  Widget build(BuildContext context) {
    final bool small = isSecond || isThird;
    final imageSize = small ? 60.0 : 80.0;
    final scoreValue = isSchool ? sScore : tScore;
    final formattedScore = _formatScore(scoreValue);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.only(top: small ? 10 : 0),
              child: CircleAvatar(
                radius: imageSize / 2,
                backgroundColor: Colors.purple.shade100,
                backgroundImage: (profileImage != null &&
                    profileImage!.isNotEmpty)
                    ? NetworkImage(
                    'https://lifeappmedia.blr1.digitaloceanspaces.com/$profileImage')
                    : AssetImage(
                  isSchool
                      ? 'assets/images/school-3.png'
                      : 'assets/images/placeholder.jpg',
                ) as ImageProvider,
              ),
            ),
            Positioned(top: 0, child: Image.asset(badgeAsset, height: 24)),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 110,
          child: Column(
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: small ? 10 : 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formattedScore,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: small ? 10 : 12,
                      color: isSchool ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isSchool ? Icons.school : Icons.leaderboard,
                    color: isSchool ? Colors.green : Colors.blue,
                    size: small ? 12 : 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
*/