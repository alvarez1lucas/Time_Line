import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import '../../utils/responsive.dart';
import 'upload_view.dart'; // Import correcto según tu estructura
import 'timeline_view.dart';

class MainTimelineView extends StatefulWidget {
  const MainTimelineView({super.key});

  @override
  State<MainTimelineView> createState() => _MainTimelineViewState();
}

class _MainTimelineViewState extends State<MainTimelineView> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Para web, usamos URL de red; para otras plataformas, asset
    if (kIsWeb) {
      _controller = VideoPlayerController.network('timeline.mp4')
        ..initialize().then((_) {
          _controller.setLooping(true);
          _controller.setVolume(0);
          _controller.play();
          setState(() {});
        });
    } else {
      _controller = VideoPlayerController.asset('assets/videos/timeline.mp4')
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo de Video
          _controller.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : Container(color: Colors.black),

          // Mensaje estético en la parte superior (10% del techo)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: rf(context, 5),
                  vertical: rf(context, 3),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '¿Listo para empezar la tuya?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: rf(context, 3.5),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // Botón en la parte inferior (25% del piso)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TimelineView()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: rf(context, 6),
                    vertical: rf(context, 2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'EMPEZAR',
                  style: TextStyle(
                    fontSize: rf(context, 2.2),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}