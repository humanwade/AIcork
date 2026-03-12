import 'wine_source.dart';
import 'wine_type.dart';

class TriedWineEntry {
  final String id;
  final String title;
  final WineType type;
  final String? imageUrl;
  final double? price;
  final String? sku;
  final String? inventoryUrl;

  final double rating; // 1–5 (supports halves)
  final List<String> flavorTags;
  final List<String> aromaTags;
  final List<String> styleTags;
  final String customNotes;
  final String? revisitNotes;

  final DateTime addedAt;
  final DateTime? tastedAt;
  final WineSource source;

  const TriedWineEntry({
    required this.id,
    required this.title,
    required this.type,
    this.imageUrl,
    this.price,
    this.sku,
    this.inventoryUrl,
    required this.rating,
    required this.flavorTags,
    required this.aromaTags,
    required this.styleTags,
    required this.customNotes,
    this.revisitNotes,
    required this.addedAt,
    this.tastedAt,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.label,
      'imageUrl': imageUrl,
      'price': price,
      'sku': sku,
      'inventoryUrl': inventoryUrl,
      'rating': rating,
      'flavorTags': flavorTags,
      'aromaTags': aromaTags,
      'styleTags': styleTags,
      'customNotes': customNotes,
      'revisitNotes': revisitNotes,
      'addedAt': addedAt.toIso8601String(),
      'tastedAt': tastedAt?.toIso8601String(),
      'source': source.name,
    };
  }

  factory TriedWineEntry.fromJson(Map<String, dynamic> json) {
    return TriedWineEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      type: WineType.fromLabel(json['type'] as String?),
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      sku: json['sku'] as String?,
      inventoryUrl: json['inventoryUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      flavorTags: (json['flavorTags'] as List?)?.cast<String>() ?? const [],
      aromaTags: (json['aromaTags'] as List?)?.cast<String>() ?? const [],
      styleTags: (json['styleTags'] as List?)?.cast<String>() ?? const [],
      customNotes: json['customNotes'] as String? ?? '',
      revisitNotes: json['revisitNotes'] as String?,
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
          DateTime.now(),
      tastedAt: json['tastedAt'] != null
          ? DateTime.tryParse(json['tastedAt'] as String)
          : null,
      source: WineSource.values.firstWhere(
        (s) => s.name == (json['source'] as String?),
        orElse: () => WineSource.manual,
      ),
    );
  }
}

