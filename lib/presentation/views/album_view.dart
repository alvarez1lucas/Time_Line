import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/navigation_service.dart';
import '../bloc/photo_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/voice_control_widget.dart';
import 'video_background_view.dart';

/// Displays the contents of an album whose name is provided.
class AlbumView extends StatelessWidget {
  const AlbumView({super.key, required this.albumName});

  final String albumName;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    final matching = provider.albums.where((a) => a.name == albumName).toList();

    if (matching.isEmpty) {
      return VideoBackgroundView(
        appBar: AppBar(title: Text('Álbum: $albumName')),
        child: const Center(child: Text('Álbum no encontrado')),
      );
    }

    final photos = matching.first.photos;

    return VideoBackgroundView(
      appBar: AppBar(
        title: Text('Álbum: $albumName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final provider = Provider.of<PhotoProvider>(context, listen: false);
              final controller = TextEditingController(text: albumName);
              final result = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Renombrar álbum'),
                  content: TextField(controller: controller),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Guardar')),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty && result != albumName) {
                await provider.renameAlbum(albumName, result);
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AlbumView(albumName: result)));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar álbum'),
                  content: const Text('¿Estás seguro?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Borrar')),
                  ],
                ),
              );
              if (confirmed == true) {
                final provider = Provider.of<PhotoProvider>(context, listen: false);
                await provider.deleteAlbum(albumName);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Image.memory(photos[index].bytes, fit: BoxFit.cover);
              },
            ),
          ),
          const SizedBox(height: 16),
          VoiceControlWidget(onCommand: (cmd) => NavigationService.handleVoiceCommand(cmd, context)),
        ],
      ),
    );
  }
}
