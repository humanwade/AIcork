import 'wine_source.dart';
import 'wine_type.dart';

class CellarWine {
  final String id;
  final String title;
  final WineType type;
  final String? imageUrl;
  final double? price;
  final String? sku;
  final String? tastingNotes;
  final String? sommelierNote;
  final String? inventoryUrl;
  final DateTime addedAt;
  final WineSource source;

  const CellarWine({
    required this.id,
    required this.title,
    required this.type,
    this.imageUrl,
    this.price,
    this.sku,
    this.tastingNotes,
    this.sommelierNote,
    this.inventoryUrl,
    required this.addedAt,
    required this.source,
  });

  CellarWine copyWith({
    String? id,
    String? title,
    WineType? type,
    String? imageUrl,
    double? price,
    String? sku,
    String? tastingNotes,
    String? sommelierNote,
    String? inventoryUrl,
    DateTime? addedAt,
    WineSource? source,
  }) {
    return CellarWine(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      sku: sku ?? this.sku,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      sommelierNote: sommelierNote ?? this.sommelierNote,
      inventoryUrl: inventoryUrl ?? this.inventoryUrl,
      addedAt: addedAt ?? this.addedAt,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.label,
      'imageUrl': imageUrl,
      'price': price,
      'sku': sku,
      'tastingNotes': tastingNotes,
      'sommelierNote': sommelierNote,
      'inventoryUrl': inventoryUrl,
      'addedAt': addedAt.toIso8601String(),
      'source': source.name,
    };
  }

  factory CellarWine.fromJson(Map<String, dynamic> json) {
    return CellarWine(
      id: json['id'] as String,
      title: json['title'] as String,
      type: WineType.fromLabel(json['type'] as String?),
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      sku: json['sku'] as String?,
      tastingNotes: json['tastingNotes'] as String?,
      sommelierNote: json['sommelierNote'] as String?,
      inventoryUrl: json['inventoryUrl'] as String?,
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
          DateTime.now(),
      source: WineSource.values.firstWhere(
        (s) => s.name == (json['source'] as String?),
        orElse: () => WineSource.manual,
      ),
    );
  }
}

