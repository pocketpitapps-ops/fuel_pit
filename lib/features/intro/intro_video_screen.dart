import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../main.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late VideoPlayerController _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.asset(
            'assets/intro.mp4',
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..initialize().then((_) async {
            // Garante que o vídeo começa no frame 0
            await _controller.seekTo(Duration.zero);
            if (!mounted) return;
            setState(() {});
            _controller.play();
          });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    final value = _controller.value;

    if (!value.isInitialized) return;
    if (_navigated) return;

    final position = value.position;
    final duration = value.duration;

    if (duration.inMilliseconds == 0) return;

    // tolerância de 200 ms para evitar problemas de arredondamento
    final isCompleted =
        position.inMilliseconds >= duration.inMilliseconds - 200;

    if (isCompleted) {
      _goToApp();
    }
  }

  void _goToApp() {
    if (!mounted) return;
    _navigated = true;
    _controller.removeListener(_videoListener);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthOrHomeRoot()),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: TextButton(
              onPressed: _goToApp,
              child: const Text('Skip', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
