import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/file_picker_service.dart';
import '../../services/navigation_service.dart';
import '../../domain/photo.dart';
import '../bloc/photo_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/voice_control_widget.dart';
import '../../utils/responsive.dart';
import 'selection_view.dart';
import 'video_background_view.dart';

/// First step: allow user to pick images from the device.  After the
/// user chooses at least one image we navigate to the selection screen so the
/// user can indicate which ones they want to keep for the workflow.
class UploadView extends StatelessWidget {
  const UploadView({super.key, this.suggestedYear});

  final int? suggestedYear;

  Future<void> _pickImages(BuildContext context) async {
    final files = await FilePickerService().pickImages();
    if (!context.mounted) return;
    final provider = Provider.of<PhotoProvider>(context, listen: false);
    provider.clear(); // start fresh on each upload attempt

    final photos = files.where((f) => f.bytes != null).map((f) => Photo(name: f.name, bytes: f.bytes!)).toList();

    if (photos.isNotEmpty) {
      provider.addAll(photos);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectionView()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonWidth = screenWidth * 0.7;
    final buttonHeight = screenHeight * 0.12; // increased from 0.08


    // ensure any saved albums from previous runs are loaded once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PhotoProvider>(context, listen: false);
      provider.loadAlbumsFromDisk();
    });

    return VideoBackgroundView(
      appBar: AppBar(title: const Text('Paso 1: cargar imágenes')),
      drawer: const AppDrawer(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => _pickImages(context),
                    child: Builder(builder: (ctx) {
                      return Text(
                        'Seleccionar imágenes',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(fontSize: rf(ctx, 3.5), fontWeight: FontWeight.w600),
                      );
                    }),
                  ),
                ),
                SizedBox(height: screenHeight * 0.15),
                SizedBox(
                  width: screenWidth * 0.8,
                  child: VoiceControlWidget(onCommand: (cmd) => NavigationService.handleVoiceCommand(cmd, context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
