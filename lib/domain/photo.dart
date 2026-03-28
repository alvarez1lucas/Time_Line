import 'dart:typed_data';

class Photo {
  final String name;
  final Uint8List bytes;
  String description;
  bool isCover;

  Photo({
    required this.name,
    required this.bytes,
    this.description = '',
    this.isCover = false,
  });
}