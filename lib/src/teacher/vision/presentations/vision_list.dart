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
  String _selectedBoardId = '';

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
    final visionProvider = Provider.of<TeacherVisionProvider>(context, listen: false);
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
    final visionProvider = Provider.of<TeacherVisionProvider>(context, listen: false);
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

  Widget _buildBoardChapterDropdown() {
    final provider = Provider.of<TeacherVisionProvider>(context, listen: true);
    final boards = provider.boards;
    final chapters = provider.chapters;

    // Get display text for the dropdown
    String displayText = 'Chapters';
    if (_selectedBoardId.isNotEmpty) {
      final selectedBoard = boards.firstWhere(
            (b) => b['id'].toString() == _selectedBoardId,
        orElse: () => {'title': '', 'name': ''},
      );
      final boardName =
          selectedBoard['title']?.toString() ?? selectedBoard['name']?.toString() ?? 'Board';

      if (_chapterFilter.isNotEmpty) {
        final selectedChapter = chapters.firstWhere(
              (c) => c['id']?.toString() == _chapterFilter,
          orElse: () => {'title': ''},
        );
        final chapterName = selectedChapter['title']?.toString() ?? '';
        displayText = '$boardName • $chapterName';
      } else {
        displayText = boardName;
      }
    } else if (_chapterFilter.isNotEmpty) {
      final selectedChapter = chapters.firstWhere(
            (c) => c['id']?.toString() == _chapterFilter,
        orElse: () => {'title': ''},
      );
      displayText = selectedChapter['title']?.toString() ?? 'Chapter';
    }

    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return ChangeNotifierProvider.value(
              value: provider,
              child: _BoardChapterModalContent(
                selectedBoardId: _selectedBoardId,
                chapterFilter: _chapterFilter,
                onBoardSelected: (String boardId, String boardTitle) {
                  setState(() {
                    _selectedBoardId = boardId;
                    _chapterFilter = '';
                  });
                  provider.setBoardFilter(boardTitle);
                  provider.setChapterFilter(null);
                },
                onChapterSelected: (String chapterId) {
                  setState(() {
                    _chapterFilter = chapterId;
                  });
                  provider.setChapterFilter(chapterId);
                },
                onClearAll: () {
                  setState(() {
                    _selectedBoardId = '';
                    _chapterFilter = '';
                  });
                  provider.setBoardFilter(null);
                  provider.setChapterFilter(null);
                },
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedBoardId.isEmpty && _chapterFilter.isEmpty
                ? Colors.grey[300]!
                : const Color(0xFF6366F1),
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
                displayText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _selectedBoardId.isEmpty && _chapterFilter.isEmpty
                      ? Colors.grey[700]
                      : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: _selectedBoardId.isEmpty && _chapterFilter.isEmpty
                  ? Colors.grey[700]
                  : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherVisionProvider>(
      builder: (context, provider, child) {
        final subjects = provider.getAvailableSubjects();
        final levels = provider.availableLevels;

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
                          child: _buildFilterDropdown(
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
                              provider.setLevelFilter(title);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBoardChapterDropdown(), // Combined Board & Chapter dropdown
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
// In your VisionPage build method, replace the body section with this:

          body: Stack(
            children: [
              // Show loading indicator only during initial load
              if (provider.isLoading && !provider.isInitialized)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading videos...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Main content
              Column(
                children: [
                  // Show initialization progress
                  if (!provider.isInitialized)
                    const LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      backgroundColor: Colors.transparent,
                      minHeight: 2,
                    ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVideoList(provider.filteredNonAssignedVideos, false, provider),
                        _buildVideoList(provider.filteredAssignedVideos, true, provider),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoList(List<TeacherVisionVideo> videos, bool isAssignedTab, TeacherVisionProvider provider) {
    final hasMore = isAssignedTab ? provider.hasMoreAssignedVideos : provider.hasMoreAllVideos;
    final isLoadingMore = provider.isLoadingMore;

    // Show loading state
    if (provider.isLoading && videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading videos...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (videos.isEmpty && !provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No videos found',
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
        if (scrollNotification.metrics.pixels == scrollNotification.metrics.maxScrollExtent) {
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  )
                      : const SizedBox.shrink(),
                ),
              );
            }

            final video = videos[index];
            final videoId = YoutubePlayer.convertUrlToId(video.youtubeUrl) ?? 'dQw4w9WgXcQ';

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (video.laBoardId != null && video.laBoardId!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Board: ${video.laBoardId}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
                        : 'No description available',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (video.laBoardId != null && video.laBoardId!.isNotEmpty)
                    Text(
                      'Board: ${video.laBoardId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
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
class _BoardChapterModalContent extends StatefulWidget {
  final String selectedBoardId;
  final String chapterFilter;
  final Function(String, String) onBoardSelected;
  final Function(String) onChapterSelected;
  final VoidCallback onClearAll;

  const _BoardChapterModalContent({
    Key? key,
    required this.selectedBoardId,
    required this.chapterFilter,
    required this.onBoardSelected,
    required this.onChapterSelected,
    required this.onClearAll,
  }) : super(key: key);

  @override
  State<_BoardChapterModalContent> createState() => _BoardChapterModalContentState();
}

class _BoardChapterModalContentState extends State<_BoardChapterModalContent> {
  late TextEditingController _boardSearchController;
  List<Map<String, Object?>> _filteredBoards = [];
  String _currentSearchQuery = '';

  // Track current selection locally for immediate UI updates
  String _currentSelectedBoardId = '';
  String _currentChapterFilter = '';

  @override
  void initState() {
    super.initState();
    _boardSearchController = TextEditingController();
    _currentSelectedBoardId = widget.selectedBoardId;
    _currentChapterFilter = widget.chapterFilter;
    _updateFilteredBoards();
  }

  void _updateFilteredBoards() {
    final provider = Provider.of<TeacherVisionProvider>(context, listen: false);
    if (_currentSearchQuery.isEmpty) {
      _filteredBoards = List.from(provider.boards);
    } else {
      _filteredBoards = provider.boards.where((board) {
        final boardTitle = board['title']?.toString() ?? board['name']?.toString() ?? '';
        return boardTitle.toLowerCase().contains(_currentSearchQuery.toLowerCase());
      }).toList();
    }
  }

  void _filterBoards(String query) {
    setState(() {
      _currentSearchQuery = query;
      _updateFilteredBoards();
    });
  }

  void _handleBoardSelection(String boardId, String boardTitle) {
    // Update local state immediately for UI response
    setState(() {
      _currentSelectedBoardId = boardId;
      _currentChapterFilter = '';
    });

    // Call the parent callback
    widget.onBoardSelected(boardId, boardTitle);
    _boardSearchController.clear();
    _filterBoards('');
  }

  void _handleChapterSelection(String chapterId) {
    setState(() {
      _currentChapterFilter = chapterId;
    });
    widget.onChapterSelected(chapterId);
    _handleClose();
  }

  void _handleClearAll() {
    setState(() {
      _currentSelectedBoardId = '';
      _currentChapterFilter = '';
    });
    widget.onClearAll();
    _boardSearchController.clear();
    _filterBoards('');
  }

  void _handleClose() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _boardSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherVisionProvider>(
      builder: (context, provider, child) {
        final boards = provider.boards;
        final chapters = provider.chapters;

        // Update filtered boards when boards change
        if (_filteredBoards.isEmpty || _filteredBoards.length != boards.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateFilteredBoards();
          });
        }

        // Reorder selected board/chapter to appear first
        final sortedBoards = [
          ..._filteredBoards.where((b) => b['id']?.toString() == _currentSelectedBoardId),
          ..._filteredBoards.where((b) => b['id']?.toString() != _currentSelectedBoardId),
        ];
        final sortedChapters = [
          ...chapters.where((c) => c['id']?.toString() == _currentChapterFilter),
          ...chapters.where((c) => c['id']?.toString() != _currentChapterFilter),
        ];

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Board & Chapter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _handleClose,
                    ),
                  ],
                ),
              ),

              // Board Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _boardSearchController,
                    onChanged: _filterBoards,
                    decoration: InputDecoration(
                      hintText: 'Search boards...',
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Row(
                  children: [
                    // Boards section
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Boards',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: _filteredBoards.isEmpty
                                  ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'No boards found',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : ListView(
                                children: [
                                  // All Boards
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _currentSelectedBoardId.isEmpty
                                          ? const Color(0xFF6366F1).withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.all_inclusive,
                                        color: _currentSelectedBoardId.isEmpty
                                            ? const Color(0xFF6366F1)
                                            : Colors.grey,
                                      ),
                                      title: const Text('All Boards', style: TextStyle(fontWeight: FontWeight.w500)),
                                      onTap: _handleClearAll,
                                    ),
                                  ),

                                  // Board options
                                  ...sortedBoards.map((board) {
                                    final boardId = board['id']?.toString() ?? '';
                                    final boardTitle = board['title']?.toString() ?? board['name']?.toString() ?? 'Unknown Board';
                                    final isSelected = _currentSelectedBoardId == boardId;

                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6366F1).withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.school,
                                          color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                                        ),
                                        title: Text(
                                          boardTitle,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
                                          ),
                                        ),
                                        onTap: () => _handleBoardSelection(boardId, boardTitle),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Chapters section
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Chapters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _currentSelectedBoardId.isEmpty
                                ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.menu_book, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Select Board to get Chapters',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : provider.isLoadingChapters
                                ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Loading chapters...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : sortedChapters.isEmpty
                                ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.menu_book, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No chapters available\nfor selected board',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : ListView(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _currentChapterFilter.isEmpty
                                        ? const Color(0xFF10B981).withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.all_inclusive,
                                      color: _currentChapterFilter.isEmpty ? const Color(0xFF10B981) : Colors.grey,
                                    ),
                                    title: const Text('All Chapters', style: TextStyle(fontWeight: FontWeight.w500)),
                                    onTap: () => _handleChapterSelection(''),
                                  ),
                                ),
                                ...sortedChapters.map((chapter) {
                                  final chapterId = chapter['id']?.toString() ?? '';
                                  final chapterTitle = chapter['title']?.toString() ?? 'Unknown Chapter';
                                  final isSelected = _currentChapterFilter == chapterId;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF10B981).withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.menu_book,
                                        color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                      title: Text(
                                        chapterTitle,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF10B981) : Colors.black87,
                                        ),
                                      ),
                                      onTap: () => _handleChapterSelection(chapterId),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}