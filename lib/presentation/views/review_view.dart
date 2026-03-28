import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/navigation_service.dart';
import '../../utils/responsive.dart';
import '../bloc/photo_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/voice_control_widget.dart';
import 'upload_view.dart';
import 'video_background_view.dart';

/// Step three: display the photos the user selected.  There is also a "Volver"
/// button to let the user go back and change the selection.
class ReviewView extends StatelessWidget {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    final chosen = provider.selected;
    final buttonWidth = wp(context, 35);
    final buttonHeight = hp(context, 6.5);
    final gap = hp(context, 4);
    final fontSize = rf(context, 3.5);

    void _handleVoice(String command) {
      final cmd = command.toLowerCase().trim();
      if (cmd == 'regresar' || cmd == 'volver') {
        Navigator.of(context).pop();
        return;
      }
      if (cmd == 'finalizar' || cmd == 'subir y guardar' || cmd == 'guardar') {
        // Reuse the same flow as the Finalizar button
        final nameController = TextEditingController();
        showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Nombre de carpeta'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'vacaciones 2020'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.of(context).pop(nameController.text.trim()), child: const Text('Guardar')),
              ],
            );
          },
        ).then((result) async {
          if (result != null && result.isNotEmpty) {
            if (!context.mounted) return;
            await provider.saveAlbum(result);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Álbum "$result" guardado')));
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
          }
        });
        return;
      }
      NavigationService.handleVoiceCommand(command, context);
    }

    return VideoBackgroundView(
      appBar: AppBar(title: const Text('Paso 3: imágenes escogidas')),
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
              itemCount: chosen.length,
              itemBuilder: (context, index) {
                final photo = chosen[index];
                return Image.memory(photo.bytes, fit: BoxFit.cover);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Regresar', style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          final nameController = TextEditingController();
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Nombre de carpeta'),
                                content: TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(hintText: 'vacaciones 2020'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(null),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
                                    child: const Text('Guardar'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (result != null && result.isNotEmpty) {
                            if (!context.mounted) return;
                            await provider.saveAlbum(result);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Álbum "$result" guardado')));
                            Navigator.of(
                              context,
                            ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UploadView()), (r) => false);
                          }
                        },
                        child: Text('Finalizar', style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gap),
                SizedBox(
                  width: wp(context, 85),
                  child: VoiceControlWidget(onCommand: _handleVoice),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
