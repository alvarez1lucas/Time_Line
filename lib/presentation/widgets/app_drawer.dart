import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bloc/photo_bloc.dart';
import '../views/upload_view.dart';
import '../views/main_timeline_view.dart';
import '../views/preview_selection_view.dart';
import '../views/albums_list_view.dart';
import '../views/album_view.dart';
import '../views/timeline_view.dart';
import '../../utils/responsive.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    // Tamaño reducido un 30% como pediste
    const double fontSizeReduced = 2.45;

    return Drawer(
      child: Container(
        color: Colors.cyan[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00ACC1), Color(0xFF006064)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Builder(builder: (ctx) {
                final fs = rf(ctx, 3.5);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text('Menú', style: TextStyle(color: Colors.white, fontSize: fs, fontWeight: FontWeight.bold)),
                  ],
                );
              }),
            ),
            // Helper para evitar repetir código de configuración de texto
            _buildDrawerTile(context, Icons.home, 'Inicio', fontSizeReduced, () {
               Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainTimelineView()), (r) => false);
            }),
            _buildDrawerTile(context, Icons.photo_library, 'Ingresar imágenes', fontSizeReduced, () {
               Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
            }),
            _buildDrawerTile(context, Icons.check_circle, 'Imágenes seleccionadas', fontSizeReduced, () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PreviewSelectionView()));
            }),
            _buildDrawerTile(context, Icons.album, 'Mis álbumes', fontSizeReduced, () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlbumsListView()));
            }),
            _buildDrawerTile(context, Icons.timeline, 'Línea de Vida', fontSizeReduced, () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimelineView()));
            }),
            
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Álbumes guardados',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: rf(context, fontSizeReduced)),
              ),
            ),
            ...provider.albums.map(
              (album) => _buildDrawerTile(context, Icons.album_outlined, album.name, fontSizeReduced, () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumView(albumName: album.name)));
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Widget reutilizable para que el texto siempre wrap-ee correctamente
  Widget _buildDrawerTile(BuildContext context, IconData icon, String title, double fontSize, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        textAlign: TextAlign.start,
        softWrap: true, // Habilita el salto de línea
        overflow: TextOverflow.visible, // Se asegura que no recorte con ...
        maxLines: null, // Permite infinitas líneas si el texto es muy largo
        style: TextStyle(fontSize: rf(context, fontSize)),
      ),
      minLeadingWidth: 20,
      onTap: onTap,
    );
  }
}