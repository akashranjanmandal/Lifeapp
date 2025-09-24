import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/vision_model.dart';
import '../providers/vision_provider.dart';
import 'video_player.dart';
import 'vision_review.dart';

class VisionPage extends StatefulWidget {
  final String navName;
  final String subjectName;
  final int? initialTabIndex;
  final String sectionId;
  final String gradeId;
  final String classId;

  const VisionPage({
    Key? key,
    required this.navName,
    required this.subjectName,
    required this.sectionId,
    required this.gradeId,
    required this.classId,
    this.initialTabIndex,
  }) : super(key: key);

  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _levelFilterTitle = '';
  final TextEditingController _searchController = TextEditingController();
  String _chapterFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToVideoPlayer(TeacherVisionVideo video) {
    if (widget.sectionId.isEmpty) {
      _showSectionErrorDialog();
      return;
    }
    final visionProvider = Provider.of<VisionProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: visionProvider,
          child: TeacherVideoPlayerPage(
            video: video,
            sectionId: widget.sectionId,
            gradeId: widget.gradeId,
            classId: widget.classId,
            onBack: () {
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  void _navigateToVisionReview(TeacherVisionVideo video) {
    final visionProvider = Provider.of<VisionProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: visionProvider,
          child: VisionReviewPage(video: video),
        ),
      ),
    );
  }

  void _showSectionErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Section Required'),
          content: const Text(
            'Section information is not available. Please navigate from the main Vision page or select a specific class section first.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown<T extends Map<String, Object?>>({
    required String label,
    required String selectedId,
    required List<T> options,
    required Function(String) onChanged,
  }) {
    String displayText = '';
    if (selectedId.isNotEmpty) {
      final selectedItem = options.firstWhere(
            (o) => o['id'].toString() == selectedId,
        orElse: () => {'id': '', 'title': ''} as T,
      );
      displayText = (selectedItem['title'] ?? '').toString();
      if (displayText.length > 10) displayText = '${displayText.substring(0, 10)}..';
    }

    return GestureDetector(
      onTap: () async {
        String? result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            TextEditingController searchController = TextEditingController();
            List<T> filteredOptions = List.from(options);

            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredOptions.isEmpty
                            ? const Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                            : ListView(
                          children: [
                            ListTile(
                              title: const Text(
                                'All',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => Navigator.pop(context, ''),
                            ),
                            ...filteredOptions.map((option) {
                              final isSelected = selectedId == option['id'].toString();
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF6366F1).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    option['title']?.toString() ?? '',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14,
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : Colors.black87,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(context, option['id'].toString()),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );

        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedId.isEmpty ? Colors.grey[300]! : const Color(0xFF6366F1),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                displayText.isEmpty ? label : displayText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selectedId.isEmpty ? Colors.grey[700] : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: selectedId.isEmpty ? Colors.grey[700] : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VisionProvider>(
      builder: (context, provider, child) {
        final subjects = provider.getAvailableSubjects();
        final levels = provider.availableLevels;
        final chapters = provider.chapters;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vision',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                if (widget.sectionId.isNotEmpty)
                  Text(
                    'Grade: ${widget.gradeId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () => provider.refreshVideos(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(160),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF6366F1),
                      indicator: BoxDecoration(
                        color: const Color.fromARGB(255, 99, 177, 241),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'All Vision'),
                        Tab(text: 'Track Vision'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filters Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child:  _buildFilterDropdown(
                            label: 'Subject',
                            selectedId: provider.selectedSubjectTitle ?? '',
                            options: provider.getAvailableSubjectTitles()
                                .map((s) => {'id': s, 'title': s})
                                .toList(),
                            onChanged: (title) {
                              provider.setSubjectFilter(title);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterDropdown(
                            label: 'Level',
                            selectedId: _levelFilterTitle,
                            options: levels
                                .map((e) => {'id': e, 'title': e})
                                .toList(),
                            onChanged: (title) {
                              setState(() {
                                _levelFilterTitle = title;
                              });
                              provider.setLevelFilter(title); // provider will handle ID mapping internally
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterDropdown(
                            label: 'Chapter',
                            selectedId: _chapterFilter,
                            options: chapters
                                .map((c) => {
                              'id': c['id'],
                              'title': c['title'] ?? ''
                            })
                                .toList(),
                            onChanged: (id) {
                              setState(() => _chapterFilter = id);
                              provider.setChapterFilter(id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                        ),
                        onChanged: (value) {
                          provider.setSearchQuery(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildVideoList(provider.filteredNonAssignedVideos, false),
                  _buildVideoList(provider.filteredAssignedVideos, true),
                ],
              ),
              if (provider.isLoading &&
                  provider.filteredNonAssignedVideos.isEmpty &&
                  provider.filteredAssignedVideos.isEmpty)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Video List & Cards remain the same (no UI change)
  Widget _buildVideoList(List<TeacherVisionVideo> videos, bool isAssignedTab) {
    final provider = Provider.of<VisionProvider>(context);
    final hasMore =
    isAssignedTab ? provider.hasMoreAssignedVideos : provider.hasMoreAllVideos;
    final isLoadingMore = provider.isLoadingMore;

    if (videos.isEmpty && !provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification.metrics.pixels ==
            scrollNotification.metrics.maxScrollExtent) {
          if (hasMore && !isLoadingMore) {
            provider.loadMoreVideos();
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => provider.refreshVideos(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: videos.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= videos.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: isLoadingMore
                      ? CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  )
                      : const Text('\u200B'),
                ),
              );
            }

            final video = videos[index];
            final videoId =
                YoutubePlayer.convertUrlToId(video.youtubeUrl) ?? 'dQw4w9WgXcQ';

            return GestureDetector(
              onTap: () => !isAssignedTab ? _navigateToVideoPlayer(video) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isAssignedTab
                    ? _buildAssignedVideoCard(video, videoId)
                    : _buildRegularVideoCard(video, videoId),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegularVideoCard(TeacherVisionVideo video, String videoId) {
    // same as your current card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Stack(
            children: [
              Image.network(
                video.thumbnailUrl.isNotEmpty
                    ? video.thumbnailUrl
                    : 'https://img.youtube.com/vi/$videoId/0.jpg',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Assign',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                video.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (video.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  video.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      video.subject,
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      video.level,
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedVideoCard(TeacherVisionVideo video, String videoId) {
    // same as your current card
    return GestureDetector(
      onTap: () => _navigateToVideoPlayer(video),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        video.thumbnailUrl.isNotEmpty
                            ? video.thumbnailUrl
                            : 'https://img.youtube.com/vi/$videoId/0.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF87CEEB).withOpacity(0.3),
                              const Color(0xFFFFB6C1).withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.description.isNotEmpty
                        ? video.description
                        : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToVisionReview(video),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    minimumSize: const Size(75, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                  ),
                  child: const Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
