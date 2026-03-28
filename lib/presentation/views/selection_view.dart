import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/photo.dart';
import '../../services/navigation_service.dart';
import '../../utils/responsive.dart';
import '../bloc/photo_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/voice_control_widget.dart';
import 'preview_selection_view.dart';
import 'video_background_view.dart';

class SelectionView extends StatefulWidget {
  const SelectionView({super.key});

  @override
  State<SelectionView> createState() => _SelectionViewState();
}

class _SelectionViewState extends State<SelectionView> {
  // nombre de la foto elegida como portada (null = primera por defecto)
  String? _coverPhotoName;
  bool _showingCoverPicker = false;

  void _handleVoice(String command) {
    final provider = Provider.of<PhotoProvider>(context, listen: false);
    final cmd = command.toLowerCase().trim();
    if (cmd == 'continuar') {
      if (provider.selected.isNotEmpty) _goNext(provider);
    } else if (cmd == 'regresar' || cmd == 'volver') {
      if (_showingCoverPicker) {
        setState(() => _showingCoverPicker = false);
      } else {
        provider.clear();
        Navigator.of(context).pop();
      }
    } else {
      NavigationService.handleVoiceCommand(command, context);
    }
  }

  void _goNext(PhotoProvider provider) {
    // marcar isCover en la foto seleccionada
    for (final photo in provider.selected) {
      photo.isCover = photo.name == (_coverPhotoName ?? provider.selected.first.name);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PreviewSelectionView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    final buttonWidth = wp(context, 50);
    final buttonHeight = hp(context, 10);
    final gap = hp(context, 4);
    final fontSize = rf(context, 3.5);

    return VideoBackgroundView(
      appBar: AppBar(
        title: Text(
          _showingCoverPicker
              ? 'Elegí la foto de portada'
              : 'Paso 2: seleccionar imágenes',
        ),
        leading: BackButton(
          onPressed: () {
            if (_showingCoverPicker) {
              setState(() => _showingCoverPicker = false);
            } else {
              provider.clear();
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      drawer: const AppDrawer(),
      child: Column(
        children: [
          // Grilla principal o picker de portada
          Expanded(
            child: _showingCoverPicker
                ? _buildCoverPicker(provider)
                : _buildSelectionGrid(provider),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Indicador de portada elegida
                if (!_showingCoverPicker && provider.selected.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _showingCoverPicker = true),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // miniatura de portada actual
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Image.memory(
                                _currentCoverPhoto(provider).bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Foto de portada',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                              const Text(
                                'Tocá para cambiar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right,
                              color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),

                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: provider.selected.isNotEmpty
                        ? _showingCoverPicker
                            ? () => setState(() => _showingCoverPicker = false)
                            : () => _goNext(provider)
                        : null,
                    child: Text(
                      _showingCoverPicker ? 'Confirmar portada' : 'Continuar',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                VoiceControlWidget(onCommand: _handleVoice),
                SizedBox(height: gap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Photo _currentCoverPhoto(PhotoProvider provider) {
    if (_coverPhotoName != null) {
      return provider.selected.firstWhere(
        (p) => p.name == _coverPhotoName,
        orElse: () => provider.selected.first,
      );
    }
    return provider.selected.first;
  }

  Widget _buildSelectionGrid(PhotoProvider provider) {
    final photos = provider.photos;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = provider.selected.contains(photo);
        final isCover = photo.name == (_coverPhotoName ?? '') ||
            (_coverPhotoName == null &&
                provider.selected.isNotEmpty &&
                photo == provider.selected.first);
        return GestureDetector(
          onTap: () => provider.toggleSelection(photo),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            elevation: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(photo.bytes, fit: BoxFit.cover),
                if (isSelected)
                  Container(
                    color: Colors.black45,
                    child: const Icon(Icons.check_circle,
                        color: Colors.lime, size: 32),
                  ),
                // Badge portada
                if (isSelected && isCover)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Portada',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverPicker(PhotoProvider provider) {
    final selected = provider.selected;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Esta foto aparecerá como vista previa en tu línea de vida',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: selected.length,
            itemBuilder: (context, index) {
              final photo = selected[index];
              final isChosen = photo.name ==
                  (_coverPhotoName ?? selected.first.name);
              return GestureDetector(
                onTap: () =>
                    setState(() => _coverPhotoName = photo.name),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isChosen
                        ? BorderSide(
                            color: Colors.amber.shade400, width: 3)
                        : BorderSide.none,
                  ),
                  elevation: isChosen ? 8 : 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(photo.bytes, fit: BoxFit.cover),
                      if (isChosen)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star,
                                color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}