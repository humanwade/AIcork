import '../../domain/entities/wine_entity.dart';

class WineRecommendationModel {
  final String title;
  final double price;
  final String sku;
  final String? thumbnailUrl;
  final String? tastingNotes;
  final String? sommelierNote;
  final String? inventoryUrl;
  final String? similarityReason;
  final String? wineType;

  const WineRecommendationModel({
    required this.title,
    required this.price,
    required this.sku,
    this.thumbnailUrl,
    this.tastingNotes,
    this.sommelierNote,
    this.inventoryUrl,
    this.similarityReason,
    this.wineType,
  });

  factory WineRecommendationModel.fromJson(Map<String, dynamic> json) {
    String rawTitle =
        (json['systitle'] as String?)?.trim().isNotEmpty == true
            ? (json['systitle'] as String).trim()
            : 'Unnamed wine';

    double parsedPrice = 0;
    final dynamic priceVal = json['ec_final_price'];
    if (priceVal is num) {
      parsedPrice = priceVal.toDouble();
    } else if (priceVal is String) {
      parsedPrice = double.tryParse(priceVal) ?? 0;
    }

    final String sku = (json['sku'] as String?)?.trim() ?? '';

    return WineRecommendationModel(
      title: rawTitle,
      price: parsedPrice,
      sku: sku,
      thumbnailUrl: (json['ec_thumbnails'] as String?)?.trim().isNotEmpty == true
          ? (json['ec_thumbnails'] as String).trim()
          : null,
      tastingNotes: (json['lcbo_tastingnotes'] as String?)?.trim(),
      sommelierNote: (json['sommelier_note'] as String?)?.trim(),
      inventoryUrl: (json['inventory_url'] as String?)?.trim(),
      similarityReason: (json['similarity_reason'] as String?)?.trim(),
      wineType: (json['wine_type'] as String?)?.trim(),
    );
  }

  WineEntity toEntity() {
    return WineEntity(
      title: title,
      price: price,
      sku: sku,
      thumbnailUrl: thumbnailUrl,
      tastingNotes: tastingNotes,
      sommelierNote: sommelierNote,
      inventoryUrl: inventoryUrl,
      matchedDb: true,
      canContribute: false,
      wineType: wineType,
    );
  }
}

