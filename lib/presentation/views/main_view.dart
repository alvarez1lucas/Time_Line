// Main view screen for displaying photos and voice prompts.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bloc/photo_bloc.dart';
import '../../services/file_picker_service.dart';
import '../../services/navigation_service.dart';
import '../../domain/photo.dart';
import '../../utils/responsive.dart';
import '../widgets/voice_control_widget.dart';
import 'video_background_view.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  void _handleVoiceCommand(String cmd, PhotoProvider provider, BuildContext context) {
    final lower = cmd.toLowerCase().trim();
    if (lower == 'guardar') {
      provider.saveCurrent();
      return;
    }
    if (lower == 'descartar') {
      provider.discardCurrent();
      return;
    }
    NavigationService.handleVoiceCommand(cmd, context);
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);

    return VideoBackgroundView(
      appBar: AppBar(
        title: const Text('Photo Voice Manager'),
      ),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final files = await FilePickerService().pickImages();
              final photos = files
                  .where((f) => f.bytes != null)
                  .map((f) => Photo(name: f.name, bytes: f.bytes!))
                  .toList();
              photoProvider.addAll(photos);
            },
            child: Builder(builder: (ctx) {
              return Text(
                'Select Images',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: rf(ctx, 3.5)),
              );
            }),
          ),
          const SizedBox(height: 8),
          if (photoProvider.current != null) ...[
            Expanded(
              child: Center(
                child: Image.memory(
                  photoProvider.current!.bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: VoiceControlWidget(
                onCommand: (cmd) => _handleVoiceCommand(cmd, photoProvider, context),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: photoProvider.saveCurrent,
                  child: Builder(builder: (ctx) {
                    return Text(
                      'Guardar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: rf(ctx, 3.5)),
                    );
                  }),
                ),
                ElevatedButton(
                  onPressed: photoProvider.discardCurrent,
                  child: Builder(builder: (ctx) {
                    return Text(
                      'Descartar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: rf(ctx, 3.5)),
                    );
                  }),
                ),
              ],
            ),
            const Divider(),
          ],
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photoProvider.photos.length,
              itemBuilder: (context, index) {
                final Photo photo = photoProvider.photos[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 4,
                  child: Image.memory(
                    photo.bytes,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
