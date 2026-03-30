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
  final TextEditingController _yearController = TextEditingController();
  final SpeechService _speech = SpeechService();
  bool _saving = false;
  String? _yearError;

  int? get _parsedYear {
    final v = int.tryParse(_yearController.text.trim());
    if (v == null) return null;
    if (v < 1900 || v > DateTime.now().year) return null;
    return v;
  }

  Future<void> _dictateTitle() async {
    if (await _speech.init()) {
      await _speech.startListening((words) {
        if (words.isNotEmpty) _titleController.text = words;
      }, continuous: false);
    }
  }

  Future<void> _save(PhotoProvider provider) async {
    final year = _parsedYear;
    if (year == null) {
      setState(() => _yearError = 'Ingresá un año válido (ej: 2019)');
      return;
    }
    setState(() {
      _saving = true;
      _yearError = null;
    });
    final name = _titleController.text.isNotEmpty
        ? _titleController.text
        : 'Álbum $year';
    await provider.saveAlbum(name, year: year);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AlbumsListView()),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    final photos = provider.photos;
    final selectedCount = provider.selected.length;
    final totalCount = photos.length;
    final buttonWidth = wp(context, 40);
    const buttonHeight = 55.0;
    final fontNormal = rf(context, 3.5);

    void handleVoice(String command) async {
      final cmd = command.toLowerCase().trim();
      if (cmd == 'cancelar') {
        provider.clear();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UploadView()),
          (r) => false,
        );
        return;
      }
      if (cmd == 'subir y guardar' || cmd == 'guardar') {
        if (selectedCount > 0) await _save(provider);
        return;
      }
      NavigationService.handleVoiceCommand(command, context);
    }

    return VideoBackgroundView(
      appBar: AppBar(
        title: Text('Vista previa y selección',
            style: TextStyle(fontSize: rf(context, 4.5))),
      ),
      drawer: const AppDrawer(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00ACC1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF00ACC1), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seleccionadas: $selectedCount de $totalCount',
                    style: TextStyle(
                        fontSize: fontNormal,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: provider.selectAll,
                    child: Text('Seleccionar todas',
                        style:
                            TextStyle(fontSize: fontNormal * 0.9)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Grid de fotos
          if (photos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                            child: const Icon(Icons.check_circle,
                                color: Colors.lime, size: 30),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Formulario nombre + año
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre del álbum',
                  style: TextStyle(
                      fontSize: fontNormal,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Vacaciones, Cumpleaños...',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic,
                          color: Color(0xFF00ACC1)),
                      onPressed: _dictateTitle,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AÑO — campo obligatorio
                Text(
                  '¿A qué año pertenecen estas fotos? *',
                  style: TextStyle(
                      fontSize: fontNormal,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'Ej: 2019',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                    counterText: '',
                    errorText: _yearError,
                  ),
                  onChanged: (_) {
                    if (_yearError != null) {
                      setState(() => _yearError = null);
                    }
                  },
                ),

                const SizedBox(height: 8),

                // Chips de años rápidos
                Wrap(
                  spacing: 8,
                  children: _quickYears().map((y) {
                    return ActionChip(
                      label: Text('$y'),
                      backgroundColor:
                          const Color(0xFF00ACC1).withOpacity(0.1),
                      onPressed: () {
                        _yearController.text = '$y';
                        setState(() => _yearError = null);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        MaterialPageRoute(
                            builder: (_) => const UploadView()),
                        (r) => false,
                      );
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: selectedCount > 0 && !_saving
                        ? () => _save(provider)
                        : null,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Text('Subir y Guardar',
                            textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Center(child: VoiceControlWidget(onCommand: handleVoice)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // Últimos 5 años como acceso rápido
  List<int> _quickYears() {
    final current = DateTime.now().year;
    return List.generate(5, (i) => current - i);
  }
}