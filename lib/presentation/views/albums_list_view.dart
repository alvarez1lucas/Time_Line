import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bloc/photo_bloc.dart';
import '../widgets/app_drawer.dart';
import 'album_view.dart';
import '../../utils/responsive.dart';
import 'video_background_view.dart';

/// Shows a grid of saved albums, each card displays cover photo, name,
/// count of images, and optionally year if detectable.
class AlbumsListView extends StatelessWidget {
  const AlbumsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    final albums = provider.albums;
    final fontSize = rf(context, 3.5);

    return VideoBackgroundView(
      appBar: AppBar(title: Text('Mis álbumes', style: TextStyle(fontSize: rf(context, 4.5)))),
      drawer: const AppDrawer(),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: albums.length,
        itemBuilder: (context, idx) {
          final album = albums[idx];
          final year = _extractYear(album.name);
          final cover = album.photos.isNotEmpty ? album.photos.first.bytes : Uint8List(0);
          return GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => AlbumView(albumName: album.name)));
            },
            child: Card(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (cover.isNotEmpty)
                        Expanded(child: Image.memory(cover, fit: BoxFit.cover)),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(album.name, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                            Text('${album.photos.length} fotos', style: TextStyle(fontSize: fontSize * 0.9)),
                            if (year != null) Text('Año $year', style: TextStyle(fontSize: fontSize * 0.8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar álbum'),
                            content: Text('¿Eliminar "$album.name"? Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Borrar')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await provider.deleteAlbum(album.name);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _extractYear(String text) {
    final match = RegExp(r'(19|20)\d{2}').firstMatch(text);
    return match?.group(0);
  }
}
