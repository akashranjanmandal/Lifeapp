import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import 'package:provider/provider.dart';
import '../provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
class TeacherLeaderboardScreen extends StatefulWidget {
  const TeacherLeaderboardScreen({super.key});

  @override
  State<TeacherLeaderboardScreen> createState() => _TeacherLeaderboardScreenState();
}

class _TeacherLeaderboardScreenState extends State<TeacherLeaderboardScreen> {
  int? _selectedIndex;
  bool isTeacherView = true;
  String filter = 'Monthly';
  DateTime? _startTime;
  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    Future.microtask(_loadData);
  }
  @override
  void dispose() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      MixpanelService.track("Leaderboard screen activity time", properties: {
        "duration_seconds": duration,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    super.dispose();
  }

  void _loadData() {
    final provider = Provider.of<LeaderboardProvider>(context, listen: false);
    isTeacherView ? provider.loadTeacherLeaderboard() : provider.loadSchoolLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LeaderboardProvider>(context);
    final isLoading = isTeacherView ? provider.isLoadingTeachers : provider.isLoadingSchools;
    final error = isTeacherView ? provider.errorTeachers : provider.errorSchools;
    final items = isTeacherView ? provider.teachers : provider.schools;
    final isSchool = !isTeacherView;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            MixpanelService.track("Back icon clicked", properties: {
              "timestamp": DateTime.now().toIso8601String(),
            });
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherDashboardPage()),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filter,
                  icon: const Icon(Icons.filter_alt_outlined),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        filter = val;
                      });

                      // Track filter option clicked
                      MixpanelService.track("Filter option clicked", properties: {
                        "filter": val,
                        "timestamp": DateTime.now().toIso8601String(),
                      });

                      _loadData();
                    }
                  },
                  items: ['Monthly', '3 Months', '6 Months', '1 Year']
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/bg.png'), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _styledChoiceChip(label: 'Teacher Board', selected: isTeacherView, onTap: () {
                    // Track teacher board tab clicked
                    MixpanelService.track("Teacher board tab button clicked", properties: {
                      "timestamp": DateTime.now().toIso8601String(),
                    });
                    _onSwitch(true);
                  },),
                  const SizedBox(width: 8),
                  _styledChoiceChip(label: 'School Board', selected: !isTeacherView, onTap: () {
                    // Track school board tab clicked
                    MixpanelService.track("School board tab button clicked", properties: {
                      "timestamp": DateTime.now().toIso8601String(),
                    });
                    _onSwitch(false);
                  },),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (error != null)
                Expanded(child: Center(child: Text(error)))
              else if (items.isNotEmpty) ...[
                  _buildTopThree(items, isSchool),
                  const SizedBox(height: 8),
                  Expanded(child: _buildRemainingList(items, isSchool)),
                ] else
                  const Expanded(child: Center(child: Text('No data available'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledChoiceChip({required String label, required bool selected, required VoidCallback onTap}) => ChoiceChip(
    label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
    selected: selected,
    selectedColor: Colors.blueAccent,
    backgroundColor: Colors.grey.shade200,
    onSelected: (_) => onTap(),
  );

  void _onSwitch(bool teacher) {
    if (isTeacherView != teacher) {
      setState(() => isTeacherView = teacher);
      _loadData();
    }
  }

  Widget _buildTopThree(List items, bool isSchool) {
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
                  MixpanelService.track("Profile/rank button clicked", properties: {
                    "rank": items[1].rank ?? 2,
                    "name": items[1].name ?? '',
                    "timestamp": DateTime.now().toIso8601String(),
                  });
                  showProfileDialog(
                  context,
                  rank: items[1].rank ?? 2,
                  name: items[1].name ?? '',
                  schoolName: items[1].schoolName ?? '',
                  score: items[1].totalEarnedCoins ?? 0,
                  imageUrl: items[1].profileImage,
                  isSchool: isSchool,
                );},
                child: _LeaderboardTopThree(
                  rank: items[1].rank ?? 2,
                  badgeAsset: 'assets/images/2.png',
                  name: items[1].name ?? '',
                  schoolName: items[1].schoolName ?? '',
                  score: items[1].totalEarnedCoins ?? 0,
                  profileImage: items[1].profileImage,
                  isSecond: true,
                  isSchool: isSchool,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: GestureDetector(
              onTap: () {
                MixpanelService.track("Profile/rank button clicked", properties: {
                  "rank": items[0].rank ?? 1,
                  "name": items[0].name ?? '',
                  "timestamp": DateTime.now().toIso8601String(),
                });
                showProfileDialog(
                context,
                rank: items[0].rank ?? 1,
                name: items[0].name ?? '',
                schoolName: items[0].schoolName ?? '',
                score: items[0].totalEarnedCoins ?? 0,
                imageUrl: items[0].profileImage,
                isSchool: isSchool,
              );},
              child: _LeaderboardTopThree(
                rank: items[0].rank ?? 1,
                badgeAsset: 'assets/images/1.png',
                name: items[0].name ?? '',
                schoolName: items[0].schoolName ?? '',
                score: items[0].totalEarnedCoins ?? 0,
                profileImage: items[0].profileImage,
                isSchool: isSchool,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (items.length > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  MixpanelService.track("Profile/rank button clicked", properties: {
                    "rank": items[2].rank ?? 3,
                    "name": items[2].name ?? '',
                    "timestamp": DateTime.now().toIso8601String(),
                  });
                  showProfileDialog(
                  context,
                  rank: items[2].rank ?? 3,
                  name: items[2].name ?? '',
                  schoolName: items[2].schoolName ?? '',
                  score: items[2].totalEarnedCoins ?? 0,
                  imageUrl: items[2].profileImage,
                  isSchool: isSchool,
                );},
                child: _LeaderboardTopThree(
                  rank: items[2].rank ?? 3,
                  badgeAsset: 'assets/images/3.png',
                  name: items[2].name ?? '',
                  schoolName: items[2].schoolName ?? '',
                  score: items[2].totalEarnedCoins ?? 0,
                  profileImage: items[2].profileImage,
                  isThird: true,
                  isSchool: isSchool,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemainingList(List items, bool isSchool) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length > 3 ? items.length - 3 : 0,
      itemBuilder: (context, index) {
        final person = items[index + 3];
        return GestureDetector(
          onTap: () {
            setState(() => _selectedIndex = index + 3);
            MixpanelService.track("Profile/rank button clicked", properties: {
              "rank": person.rank ?? (index + 4),
              "name": person.name ?? '',
              "timestamp": DateTime.now().toIso8601String(),
            });
            showProfileDialog(
              context,
              rank: person.rank ?? (index + 4),
              name: person.name ?? '',
              schoolName: person.schoolName ?? '',
              score: person.totalEarnedCoins ?? 0,
              imageUrl: person.profileImage,
              isSchool: isSchool,
            );
          },
          child: _LeaderboardListItem(
            rank: person.rank ?? (index + 4),
            name: person.name ?? '',
            score: person.totalEarnedCoins ?? 0,
            isSelected: _selectedIndex == index + 3,
            profileImage: person.profileImage,
            isSchool: isSchool,
          ),
        );
      },
    );
  }
}

void showProfileDialog(
    BuildContext context, {
      required int rank,
      required String name,
      required String schoolName,
      required int score,
      required String? imageUrl,
      required bool isSchool,
    }) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                'Rank #$rank',
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
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage('https://lifeappmedia.blr1.digitaloceanspaces.com/$imageUrl')
                  : AssetImage(
                isSchool ? 'assets/images/school-3.png' : 'assets/images/placeholder.jpg',
              ) as ImageProvider,
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              schoolName,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  score.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // Track close button clicked in rank details popup
                  MixpanelService.track("Close button in Rank details popup clicked", properties: {
                    "timestamp": DateTime.now().toIso8601String(),
                    "rank": rank,
                    "name": name,
                  });
                  Navigator.of(context, rootNavigator: true).pop();
                },
                  child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
  });

  @override
  Widget build(BuildContext context) {
    final bool small = isSecond || isThird;
    final imageSize = small ? 60.0 : 80.0;

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
                backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                    ? NetworkImage('https://lifeappmedia.blr1.digitaloceanspaces.com/$profileImage')
                    : AssetImage(
                  isSchool ? 'assets/images/school-3.png' : 'assets/images/placeholder.jpg',
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: small ? 10 : 12),
              ),
              Text(
                schoolName,
                maxLines: null,
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: small ? 10 : 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardListItem extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final bool isSelected;
  final String? profileImage;
  final bool isSchool;

  const _LeaderboardListItem({
    required this.rank,
    required this.name,
    required this.score,
    this.isSelected = false,
    this.profileImage,
    this.isSchool = false,
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

  @override
  Widget build(BuildContext context) {
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
                ? NetworkImage('https://lifeappmedia.blr1.digitaloceanspaces.com/$profileImage')
                : AssetImage(
              isSchool ? 'assets/images/school-3.png' : 'assets/images/placeholder.jpg',
            ) as ImageProvider,
          ),
          const SizedBox(width: 12),
          Text(_ordinal(rank), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          Text(score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
        ],
      ),
    );
  }
}
