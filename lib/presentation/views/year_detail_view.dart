import 'package:flutter/material.dart';
import '../../domain/photo.dart';

class YearDetailView extends StatefulWidget {
  final int year;
  final List<Photo> photos;

  const YearDetailView({
    super.key,
    required this.year,
    required this.photos,
  });

  @override
  State<YearDetailView> createState() => _YearDetailViewState();
}

class _YearDetailViewState extends State<YearDetailView> {
  late List<TextEditingController> _controllers;
  late List<bool> _isEditing;

  @override
  void initState() {
    super.initState();
    _controllers = widget.photos
        .map((p) => TextEditingController(text: p.description))
        .toList();
    _isEditing = List.filled(widget.photos.length, false);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleEdit(int index) {
    if (_isEditing[index]) {
      // guardar
      setState(() {
        widget.photos[index].description = _controllers[index].text;
        _isEditing[index] = false;
      });
    } else {
      setState(() {
        _isEditing[index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.year.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          final isEditing = _isEditing[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto grande
              GestureDetector(
                onTap: () => _showFullScreen(context, index),
                child: Hero(
                  tag: 'photo_${widget.year}_$index',
                  child: Image.memory(
                    photo.bytes,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Área de descripción
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: isEditing
                          ? TextField(
                              controller: _controllers[index],
                              autofocus: true,
                              maxLines: null,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                              decoration: InputDecoration(
                                hintText: 'Contá algo sobre este momento...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () => _toggleEdit(index),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 40),
                                child: Text(
                                  photo.description.isEmpty
                                      ? 'Tocá para agregar una descripción...'
                                      : photo.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: photo.description.isEmpty
                                        ? Colors.grey.shade400
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    // Botón editar / guardar
                    GestureDetector(
                      onTap: () => _toggleEdit(index),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isEditing ? Icons.check_circle : Icons.edit_outlined,
                          key: ValueKey(isEditing),
                          color: isEditing ? primaryColor : Colors.grey.shade400,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Nombre del archivo en muted
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  photo.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

              // Separador entre fotos
              if (index < widget.photos.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1, thickness: 0.5),
                )
              else
                const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  void _showFullScreen(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenPhoto(
          photos: widget.photos,
          initialIndex: index,
          year: widget.year,
        ),
      ),
    );
  }
}

class _FullScreenPhoto extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final int year;

  const _FullScreenPhoto({
    required this.photos,
    required this.initialIndex,
    required this.year,
  });

  @override
  State<_FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<_FullScreenPhoto> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.year}  ·  ${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return Hero(
            tag: 'photo_${widget.year}_$index',
            child: InteractiveViewer(
              child: Center(
                child: Image.memory(
                  widget.photos[index].bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}