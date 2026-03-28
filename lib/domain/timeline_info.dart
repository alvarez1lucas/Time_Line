/// Model representing the user's life timeline information.
class TimelineInfo {
  String fullName;
  int birthYear;
  DateTime createdAt;

  TimelineInfo({
    required this.fullName,
    required this.birthYear,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate the user's current age
  int get currentAge => DateTime.now().year - birthYear;

  /// Get the year range for display (e.g., "1990-2025")
  String get yearRange => '$birthYear - ${DateTime.now().year}';
}
