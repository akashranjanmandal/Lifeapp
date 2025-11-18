import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/vision_model.dart';
import '../providers/vision_provider.dart';
import 'student_assign.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';

class TeacherVideoPlayerPage extends StatefulWidget {
  final TeacherVisionVideo video;
  final VoidCallback? onBack;
  final String sectionId;
  final String gradeId;
  final String classId;

  const TeacherVideoPlayerPage({
    Key? key,
    required this.video,
    this.onBack,
    required this.sectionId,
    required this.gradeId,
    required this.classId,
  }) : super(key: key);

  @override
  State<TeacherVideoPlayerPage> createState() => _TeacherVideoPlayerPageState();
}

class _TeacherVideoPlayerPageState extends State<TeacherVideoPlayerPage>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;

  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isFullscreen = false;
  bool _showControls = true;

  // Enable button only after 1s of actual playback
  bool _playAssignButtonEnabled = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _hideTimer;

  // Loader until video starts + smooth fade-out on back
  bool _showInitialLoader = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();

    final videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        hideControls: true,
        disableDragSeek: true,
        forceHD: false,
        mute: false,
      ),
    )..addListener(_listener);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.value = 1.0; // visible initially
  }

  void _listener() {
    if (!mounted) return;
    final val = _controller.value;

    // duration can be null pre-metadata; guard it
    final metaDuration = _controller.metadata.duration;
    final isPlayingNow = val.isPlaying;

    setState(() {
      _isPlaying = isPlayingNow;
      _position = val.position;
      _duration = metaDuration == null || metaDuration == Duration.zero
          ? _duration
          : metaDuration;

      // Show loader until video *actually starts* (first frame / playing or position > 0)
      if (_showInitialLoader && (isPlayingNow || _position > Duration.zero)) {
        _showInitialLoader = false;
      }

      // Enable after 1s of playback time
      if (!_playAssignButtonEnabled && _position.inMilliseconds >= 1000) {
        _playAssignButtonEnabled = true;
      }
    });
  }

  // ---- Controls
  void _togglePlayPause() => _isPlaying ? _controller.pause() : _controller.play();

  void _toggleMute() {
    _isMuted ? _controller.unMute() : _controller.mute();
    setState(() => _isMuted = !_isMuted);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        _setFullscreenOrientation();
      } else {
        _setPortraitOrientation();
      }
    });
  }

  void _seekTo(double value) {
    _controller.seekTo(Duration(seconds: value.toInt()));
  }

  // ---- Orientation / System UI
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _setFullscreenOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _toggleFullscreenControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  // Smooth fade-out to avoid laggy splash of player when leaving
  Future<void> _fadeOutAndPop() async {
    try {
      _controller.pause();
      // Seek to start so the last frame isn't flashed
      _controller.seekTo(Duration.zero);
    } catch (_) {}
    await _fadeCtrl.reverse(); // fade to 0
    _setPortraitOrientation();
    if (mounted) {
      widget.onBack?.call();
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    await _fadeOutAndPop();
    return false; // we handle pop ourselves
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    _hideTimer?.cancel();
    _fadeCtrl.dispose();
    _setPortraitOrientation();
    super.dispose();
  }

  // ---- UI widgets
  Widget _buildControls({bool overlayMode = false}) {
    return overlayMode
        ? Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 36),
          onPressed: _togglePlayPause,
        ),
        IconButton(
          icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white, size: 30),
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
              color: Colors.white, size: 30),
          onPressed: _toggleFullscreen,
        ),
      ],
    )
        : Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.video.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.video.level,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 20),
            Text(widget.video.subject,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        Slider(
          value: _position.inSeconds
              .toDouble()
              .clamp(0, _duration.inSeconds.toDouble()),
          max: _duration.inSeconds.toDouble() > 0
              ? _duration.inSeconds.toDouble()
              : 1,
          onChanged: _seekTo,
          activeColor: Colors.deepPurple,
          inactiveColor: Colors.grey,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 36),
              onPressed: _togglePlayPause,
            ),
            IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white, size: 30),
              onPressed: _toggleMute,
            ),
            Text(
              '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / '
                  '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: Icon(
                  _isFullscreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: Colors.white,
                  size: 30),
              onPressed: _toggleFullscreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _playAssignButtonEnabled
              ? () {
            _controller.pause();
            final visionProvider =
            Provider.of<TeacherVisionProvider>(context, listen: false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider<TeacherVisionProvider>.value(
                        value: visionProvider),
                    ChangeNotifierProvider<TeacherDashboardProvider>.value(
                      value: Provider.of<TeacherDashboardProvider>(context,
                          listen: false),
                    ),
                  ],
                  child: StudentAssignPage(
                    videoTitle: widget.video.title,
                    videoId: widget.video.id,
                    gradeId: widget.gradeId,
                    subjectId: '2',
                    sectionId: widget.sectionId,
                    classId: widget.classId,
                  ),
                ),
              ),
            );
          }
              : null,
          icon: const Icon(Icons.assignment, color: Colors.white),
          label: const Text(
            "Assign Vision",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            disabledBackgroundColor:
            Colors.deepPurple,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            minimumSize: const Size(double.infinity, 55),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final videoHeight =
    isPortrait ? screenSize.width * 9 / 16 : screenSize.height;

    final videoWidget = SizedBox(
      width: screenSize.width,
      height: videoHeight,
      child: Stack(
        children: [
          // Fade keeps transitions smooth to avoid flash on back
          FadeTransition(
            opacity: _fade,
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: false,
              // When ready doesn't guarantee playback; loader hides until playing/position>0
              onReady: () {
                // no-op; _listener will hide loader when playback/position updates
              },
            ),
          ),
          // Initial loader overlay until the video starts actually playing
          if (_showInitialLoader)
            Positioned.fill(
              child: Container(
                color: Colors.black, // solid to mask any white flash
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (_isFullscreen) {
      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleFullscreenControls,
                  child: Container(color: Colors.black),
                ),
              ),
              Center(child: videoWidget),
              if (_showControls)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.transparent,
                    child: _buildControls(overlayMode: true),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text("Vision"),
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _fadeOutAndPop, // smooth fade to avoid splash
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                videoWidget,
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildControls(),
                ),
                _buildAssignButton(),
              ],
            ),
          ),
        ),
      );
    }
  }
}
