import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/vision_video.dart';
import '../providers/vision_provider.dart';
import 'quiz_questions.dart';

class VideoPlayerPage extends StatefulWidget {
  final VisionVideo video;
  final VoidCallback? onBack;
  final Function()? onVideoCompleted;
  final String navName;
  final String subjectId;

  const VideoPlayerPage({
    Key? key,
    required this.video,
    this.onBack,
    this.onVideoCompleted,
    required this.navName,
    required this.subjectId,
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;

  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isFullscreen = false;

  // Loader & first-frame handling
  bool _showLoader = true;

  // "Play & Earn" button lock for 1s
  bool _playEarnEnabled = false;
  Timer? _unlockTimer;

  // Position/duration
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Fullscreen controls visibility
  bool _showFullscreenControls = true;
  Timer? _hideTimer;

  // Clean exit animation
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();

    final videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl) ?? '';

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        hideControls: true,       // we provide custom controls
        disableDragSeek: true,
        mute: false,
        forceHD: false,
        useHybridComposition: true, // smoother on Android, reduces glitches
      ),
    );

    _controller.addListener(_listener);

    // Enable button after 1 second (stays blue regardless)
    _unlockTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _playEarnEnabled = true);
    });
  }

  void _listener() {
    if (!mounted) return;

    final value = _controller.value;
    final position = value.position;
    final duration = _controller.metadata.duration;

    // Decide when to show the loader:
    // - Not ready yet
    // - Buffering
    // - Unstarted & no position
    final bool shouldShowLoader = !value.isReady ||
        value.playerState == PlayerState.buffering ||
        (value.playerState == PlayerState.unknown ||
            (value.playerState == PlayerState.unStarted &&
                position == Duration.zero));

    setState(() {
      _isPlaying = value.isPlaying;
      _position = position;
      _duration = duration;
      _showLoader = shouldShowLoader;

      // Completion callback
      if (duration > Duration.zero &&
          position >= duration &&
          !value.isPlaying &&
          value.playerState == PlayerState.ended) {
        widget.onVideoCompleted?.call();
      }
    });
  }

  void _togglePlayPause() => _isPlaying ? _controller.pause() : _controller.play();

  void _toggleMute() {
    _isMuted ? _controller.unMute() : _controller.mute();
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      _setFullscreenOrientation();
    } else {
      _setPortraitOrientation();
    }
  }

  void _seekTo(double value) {
    _controller.seekTo(Duration(seconds: value.toInt()));
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _setFullscreenOrientation() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _toggleFullscreenControls() {
    setState(() => _showFullscreenControls = !_showFullscreenControls);

    if (_showFullscreenControls) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showFullscreenControls = false);
        }
      });
    }
  }

  Future<bool> _handlePop() async {
    // Clean, no-splash exit
    if (_isFullscreen) {
      await _toggleFullscreen();
    }

    setState(() => _isExiting = true);
    // Brief fade-out so the player doesn't "flash" during route pop
    await Future.delayed(const Duration(milliseconds: 120));

    // Stop playback before removing view
    _controller.pause();

    widget.onBack?.call();
    Navigator.of(context).pop();
    return false; // we handled it
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    _hideTimer?.cancel();
    _unlockTimer?.cancel();
    _setPortraitOrientation();
    super.dispose();
  }

  Widget _buildLoader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _showLoader
          ? Container(
        key: const ValueKey('loader'),
        color: Colors.black.withOpacity(0.6),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      )
          : const SizedBox.shrink(key: ValueKey('no_loader')),
    );
  }

  Widget _buildPortraitControls() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _position.inSeconds
                .toDouble()
                .clamp(0, _duration.inSeconds.toDouble()),
            max: _duration.inSeconds.toDouble() > 0
                ? _duration.inSeconds.toDouble()
                : 1,
            onChanged: _seekTo,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleMute,
                  ),
                ],
              ),
              Text(
                '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / '
                    '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              IconButton(
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: _showFullscreenControls
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _toggleMute,
          ),
          Expanded(
            child: Slider(
              value: _position.inSeconds
                  .toDouble()
                  .clamp(0, _duration.inSeconds.toDouble()),
              max: _duration.inSeconds.toDouble() > 0
                  ? _duration.inSeconds.toDouble()
                  : 1,
              onChanged: _seekTo,
              activeColor: Colors.white,
              inactiveColor: Colors.white54,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_exit,
                color: Colors.white, size: 28),
            onPressed: _toggleFullscreen,
          ),
        ],
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPortraitBottomContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 5, right: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.video.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.video.subjectName ?? 'Unknown Subject'} • Level: ${widget.video.levelId ?? 'N/A'}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 0),
          _buildPortraitControls(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _playEarnEnabled
                ? () {
              _controller.pause();
              final provider =
              Provider.of<VisionProvider>(context, listen: false);
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
                      onReplayVideo: () => _controller.play(),
                    ),
                  ),
                ),
              );
            }
                : null,
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            label: const Text(
              "Play & Earn",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              // Always blue, even when disabled – use foregroundOnSurface handling
              backgroundColor: Colors.blueAccent,
              disabledBackgroundColor: Colors.blueAccent,
              disabledForegroundColor: Colors.white.withOpacity(0.6),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final videoHeight = _isFullscreen ? screenHeight : screenWidth * 9 / 16;

    final player = Stack(
      children: [
        // Fade out the player when exiting to avoid splash
        AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _isExiting ? 0 : 1,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: false,
          ),
        ),
        _buildLoader(),
      ],
    );

    return WillPopScope(
      onWillPop: _handlePop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullscreen
            ? null
            : AppBar(
          title: const Text("Vision"),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handlePop,
          ),
        ),
        body: SafeArea(
          child: _isFullscreen
              ? Stack(
            children: [
              SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: player,
              ),
              GestureDetector(
                onTap: _toggleFullscreenControls,
                child: Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: Colors.transparent,
                ),
              ),
              _buildFullscreenControls(),
            ],
          )
              : Column(
            children: [
              const Spacer(),
              SizedBox(
                width: screenWidth,
                height: videoHeight,
                child: player,
              ),
              const SizedBox(height: 25),
              _buildPortraitBottomContent(),
            ],
          ),
        ),
      ),
    );
  }
}
