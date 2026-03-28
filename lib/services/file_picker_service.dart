// Service responsible for picking files from device storage.

import 'package:file_picker/file_picker.dart';

class FilePickerService {
  /// Opens the platform file picker allowing multiple image selection.
  ///
  /// Returns a list of `PlatformFile` representing the chosen files, or an
  /// empty list if the user cancelled.
  Future<List<PlatformFile>> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true, // so we can access bytes directly on web
    );

    if (result == null) {
      return [];
    }
    return result.files;
  }
}
