/// Dictionary of voice keywords organized by context.
/// These words and phrases are recognized by the app and trigger specific actions.
class VoiceKeywords {
  // Navigation & Menu commands
  static const List<String> goHome = ['volver al menú', 'menú principal', 'inicio', 'vuelve al inicio'];
  static const List<String> uploadImages = ['seleccionar imágenes', 'ingresar imágenes', 'cargar imágenes', 'subir fotos', 'carga imagenes'];
  static const List<String> viewSelected = [
    'imágenes seleccionadas',
    'seleccionadas',
    'mis selecciones',
    'ver seleccionadas',
  ];

  // Photo selection commands
  static const List<String> selectPhoto = ['seleccionar', 'marcar', 'elige', 'escoge'];
  static const List<String> deselectPhoto = ['deseleccionar', 'desmarcar', 'quita', 'elimina'];
  static const List<String> selectAllPhotos = ['seleccionar todas', 'marcar todas', 'todo', 'todas'];
  static const List<String> continueFlow = ['continuar', 'siguiente', 'sigue', 'adelante'];

  // Review & Save commands
  static const List<String> goBack = ['regresar', 'vuelve', 'atrás', 'volver'];
  static const List<String> finalizeSave = ['subir y guardar', 'finalizar', 'guardar', 'terminar', 'listo', 'completar'];

  // Album commands
  static const List<String> viewAlbums = ['mis álbumes', 'ver álbumes', 'álbumes', 'todos los álbumes'];

  // Help / General
  static const List<String> helpCommand = ['ayuda', 'help', 'qué puedo hacer', 'instrucciones'];

  /// Check if a spoken phrase matches any keyword in the given list.
  /// Uses fuzzy matching to handle variations and typos.
  static bool matchesKeyword(String phrase, List<String> keywords) {
    final lower = phrase.toLowerCase().trim();

    for (final keyword in keywords) {
      if (lower == keyword.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Simple similarity calculation (Levenshtein-like).
  /// Returns a value between 0.0 and 1.0.
  static double _similarity(String a, String b) {
    final aLen = a.length;
    final bLen = b.length;
    if (aLen == 0 || bLen == 0) return aLen == bLen ? 1.0 : 0.0;

    final maxLen = (aLen + bLen) / 2;
    final distance = _levenshteinDistance(a, b);
    return 1.0 - (distance / maxLen);
  }

  /// Compute Levenshtein distance between two strings.
  static int _levenshteinDistance(String a, String b) {
    final aLen = a.length;
    final bLen = b.length;
    final distances = List.generate(aLen + 1, (_) => List.filled(bLen + 1, 0));

    for (var i = 0; i <= aLen; i++) {
      distances[i][0] = i;
    }
    for (var j = 0; j <= bLen; j++) {
      distances[0][j] = j;
    }

    for (var i = 1; i <= aLen; i++) {
      for (var j = 1; j <= bLen; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        distances[i][j] = [
          distances[i - 1][j] + 1, // deletion
          distances[i][j - 1] + 1, // insertion
          distances[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return distances[aLen][bLen];
  }
}
