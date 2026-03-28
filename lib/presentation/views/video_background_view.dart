import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

/// Widget que proporciona un background de video para las vistas
class VideoBackgroundView extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;

  const VideoBackgroundView({
    super.key,
    required this.child,
    this.appBar,
    this.drawer,
  });

  @override
  State<VideoBackgroundView> createState() => _VideoBackgroundViewState();
}

class _VideoBackgroundViewState extends State<VideoBackgroundView> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Para web, usamos URL de red; para otras plataformas, asset
    if (kIsWeb) {
      _controller = VideoPlayerController.network('background.mp4')
        ..initialize().then((_) {
          _controller.setLooping(true);
          _controller.setVolume(0);
          _controller.play();
          setState(() {});
        });
    } else {
      _controller = VideoPlayerController.asset('assets/videos/background.mp4')
        ..initialize().then((_) {
          _controller.setLooping(true);
          _controller.setVolume(0);
          _controller.play();
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      drawer: widget.drawer,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo de Video
          if (_controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Container(color: Colors.black),

          // Contenido de la vista encima del video
          widget.child,
        ],
      ),
    );
  }
}
