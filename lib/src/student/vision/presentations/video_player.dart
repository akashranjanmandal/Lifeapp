import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/vision_video.dart';
import 'quiz_questions.dart';
import '../providers/vision_provider.dart';

class VideoPlayerPage extends StatefulWidget {
  final VisionVideo video;
  final VoidCallback? onBack;
  final Function()? onVideoCompleted;
  final String navName;
  final String subjectId;

  const VideoPlayerPage({
    super.key,
    required this.video,
    this.onBack,
    this.onVideoCompleted,
    required this.navName,
    required this.subjectId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;
  bool _isMuted = false;
  bool _isPlayerReady = false;
  bool _isPlaying = true;
  bool _playEarnButtonEnabled = false;
  bool _isNavigatingBack = false;
  bool _showBackLoader = false;
  late String videoId;
  double _currentPosition = 0;
  double _videoDuration = 1;
  final bool _showOverlay = true;
  bool _isFullscreen = false;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _pageFadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    videoId = VisionVideo.getVideoIdFromUrl(widget.video.youtubeUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId.isNotEmpty ? videoId : 'dQw4w9WgXcQ',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
      ),
    );

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (_controller.value.isReady && mounted) {
      final position = _controller.value.position.inSeconds.toDouble();
      final duration = _controller.metadata.duration.inSeconds.toDouble();

      setState(() {
        _isPlayerReady = true;
        _currentPosition = position;
        _videoDuration = duration > 0 ? duration : 1;
        _isPlaying = _controller.value.isPlaying;
        _isLoading = false;
        _isFullscreen = _controller.value.isFullScreen;
        _playEarnButtonEnabled = position >= 1;
      });

      if (_isFullscreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _fadeController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  String _formatDuration(double seconds) {
    final Duration duration = Duration(seconds: seconds.round());
    final String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  void _handleBackButton() async {
    if (_isFullscreen) {
      _controller.toggleFullScreenMode();
    } else {
      setState(() {
        _isNavigatingBack = true;
      });

      _controller.pause();
      _controller.removeListener(_videoListener);

      await _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted) {
        widget.onBack?.call();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return WillPopScope(
      onWillPop: () async {
        _handleBackButton();
        return false;
      },
      child: FadeTransition(
        opacity: _pageFadeAnimation,
        child: IgnorePointer(
          ignoring: _isNavigatingBack,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                if (!_isNavigatingBack)
                  Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        children: [
                          YoutubePlayerBuilder(
                            player: YoutubePlayer(
                              controller: _controller,
                              showVideoProgressIndicator: false,
                              progressColors: const ProgressBarColors(
                                playedColor: Colors.deepPurple,
                                handleColor: Colors.deepPurpleAccent,
                              ),
                              onReady: () {
                                setState(() {
                                  _isPlayerReady = true;
                                  _isLoading = false;
                                });
                              },
                              onEnded: (_) => widget.onVideoCompleted?.call(),
                            ),
                            builder: (_, player) => player,
                          ),
                          if (_isLoading)
                            Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                if (_showBackLoader)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                if (_showOverlay)
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _handleBackButton,
                        ),
                        const Text(
                          'Vision',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                if (_showOverlay)
                  Positioned(
                    bottom: 90,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            widget.video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _isPlaying ? _controller.pause() : _controller.play();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isMuted ? Icons.volume_off : Icons.volume_up,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isMuted = !_isMuted;
                                      _isMuted ? _controller.mute() : _controller.unMute();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                                  onPressed: () => _controller.toggleFullScreenMode(),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                "${_formatDuration(_currentPosition)} / ${_formatDuration(_videoDuration)}",
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          min: 0,
                          max: _videoDuration,
                          value: _currentPosition.clamp(0, _videoDuration),
                          onChanged: (value) => setState(() => _currentPosition = value),
                          onChangeEnd: (value) => _controller.seekTo(Duration(seconds: value.toInt())),
                          activeColor: Colors.deepPurple,
                          inactiveColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                if (!_isFullscreen && isPortrait)
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: _playEarnButtonEnabled
                          ? () {
                        _controller.pause();
                        final provider = Provider.of<VisionProvider>(context, listen: false);
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: provider,
                                child: QuizScreen(
                                  videoTitle: widget.video.title,
                                  visionId: widget.video.id,
                                  navName: widget.navName,
                                  subjectId: widget.subjectId,
                                  onReplayVideo: () {
                                    if (mounted) {
                                      _controller.play();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                      }
                          : () {
                        Fluttertoast.showToast(
                          msg: "Play and Earn button will be available after 1 seconds",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.TOP,
                          timeInSecForIosWeb: 2,
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                          fontSize: 16.0,
                          webBgColor: "linear-gradient(to right, #ffecd2, #fcb69f)",
                          webPosition: "center",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _playEarnButtonEnabled
                            ? Colors.blueAccent
                            : Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Play and earn",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                        ],
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
}
