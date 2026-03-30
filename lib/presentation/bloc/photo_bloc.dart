import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/photo.dart';

class PhotoAlbum {
  String name;
  final List<Photo> photos;
  final int? year; // año del álbum guardado explícitamente

  PhotoAlbum({required this.name, required this.photos, this.year});
}

class PhotoProvider extends ChangeNotifier {
  final List<Photo> _photos = [];
  int _currentIndex = 0;
  final List<Photo> _saved = [];
  final List<Photo> _discarded = [];
  final List<Photo> _selected = [];
  final List<PhotoAlbum> _albums = [];
  final Map<int, String> _coverByYear = {};

  List<PhotoAlbum> get albums => List.unmodifiable(_albums);
  List<Photo> get photos => List.unmodifiable(_photos);
  Photo? get current => (_photos.isNotEmpty && _currentIndex < _photos.length)
      ? _photos[_currentIndex]
      : null;
  List<Photo> get saved => List.unmodifiable(_saved);
  List<Photo> get discarded => List.unmodifiable(_discarded);
  List<Photo> get selected => List.unmodifiable(_selected);
  bool get hasNext => _currentIndex + 1 < _photos.length;

  Photo? coverPhotoForYear(int year, List<Photo> photos) {
    final coverName = _coverByYear[year];
    if (coverName == null) return photos.isNotEmpty ? photos.first : null;
    return photos.firstWhere(
      (p) => p.name == coverName,
      orElse: () => photos.first,
    );
  }

  Future<void> setCoverPhoto(int year, String photoName) async {
    _coverByYear[year] = photoName;
    await _saveMetadata();
    notifyListeners();
  }

  void add(Photo photo) {
    _photos.add(photo);
    notifyListeners();
  }

  void addAll(List<Photo> photos) {
    _photos.addAll(photos);
    notifyListeners();
  }

  void clear() {
    _photos.clear();
    _currentIndex = 0;
    _saved.clear();
    _discarded.clear();
    _selected.clear();
    notifyListeners();
  }

  void saveCurrent() {
    if (current != null) {
      _saved.add(current!);
      _photos.removeAt(_currentIndex);
      if (_photos.isNotEmpty && _currentIndex >= _photos.length) {
        _currentIndex = _photos.length - 1;
      }
      notifyListeners();
    }
  }

  void discardCurrent() {
    if (current != null) {
      _discarded.add(current!);
      _photos.removeAt(_currentIndex);
      if (_photos.isNotEmpty && _currentIndex >= _photos.length) {
        _currentIndex = _photos.length - 1;
      }
      notifyListeners();
    }
  }

  void toggleSelection(Photo photo) {
    if (_selected.contains(photo)) {
      _selected.remove(photo);
    } else {
      _selected.add(photo);
    }
    notifyListeners();
  }

  void selectAll() {
    _selected.clear();
    _selected.addAll(_photos);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  // year ahora es parámetro explícito obligatorio
  Future<void> saveAlbum(String name, {int? year}) async {
    if (_selected.isEmpty) return;
    final photosToSave = List<Photo>.from(_selected);

    // asignar el año a cada foto
    if (year != null) {
      for (final p in photosToSave) {
        p.year = year;
      }
    }

    // portada: la que tenga isCover, si no la primera
    final cover = photosToSave.firstWhere(
      (p) => p.isCover,
      orElse: () => photosToSave.first,
    );

    _albums.add(PhotoAlbum(name: name, photos: photosToSave, year: year));

    if (year != null) {
      _coverByYear[year] = cover.name;
      await _saveMetadata();
    }

    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/$name');
        if (!await folder.exists()) {
          await folder.create(recursive: true);
        }
        for (var photo in photosToSave) {
          final file = File('${folder.path}/${photo.name}');
          await file.writeAsBytes(photo.bytes);
        }
      } catch (e) {
        if (kDebugMode) print('failed saving album: $e');
      }
    }

    clear();
  }

  Future<void> deleteAlbum(String name) async {
    _albums.removeWhere((a) => a.name == name);
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/$name');
        if (await folder.exists()) await folder.delete(recursive: true);
      } catch (e) {
        if (kDebugMode) print('failed deleting album: $e');
      }
    }
    notifyListeners();
  }

  Future<void> renameAlbum(String oldName, String newName) async {
    if (oldName == newName) return;
    final idx = _albums.indexWhere((a) => a.name == oldName);
    if (idx == -1) return;
    _albums[idx].name = newName;
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final oldFolder = Directory('${dir.path}/$oldName');
        final newFolder = Directory('${dir.path}/$newName');
        if (await oldFolder.exists()) await oldFolder.rename(newFolder.path);
      } catch (e) {
        if (kDebugMode) print('failed renaming album: $e');
      }
    }
    notifyListeners();
  }

  Future<void> loadAlbumsFromDisk() async {
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        await _loadMetadata(dir.path);
        if (await dir.exists()) {
          for (var entity in dir.listSync()) {
            if (entity is Directory) {
              final name =
                  entity.path.split(Platform.pathSeparator).last;
              if (name == '_metadata') continue;
              final photos = <Photo>[];
              for (var fileEnt in entity.listSync()) {
                if (fileEnt is File) {
                  try {
                    final bytes = await fileEnt.readAsBytes();
                    photos.add(Photo(
                      name: fileEnt.uri.pathSegments.last,
                      bytes: bytes,
                    ));
                  } catch (_) {}
                }
              }
              // intentar recuperar año del metadata
              final year = _extractYear(name);
              _albums.add(
                  PhotoAlbum(name: name, photos: photos, year: year));
            }
          }
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) print('error loading albums: $e');
      }
    }
  }

  int? _extractYear(String text) {
    final match = RegExp(r'(19|20)\d{2}').firstMatch(text);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  Future<void> _saveMetadata() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/_metadata/covers.json');
      await file.parent.create(recursive: true);
      final data = _coverByYear.map((k, v) => MapEntry(k.toString(), v));
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      if (kDebugMode) print('error saving metadata: $e');
    }
  }

  Future<void> _loadMetadata(String basePath) async {
    try {
      final file = File('$basePath/_metadata/covers.json');
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString())
            as Map<String, dynamic>;
        raw.forEach((k, v) {
          final year = int.tryParse(k);
          if (year != null) _coverByYear[year] = v as String;
        });
      }
    } catch (e) {
      if (kDebugMode) print('error loading metadata: $e');
    }
  }
}