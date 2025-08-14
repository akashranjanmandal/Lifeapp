import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
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

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _playEarnButtonEnabled = false;
  bool _isFullscreen = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final yt = YoutubeExplode();
      final videoId = VideoId(widget.video.youtubeUrl);
      final streamInfo = await yt.videos.streamsClient.getManifest(videoId);
      final videoUrl = streamInfo.muxed.withHighestBitrate().url.toString();

      _videoController = VideoPlayerController.network(videoUrl)
        ..addListener(_videoListener);

      await _videoController.initialize();

      if (!mounted || _isDisposed) {
        _videoController.dispose();
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        showControls: true,
        customControls: const CupertinoControls(
          backgroundColor: Colors.black54,
          iconColor: Colors.white,
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          bufferedColor: Colors.grey,
          backgroundColor: Colors.grey.shade700,
        ),
      );

      if (!mounted || _isDisposed) {
        _chewieController?.dispose();
        _videoController.dispose();
        return;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _videoListener() {
    if (!mounted || _isDisposed) return;

    if (_videoController.value.duration == _videoController.value.position &&
        !_videoController.value.isBuffering) {
      setState(() => _playEarnButtonEnabled = true);
      widget.onVideoCompleted?.call();
    }
  }

  void _enterFullscreen() {
    setState(() => _isFullscreen = true);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _chewieController?.enterFullScreen();
  }

  void _exitFullscreen() {
    setState(() => _isFullscreen = false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _chewieController?.exitFullScreen();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _videoController.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullscreen) {
          _exitFullscreen();
          return false;
        }
        widget.onBack?.call();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasError
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 50, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load video',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                            });
                            _initializePlayer();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                      : Chewie(controller: _chewieController!),
                ),
              ),

              // Back button (only in portrait mode)
              if (!_isFullscreen)
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      widget.onBack?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ),

              // Play and Earn button (only in portrait mode)
              if (!_isFullscreen)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _playEarnButtonEnabled
                        ? () {
                      _videoController.pause();
                      final provider = Provider.of<VisionProvider>(context, listen: false);
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
                              onReplayVideo: () => _videoController.play(),
                            ),
                          ),
                        ),
                      );
                    }
                        : () {
                      Fluttertoast.showToast(
                        msg: "Please watch the video first",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.TOP,
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
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
    );
  }
}