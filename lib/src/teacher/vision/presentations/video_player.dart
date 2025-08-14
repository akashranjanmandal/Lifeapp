import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

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

class _TeacherVideoPlayerPageState extends State<TeacherVideoPlayerPage> {
  late InAppWebViewController _webViewController;
  Duration _lastPlaybackPosition = Duration.zero;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDisposed = false;
  bool _isFullscreen = false;
  bool _isMuted = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration(minutes: 1);

  Timer? _progressTimer;
  bool _showControls = true;

  String extractYoutubeVideoId(String url) {
    try {
      Uri uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      } else if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'] ?? '';
      } else {
        return '';
      }
    } catch (_) {
      return '';
    }
  }

  String _html(String videoId) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <style>
      body, html {
        margin: 0;
        background-color: black;
        height: 100%;
        overflow: hidden;
      }
      iframe {
        pointer-events: none; /* prevent brief UI display */
      }
      #player {
        position: absolute;
        top: 0; left: 0; right: 0; bottom: 0;
        width: 100%;
        height: 100%;
      }
    </style>
  </head>
  <body>
    <div id="player"></div>
    <script>
      var tag = document.createElement('script');
      tag.src = "https://www.youtube.com/iframe_api";
      var firstScriptTag = document.getElementsByTagName('script')[0];
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

      var player;
      var lastPosition = ${(_lastPlaybackPosition.inMilliseconds / 1000).toStringAsFixed(2)};

      function onYouTubeIframeAPIReady() {
        player = new YT.Player('player', {
          height: '100%',
          width: '100%',
          videoId: '$videoId',
          playerVars: {
            controls: 0,
            modestbranding: 1,
            rel: 0,
            showinfo: 0,
            autoplay: 1,
            disablekb: 1,
            fs: 0
          },
          events: {
            'onReady': onPlayerReady,
            'onStateChange': onPlayerStateChange
          }
        });
      }

      function onPlayerReady(event) {
        if (lastPosition > 0) {
          player.seekTo(lastPosition, true);
        }
        window.flutter_inappwebview.callHandler('playerReady');
        player.playVideo();
      }

      function onPlayerStateChange(event) {
        window.flutter_inappwebview.callHandler('playerStateChange', event.data);
      }

      function playVideo() { player.playVideo(); }
      function pauseVideo() { player.pauseVideo(); }
      function muteVideo() { player.mute(); }
      function unMuteVideo() { player.unMute(); }
      function getCurrentTime() { return player.getCurrentTime(); }
      function getDuration() { return player.getDuration(); }
      function seekTo(seconds) { player.seekTo(seconds, true); }
    </script>
  </body>
</html>
''';  }

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();
  }

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

  Future<void> _play() async {
    await _webViewController.evaluateJavascript(source: 'playVideo();');
  }

  Future<void> _pause() async {
    await _webViewController.evaluateJavascript(source: 'pauseVideo();');
  }

  Future<void> _mute() async {
    await _webViewController.evaluateJavascript(source: 'muteVideo();');
  }

  Future<void> _unMute() async {
    await _webViewController.evaluateJavascript(source: 'unMuteVideo();');
  }

  Future<double> _getCurrentTime() async {
    final result = await _webViewController.evaluateJavascript(source: 'getCurrentTime();');
    if (result == null) return 0;
    return double.tryParse(result.toString()) ?? 0;
  }

  Future<double> _getDuration() async {
    final result = await _webViewController.evaluateJavascript(source: 'getDuration();');
    if (result == null) return 0;
    return double.tryParse(result.toString()) ?? 0;
  }

  Future<void> _seekTo(double seconds) async {
    await _webViewController.evaluateJavascript(source: 'seekTo($seconds);');
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _pause();
    } else {
      await _play();
    }

  }

  void _toggleMute() async {
    if (_isMuted) {
      await _unMute();
    } else {
      await _mute();
    }
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleFullscreen() async {
    // get current time as double seconds
    double seconds = await _getCurrentTime();

    // convert to Duration
    _lastPlaybackPosition = Duration(milliseconds: (seconds * 1000).toInt());

    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        _setFullscreenOrientation();
      } else {
        _setPortraitOrientation();
      }
    });
  }
  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      final pos = await _getCurrentTime();
      final dur = await _getDuration();

      setState(() {
        _position = Duration(seconds: pos.toInt());
        _duration = Duration(seconds: dur.toInt());
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _isDisposed = true;
    _setPortraitOrientation();
    super.dispose();
  }

  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.video.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [
                Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(0, 1)),
              ],
            ),
          ),
          const SizedBox(height: 10), // smaller gap than 10
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.video.level,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(0, 1)),
                  ],
                ),
              ),
              const SizedBox(width: 30), // space between level & subject
              Text(
                widget.video.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0), // reduce slider padding
            child: Slider(
              value: _position.inSeconds
                  .toDouble()
                  .clamp(0, _duration.inSeconds.toDouble()),
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) {
                _seekTo(value);
                setState(() {
                  _position = Duration(seconds: value.toInt());
                });
              },
              activeColor: Colors.deepPurple,
              inactiveColor: Colors.grey,
            ),
          ),
          Padding(
            padding: EdgeInsets.zero, // reduce gap from top
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _toggleMute,
                ),
                Text(
                  '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / '
                      '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          )
        ]
    );
  }

  Widget _buildAssignButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () {
            _pause();
            final visionProvider = Provider.of<VisionProvider>(context, listen: false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider<VisionProvider>.value(value: visionProvider),
                    ChangeNotifierProvider<TeacherDashboardProvider>.value(
                      value: Provider.of<TeacherDashboardProvider>(context, listen: false),
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
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            minimumSize: const Size(double.infinity, 55),
          ),
          icon: const Icon(Icons.assignment, color: Colors.white),
          label: const Text(
            "Assign Vision",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text("Video unavailable", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _webViewController.reload();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoId = extractYoutubeVideoId(widget.video.youtubeUrl);
    if (videoId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Vision"),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              widget.onBack?.call();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
          child: Text(
            "Invalid YouTube URL",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // In portrait, video height based on width and 16:9 aspect ratio
    final videoHeight = isPortrait ? screenSize.width * 9 / 16 : screenSize.height;

    Widget videoPlayerWidget = SizedBox(
      width: screenSize.width,
      height: videoHeight,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: InAppWebView(
          initialData: InAppWebViewInitialData(data: _html(videoId)),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              mediaPlaybackRequiresUserGesture: false,
              useShouldOverrideUrlLoading: true,
              javaScriptCanOpenWindowsAutomatically: false,
            ),
            android: AndroidInAppWebViewOptions(
              useHybridComposition: true,
            ),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
              allowsAirPlayForMediaPlayback: true,
            ),
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _progressTimer?.cancel();
            _isLoading = true;
            _hasError = false;

            _webViewController.addJavaScriptHandler(
              handlerName: 'playerReady',
              callback: (args) {
                setState(() {
                  _isLoading = false;
                  _isPlaying = true; // autoplay started
                });
                _startProgressTimer();
                return null;
              },
            );
            _webViewController.addJavaScriptHandler(
              handlerName: 'playerStateChange',
              callback: (args) {
                int state = args[0];
                if (state == 1) {
                  setState(() {
                    _isPlaying = true;
                  });
                  _startProgressTimer();
                } else {
                  setState(() {
                    _isPlaying = false;
                  });
                  _progressTimer?.cancel();
                }
                return null;
              },
            );
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final uri = navigationAction.request.url;
            if (uri == null) return NavigationActionPolicy.CANCEL;

            if (uri.host.contains("youtube.com") || uri.host.contains("youtu.be")) {
              return NavigationActionPolicy.ALLOW;
            }
            return NavigationActionPolicy.CANCEL;
          },
          onLoadError: (controller, url, code, message) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "Failed to load video",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.white,
              textColor: Colors.black87,
            );
          },
          onLoadHttpError: (controller, url, statusCode, description) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("Console: ${consoleMessage.message}");
          },
        ),
      ),
    );

    if (_isFullscreen) {
      // Fullscreen: video takes full screen, controls overlay at bottom inside Stack
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: videoPlayerWidget),
            if (_showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: _buildControls(),
                ),
              ),
          ],
        ),
      );
    } else {
      // Portrait or normal mode: video + controls below with small gap
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Vision"),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              widget.onBack?.call();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // 16:9 centered video on top
              AspectRatio(
                aspectRatio: 16 / 9,
                child: videoPlayerWidget,
              ),
              const SizedBox(height: 60),

              // Expanded to push the rest to bottom

              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white),
              if (_hasError)
                _buildErrorUI()
              else if (!_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildControls(),
                ),

              const SizedBox(height: 0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildAssignButton(context),
              ),

              const SizedBox(height: 15), // gap from bottom of screen
            ],
          ),
        ),
      );
    }
  }

}
