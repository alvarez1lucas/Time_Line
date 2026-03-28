import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/bloc/photo_bloc.dart';
import '../presentation/views/upload_view.dart';
import '../presentation/views/preview_selection_view.dart';
import '../presentation/views/albums_list_view.dart';
import '../presentation/views/album_view.dart';
import 'voice_keywords.dart';

/// Helper for interpreting voice commands that relate to navigation.
/// Uses [VoiceKeywords] dictionary for flexible keyword matching.
class NavigationService {
  static void handleVoiceCommand(String command, BuildContext context) {
    if (command.isEmpty) return;

    // Go home/main menu
    if (VoiceKeywords.matchesKeyword(command, VoiceKeywords.goHome)) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
      _showFeedback(context, '🏠 Volviendo al inicio');
      return;
    }

    // Upload images
    if (VoiceKeywords.matchesKeyword(command, VoiceKeywords.uploadImages)) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
      _showFeedback(context, '📁 Cargando imágenes');
      return;
    }

    // View selected images
    if (VoiceKeywords.matchesKeyword(command, VoiceKeywords.viewSelected)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PreviewSelectionView()));
      _showFeedback(context, '👁 Mostrando seleccionadas');
      return;
    }

    // Show albums list
    if (VoiceKeywords.matchesKeyword(command, VoiceKeywords.viewAlbums)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlbumsListView()));
      _showFeedback(context, '📚 Mostrando mis álbumes');
      return;
    }

    // Open album by name
    final cmd = command.toLowerCase();
    if (cmd.contains('album') || cmd.contains('álbum')) {
      final name = cmd.replaceFirst(RegExp(r'albu[mú]m?\s*'), '').trim();
      if (name.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumView(albumName: name)));
        _showFeedback(context, '📄 Abriendo: $name');
      }
      return;
    }

    // select all photos
    if (VoiceKeywords.matchesKeyword(command, VoiceKeywords.selectAllPhotos)) {
      try {
        final provider = Provider.of<PhotoProvider>(context, listen: false);
        provider.selectAll();
        _showFeedback(context, '✅ Seleccionadas todas las fotos');
      } catch (_) {}
      return;
    }

    // Help command
    if (VoiceKeywords.matchesKeyword(command, VoiceKeywords.helpCommand)) {
      _showFeedback(context, '✅ Puedo: ir al menú, cargar fotos, ver seleccionadas, abrir álbumes');
      return;
    }

    // Command not recognized
    _showFeedback(context, '❌ No entendí: "$command"');
  }

  static void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
      ),
    );
  }
}
