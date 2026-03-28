import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/speech_service.dart';
import '../../utils/responsive.dart';
import '../bloc/photo_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/voice_control_widget.dart';
import '../../services/navigation_service.dart';
import 'upload_view.dart';
import 'albums_list_view.dart';
import 'video_background_view.dart';

class PreviewSelectionView extends StatefulWidget {
  const PreviewSelectionView({super.key});

  @override
  State<PreviewSelectionView> createState() => _PreviewSelectionViewState();
}

class _PreviewSelectionViewState extends State<PreviewSelectionView> {
  final TextEditingController _titleController = TextEditingController();
  final SpeechService _speech = SpeechService();
  String? _suggestedTitle;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSuggestYear());
  }

  Future<void> _maybeSuggestYear() async {
    final provider = Provider.of<PhotoProvider>(context, listen: false);
    final years = <String>{};
    for (var photo in provider.photos) {
      final y = _extractYearFromName(photo.name);
      if (y != null) years.add(y);
    }
    if (years.length == 1) {
      setState(() {
        _suggestedTitle = years.first;
      });
    }
  }

  String? _extractYearFromName(String name) {
    final regex = RegExp(r'(19|20)\d{2}');
    final match = regex.firstMatch(name);
    return match?.group(0);
  }

  Future<void> _dictateTitle() async {
    if (await _speech.init()) {
      await _speech.startListening((words) {
        if (words.isNotEmpty) {
          _titleController.text = words;
        }
      }, continuous: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    final photos = provider.photos;
    final selectedCount = provider.selected.length;
    final totalCount = photos.length;

    // Ajustes de tamaño responsivo para botones
    final buttonWidth = wp(context, 40);
    final buttonHeight = 55.0; 
    final fontNormal = rf(context, 3.5);

    void _handleVoice(String command) async {
      final cmd = command.toLowerCase().trim();

      if (cmd == 'cancelar') {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
        return;
      }
      if (cmd == 'subir y guardar' || cmd == 'guardar') {
        if (selectedCount > 0) {
          setState(() => _saving = true);
          final name = _titleController.text.isNotEmpty ? _titleController.text : (_suggestedTitle ?? 'Álbum');
          await provider.saveAlbum(name);
          if (!context.mounted) return;
          setState(() => _saving = false);
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AlbumsListView()));
        }
        return;
      }

      if (cmd == 'finalizar') {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
        return;
      }

      NavigationService.handleVoiceCommand(command, context);
    }

    return VideoBackgroundView(
      appBar: AppBar(
        title: Text('Vista previa y selección', style: TextStyle(fontSize: rf(context, 4.5))),
      ),
      drawer: const AppDrawer(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 1. Contador de selección
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00ACC1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00ACC1), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seleccionadas: $selectedCount de $totalCount',
                    style: TextStyle(fontSize: fontNormal, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: provider.selectAll,
                    child: Text('Seleccionar todas', style: TextStyle(fontSize: fontNormal * 0.9)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Grid de fotos
          if (photos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                final isSelected = provider.selected.contains(photo);
                return GestureDetector(
                  onTap: () => provider.toggleSelection(photo),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(photo.bytes, fit: BoxFit.cover),
                        if (isSelected)
                          Container(
                            color: Colors.black38,
                            child: const Icon(Icons.check_circle, color: Colors.lime, size: 30),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // 3. Formulario del nombre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ponle un nombre a este grupo de fotos',
                  style: TextStyle(fontSize: fontNormal, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Nombre del álbum',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic, color: Color(0xFF00ACC1)),
                      onPressed: _dictateTitle,
                    ),
                  ),
                ),
                if (_suggestedTitle != null) ...[
                  const SizedBox(height: 12),
                  ActionChip(
                    backgroundColor: const Color(0xFF00ACC1).withOpacity(0.1),
                    label: Text('Usar año sugerido: $_suggestedTitle'),
                    onPressed: () => _titleController.text = _suggestedTitle!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 40), // Espacio visual antes de los botones

          // 4. Botones de acción (ahora parte del scroll)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                    onPressed: () {
                      provider.clear();
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: selectedCount > 0 && !_saving
                        ? () async {
                            setState(() => _saving = true);
                            final name = _titleController.text.isNotEmpty
                                ? _titleController.text
                                : (_suggestedTitle ?? 'Álbum');
                            await provider.saveAlbum(name);
                            if (!context.mounted) return;
                            setState(() => _saving = false);
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const AlbumsListView()));
                          }
                        : null,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Subir y Guardar', textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: VoiceControlWidget(onCommand: _handleVoice),
          ),
          const SizedBox(height: 60), // EL "SECRETO": Espacio extra al final para que no se corte
        ],
      ),
    );
  }
}