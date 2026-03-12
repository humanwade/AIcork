/// Response from POST /scan (AI wine label recognition).
class ScanWineResponse {
  const ScanWineResponse({
    required this.recognized,
    this.wineName,
    this.winery,
    this.vintage,
    this.matchedDb = false,
    this.canContribute = false,
    this.wineData,
  });

  final bool recognized;
  final String? wineName;
  final String? winery;
  final String? vintage;
  final bool matchedDb;
  final bool canContribute;
  final ScanWineData? wineData;

  factory ScanWineResponse.fromJson(Map<String, dynamic> json) {
    final recognized = json['recognized'] as bool? ?? false;
    final wineDataJson = json['wine_data'] as Map<String, dynamic>?;
    return ScanWineResponse(
      recognized: recognized,
      wineName: json['wine_name'] as String?,
      winery: json['winery'] as String?,
      vintage: json['vintage'] as String?,
      matchedDb: json['matched_db'] as bool? ?? false,
      canContribute: json['can_contribute'] as bool? ?? false,
      wineData: wineDataJson != null
          ? ScanWineData.fromJson(wineDataJson)
          : null,
    );
  }
}

/// Wine data returned by scan (matches backend wine_data structure).
class ScanWineData {
  const ScanWineData({
    required this.systitle,
    this.ecFinalPrice = 0,
    this.lcboTastingnotes = '',
    this.ecThumbnails,
    this.sku,
    this.inventoryUrl,
    this.sommelierNote = '',
    this.winery,
    this.vintage,
  });

  final String systitle;
  final double ecFinalPrice;
  final String lcboTastingnotes;
  final String? ecThumbnails;
  final String? sku;
  final String? inventoryUrl;
  final String sommelierNote;
  final String? winery;
  final String? vintage;

  factory ScanWineData.fromJson(Map<String, dynamic> json) {
    final sku = json['sku'];
    return ScanWineData(
      systitle: json['systitle'] as String? ?? '',
      ecFinalPrice: (json['ec_final_price'] as num?)?.toDouble() ?? 0,
      lcboTastingnotes: json['lcbo_tastingnotes'] as String? ?? '',
      ecThumbnails: json['ec_thumbnails'] as String?,
      sku: sku != null ? sku.toString() : null,
      inventoryUrl: json['inventory_url'] as String?,
      sommelierNote: json['sommelier_note'] as String? ?? '',
      winery: json['winery'] as String?,
      vintage: json['vintage'] as String?,
    );
  }
}
