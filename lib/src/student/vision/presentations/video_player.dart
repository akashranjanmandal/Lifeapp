import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
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

class _VideoPlayerPageState extends State<VideoPlayerPage> {
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
  bool _playEarnButtonEnabled = false;

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
        pointer-events: none;
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
        if (event.data === YT.PlayerState.PLAYING) {
          window.flutter_inappwebview.callHandler('videoStarted');
        }
        if (event.data === YT.PlayerState.ENDED) {
          window.flutter_inappwebview.callHandler('videoEnded');
        }
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
''';
  }

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
    double seconds = await _getCurrentTime();
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

        if (_position.inSeconds >= 1 && !_playEarnButtonEnabled) {
          _playEarnButtonEnabled = true;
        }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
            max: _duration.inSeconds.toDouble(),
            onChanged: (value) {
              _seekTo(value);
              setState(() {
                _position = Duration(seconds: value.toInt());
              });
            },
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
                  const SizedBox(width: 8),
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

  Widget _buildPlayEarnButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: _playEarnButtonEnabled
            ? () {
          _pause();
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
                  onReplayVideo: () => _play(),
                ),
              ),
            ),
          );
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _playEarnButtonEnabled
              ? Colors.blueAccent
              : Colors.grey.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size(double.infinity, 50),
          elevation: 5,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        icon: const Icon(Icons.play_circle_fill, color: Colors.white),
        label: const Text(
          "Play & Earn",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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

  Widget _buildVideoPlayer(double width) {
    final videoId = extractYoutubeVideoId(widget.video.youtubeUrl);
    final videoHeight = width * 9 / 16;

    return SizedBox(
      width: width - 40,
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
                  _isPlaying = true;
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
                  setState(() => _isPlaying = true);
                  _startProgressTimer();
                } else {
                  setState(() => _isPlaying = false);
                  _progressTimer?.cancel();
                }
                return null;
              },
            );
            _webViewController.addJavaScriptHandler(
              handlerName: 'videoStarted',
              callback: (args) {
                setState(() => _playEarnButtonEnabled = true);
                return null;
              },
            );
            _webViewController.addJavaScriptHandler(
              handlerName: 'videoEnded',
              callback: (args) {
                widget.onVideoCompleted?.call();
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
  }

  @override
  Widget build(BuildContext context) {
    if (extractYoutubeVideoId(widget.video.youtubeUrl).isEmpty) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildVideoPlayer(MediaQuery.of(context).size.width)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildControls(),
            ),
          ],
        ),
      );
    } else {
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
        body: Column(
          children: [
            const Spacer(),
            _buildVideoPlayer(screenWidth),

            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.video.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4), // spacing between title and row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.video.subjectName ?? 'Unknown Subject',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Level: ${widget.video.levelId ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildControls(),
            const SizedBox(height: 20),

            _buildPlayEarnButton(),
            const SizedBox(height: 40),

          ],
        ),
      );
    }
  }
}