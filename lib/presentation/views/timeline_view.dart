import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/photo.dart';
import '../bloc/photo_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/voice_control_widget.dart';
import '../widgets/timeline_node_painter.dart';
import 'upload_view.dart';
import 'year_detail_view.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  static const double _nodeSpacing = 80.0;
  static const double _timelineHeight = 200.0;
  static const double _axisY = 130.0;
  static const double _thumbSize = 48.0;

  int? _selectedYear;
  final ScrollController _scrollController = ScrollController();
  int? _birthYear;
  bool _isLoadingBirthYear = true;

  @override
  void initState() {
    super.initState();
    _loadBirthYear();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBirthYear() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _birthYear = prefs.getInt('birth_year');
      _isLoadingBirthYear = false;
    });
  }

  Future<void> _saveBirthYear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('birth_year', year);
    setState(() {
      _birthYear = year;
      _selectedYear = null;
    });
  }

  // Deriva _photosByYear directo del provider en cada build
  Map<int, List<Photo>> _groupPhotosByYear(PhotoProvider provider) {
  final Map<int, List<Photo>> grouped = {};
  for (var album in provider.albums) {
    for (var photo in album.photos) {
      // prioridad: año explícito del photo, luego año del álbum, luego regex del nombre
      final year = photo.year
          ?? album.year
          ?? _extractYearFromName(photo.name)
          ?? _extractYearFromName(album.name);
      if (year != null) {
        grouped.putIfAbsent(year, () => []).add(photo);
      }
    }
  }
  return grouped;
 }

  int? _extractYearFromName(String name) {
    final regex = RegExp(r'(19|20)\d{2}');
    final match = regex.firstMatch(name);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  List<int> _buildYearList(Map<int, List<Photo>> photosByYear) {
    if (_birthYear == null) {
      return photosByYear.keys.toList()..sort();
    }
    final current = DateTime.now().year;
    final set = <int>{};
    for (int y = _birthYear!; y <= current; y++) {
      if ((y - _birthYear!) % 5 == 0) set.add(y);
      if (photosByYear.containsKey(y)) set.add(y);
    }
    return set.toList()..sort();
  }

  int _getNodeSize(int year, Map<int, List<Photo>> photosByYear) {
    final count = photosByYear[year]?.length ?? 0;
    if (count == 0) return 7;
    if (count <= 3) return 11;
    return 16;
  }

  double _getLineThickness(
    int year1,
    int year2,
    Map<int, List<Photo>> photosByYear,
  ) {
    final count1 = photosByYear[year1]?.length ?? 0;
    final count2 = photosByYear[year2]?.length ?? 0;
    final density = (count1 + count2) / 2.0;
    final total = photosByYear.values.expand((e) => e).length;
    final length = photosByYear.length;
    if (total == 0 || length == 0) return 1.5;
    final maxDensity = total / length.toDouble();
    return 1.5 + (density / maxDensity) * 2.5;
  }

  Future<void> _showBirthYearPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Seleccioná tu año de nacimiento',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );
    if (picked != null) await _saveBirthYear(picked.year);
  }

  void _onYearTap(int year, Map<int, List<Photo>> photosByYear) {
    final hasPhotos = photosByYear[year]?.isNotEmpty ?? false;
    if (hasPhotos) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => YearDetailView(
            year: year,
            photos: photosByYear[year]!,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UploadView(suggestedYear: year),
        ),
      );
    }
  }

  void _handleVoice(String command) {
    final cmd = command.toLowerCase().trim();
    if (cmd == 'cancelar' || cmd == 'volver') Navigator.of(context).pop();
  }

  Widget _buildThumb(
    int year,
    int index,
    Color primaryColor,
    Map<int, List<Photo>> photosByYear,
    PhotoProvider provider,
  ) {
    final photos = photosByYear[year];
    if (photos == null || photos.isEmpty) return const SizedBox.shrink();

    final coverPhoto = provider.coverPhotoForYear(year, photos);
    if (coverPhoto == null) return const SizedBox.shrink();

    final x = index * _nodeSpacing;

    return Positioned(
      left: x - _thumbSize / 2,
      top: _axisY - _thumbSize - 24,
      child: GestureDetector(
        onTap: () => _onYearTap(year, photosByYear),
        child: Container(
          width: _thumbSize,
          height: _thumbSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  coverPhoto.bytes,
                  fit: BoxFit.cover,
                ),
                if (photos.length > 1)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${photos.length - 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // listen: true — rebuilda automáticamente cuando el provider cambia
    final provider = Provider.of<PhotoProvider>(context);
    final photosByYear = _groupPhotosByYear(provider);
    final years = _buildYearList(photosByYear);

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final totalWidth = years.length * _nodeSpacing + 80;

    if (_isLoadingBirthYear) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Línea de Vida')),
      drawer: const AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_birthYear == null) _buildWelcomeBanner(theme),

          SizedBox(
            height: _timelineHeight,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: totalWidth,
                height: _timelineHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Painter: línea y nodos base
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: (details) {
                          if (years.isEmpty) return;
                          final tapX = details.localPosition.dx;
                          final index = (tapX / _nodeSpacing)
                              .round()
                              .clamp(0, years.length - 1);
                          _onYearTap(years[index], photosByYear);
                        },
                        child: CustomPaint(
                          size: Size(totalWidth, _timelineHeight),
                          painter: TimelineNodePainter(
                            years: years,
                            selectedYear: _selectedYear,
                            photosByYear: photosByYear,
                            primaryColor: primaryColor,
                            getNodeSize: (y) =>
                                _getNodeSize(y, photosByYear),
                            getLineThickness: (y1, y2) =>
                                _getLineThickness(y1, y2, photosByYear),
                            birthYear: _birthYear ?? -1,
                          ),
                        ),
                      ),
                    ),

                    // Miniaturas con portada sobre cada nodo
                    ...years.asMap().entries.map(
                          (entry) => _buildThumb(
                            entry.value,
                            entry.key,
                            primaryColor,
                            photosByYear,
                            provider,
                          ),
                        ),

                    // Nodo especial sin birthYear
                    if (_birthYear == null)
                      Positioned(
                        left: 8,
                        top: _axisY - 20,
                        child: GestureDetector(
                          onTap: _showBirthYearPicker,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFAEEDA),
                              border: Border.all(
                                color: const Color(0xFFEF9F27),
                                width: 3,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '✦',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFBA7517),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Etiquetas de año debajo del eje
                    ...years.asMap().entries.map((entry) {
                      final index = entry.key;
                      final year = entry.value;
                      final isMajor = _birthYear != null &&
                          (year - _birthYear!) % 5 == 0;
                      final x = index * _nodeSpacing;
                      return Positioned(
                        left: x - 22,
                        top: _axisY + 20,
                        child: SizedBox(
                          width: 44,
                          child: Text(
                            year.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMajor ? 12 : 10,
                              fontWeight: isMajor
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isMajor
                                  ? theme.colorScheme.onSurface
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Área de toque ampliada sobre cada nodo
                    ...years.asMap().entries.map((entry) {
                      final index = entry.key;
                      final year = entry.value;
                      final radius =
                          _getNodeSize(year, photosByYear).toDouble() + 8;
                      final x = index * _nodeSpacing;
                      return Positioned(
                        left: x - radius,
                        top: _axisY - radius,
                        child: GestureDetector(
                          onTap: () => _onYearTap(year, photosByYear),
                          child: SizedBox(
                            width: radius * 2,
                            height: radius * 2,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          Expanded(
            child: SingleChildScrollView(
              child: _buildEmptyState(primaryColor),
            ),
          ),
        ],
      ),
      bottomNavigationBar: VoiceControlWidget(onCommand: _handleVoice),
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFAEEDA),
              border: Border.all(
                color: const Color(0xFFEF9F27),
                width: 2.5,
              ),
            ),
            child: const Center(
              child: Text(
                '✦',
                style: TextStyle(fontSize: 26, color: Color(0xFFBA7517)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '¿Cuándo comenzó tu historia?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresá tu año de nacimiento para armar tu línea de vida y empezar a agregar recuerdos.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _showBirthYearPicker,
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 13,
              ),
            ),
            child: const Text('Elegir mi año de nacimiento'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Tocá un año o una foto\npara ver tus recuerdos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UploadView()),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Agregar fotos'),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}