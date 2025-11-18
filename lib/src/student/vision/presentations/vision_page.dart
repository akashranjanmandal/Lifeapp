import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:provider/provider.dart';
import '../providers/vision_provider.dart';
import '../models/vision_video.dart';
import 'filter_page.dart';
import 'video_player.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class VisionPage extends StatefulWidget {
  final String navName;
  final String subjectId;
  final String levelId;
  const VisionPage({
    super.key,
    required this.navName,
    required this.subjectId,
    required this.levelId
  });
  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _enterTime;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    MixpanelService.track("Vision screen opened");
    _enterTime = DateTime.now();

    // Setup scroll listener for lazy loading
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<VisionProvider>(context, listen: false);
      print("subject ${widget.subjectId}");
      print('Current Level ID: ${widget.levelId}');

      await provider.initWithSubject(widget.subjectId, widget.levelId);
      _checkLevelCompletion(provider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<VisionProvider>(context, listen: false);

    // Load more when 200px from bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (provider.currentFilter.isNotEmpty) {
        // Load more filter results
        provider.loadMoreFilterResults();
      } else if (provider.searchQuery.isNotEmpty) {
        // Load more search results
        provider.loadMoreSearchResults();
      } else {
        // Load more regular videos
        provider.loadMoreVideos();
      }
    }
  }
  void _onSearchChanged(String value) {
    // Cancel previous debounce timer
    _searchDebounce?.cancel();

    // Set up new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final provider = Provider.of<VisionProvider>(context, listen: false);
      provider.setSearchText(value);
      MixpanelService.track("Vision searched", properties: {
        'search_query': value,
        'subject_id': widget.subjectId,
        'level_id': widget.levelId,
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final provider = Provider.of<VisionProvider>(context, listen: false);
    provider.clearSearch();
  }

  void _checkLevelCompletion(VisionProvider provider) {
    if (provider.isCurrentLevelCompleted()) {
      final currentLevel = int.tryParse(widget.levelId ?? '');
      const finalLevel = 4;

      String message = currentLevel == finalLevel
          ? '🎉 Congratulations!\nYou have completed all levels!'
          : '✅ You have successfully completed Level $currentLevel!';

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber.shade600,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Level Complete!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          final nextLevel = (int.tryParse(widget.levelId) ?? 1) + 1;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisionPage(
                                navName: widget.navName,
                                subjectId: widget.subjectId,
                                levelId: nextLevel.toString(),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "Continue to Level ${(int.tryParse(widget.levelId) ?? 1) + 1}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: StringHelper.navName,
      ),
      body: Consumer<VisionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSearchFilterBar(context, provider),
              Expanded(
                child: _buildVisionCardsList(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.black;
      case 'pending':
        return Colors.black;
      case 'submitted':
        return Colors.black;
      case 'rejected':
        return Colors.black;
      case 'skipped':
        return Colors.black;
      default:
        return Colors.black;
    }
  }

  String _getStatusLabel(VisionVideo video) {
    if (video.teacherAssigned && video.status == 'submitted') {
      return 'Submitted';
    }
    return video.status[0].toUpperCase() + video.status.substring(1);
  }

  Widget _buildSearchFilterBar(BuildContext context, VisionProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Filter button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: () {
                _showFilterPage(context, provider);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Search bar
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: provider.searchQuery.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                ) : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionCardsList(BuildContext context, VisionProvider provider) {
    // Show initial loading
    if (provider.isLoading && provider.videos.isEmpty && !provider.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading videos...'),
          ],
        ),
      );
    }

    // Show search loading
    if (provider.isSearching && provider.searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching videos...'),
          ],
        ),
      );
    }

    // Show error state
    if (provider.error.isNotEmpty && provider.videos.isEmpty && provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchVideos(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredVideos = provider.filteredVideos;

    // Show empty state for search
    if (provider.searchQuery.isNotEmpty && filteredVideos.isEmpty && !provider.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No videos found for "${provider.searchQuery}"',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    // Show empty state for no videos
    if (filteredVideos.isEmpty && !provider.isLoading && !provider.isSearching) {
      return const Center(
        child: Text('No vision videos found', style: TextStyle(fontSize: 16)),
      );
    }

    final canLoadMore = provider.currentFilter.isNotEmpty
        ? provider.canLoadMoreFilter
        : provider.searchQuery.isNotEmpty
        ? provider.canLoadMoreSearch
        : provider.canLoadMore;

    final totalVideos = provider.currentFilter.isNotEmpty
        ? provider.filterTotalVideos
        : provider.searchQuery.isNotEmpty
        ? provider.searchTotalVideos
        : provider.totalVideos;

    return RefreshIndicator(
      onRefresh: () => provider.refreshVideos(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: filteredVideos.length + (canLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end when loading more
          if (index >= filteredVideos.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          }

          final video = filteredVideos[index];
          return _buildVisionVideoCard(
            context,
            video: video,
            provider: provider,
          );
        },
      ),
    );
  }

  Widget _buildVisionVideoCard(
      BuildContext context, {
        required VisionVideo video,
        required VisionProvider provider,
      }) {
    final statusBgColor = _getStatusColor(video.status);
    final isCompleted = video.status.toLowerCase() == 'completed';

    return InkWell(
      onTap: isCompleted ? () {
        _showCompletionToast(context);
      } : () {
        _navigateToVideoPlayer(context, video, provider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Stack(
                children: [
                  FadeInImage.assetNetwork(
                    placeholder: 'assets/images/video_placeholder.png',
                    image: video.thumbnailUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.pink.shade100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library,
                                  size: 50, color: Colors.pink.shade300),
                              const SizedBox(height: 8),
                              Text(
                                'Video Preview',
                                style: TextStyle(color: Colors.pink.shade800),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusLabel(video),
                        style: TextStyle(
                          color: statusBgColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
              child: Text(
                video.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                video.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'This vision is already completed!',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToVideoPlayer(
      BuildContext context, VisionVideo video, VisionProvider provider) {
    MixpanelService.track("Vision video item clicked");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: VideoPlayerPage(
            video: video,
            navName: widget.navName,
            subjectId: widget.subjectId,
            onVideoCompleted: () {
              // This will be handled in the video player
            },
          ),
        ),
      ),
    );
  }

  void _showFilterPage(BuildContext context, VisionProvider provider) async {
    MixpanelService.track("Vision filter icon clicked");
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilterPage(
          onApplyFilters: (filters) {
            provider.setFilters(filters);
          },
          initialFilters: provider.activeFilters ?? {},
        ),
      ),
    );

    if (result != null && result is Map<String, bool>) {
      provider.setFilters(result);
    }
  }
}