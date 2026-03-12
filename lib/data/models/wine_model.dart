/// Data model for "My Cellar" entries: wishlist and tasting notes.
class WineEntry {
  final String id;
  final String name;
  final String type; // e.g. Red, White, Rosé, Sparkling
  /// When false: "Wants" (to buy). When true: "Tried" (with rating/notes).
  final bool isTried;

  // Tried-only fields
  final double rating; // 1–5 star rating
  final String tastingNote;
  final DateTime? dateConsumed;
  final String? imagePath;

  const WineEntry({
    required this.id,
    required this.name,
    required this.type,
    this.isTried = false,
    this.rating = 0,
    this.tastingNote = '',
    this.dateConsumed,
    this.imagePath,
  });

  WineEntry copyWith({
    String? id,
    String? name,
    String? type,
    bool? isTried,
    double? rating,
    String? tastingNote,
    DateTime? dateConsumed,
    String? imagePath,
  }) {
    return WineEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isTried: isTried ?? this.isTried,
      rating: rating ?? this.rating,
      tastingNote: tastingNote ?? this.tastingNote,
      dateConsumed: dateConsumed ?? this.dateConsumed,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isTried': isTried,
      'rating': rating,
      'tastingNote': tastingNote,
      'dateConsumed': dateConsumed?.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory WineEntry.fromJson(Map<String, dynamic> json) {
    return WineEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isTried: json['isTried'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      tastingNote: json['tastingNote'] as String? ?? '',
      dateConsumed: json['dateConsumed'] != null
          ? DateTime.tryParse(json['dateConsumed'] as String)
          : null,
      imagePath: json['imagePath'] as String?,
    );
  }
}
