import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';

class RemoteWineEntry {
  final int id;
  final int userId;
  final String wineName;
  final String wineType;
  final double? rating;
  final String? tastingNotes;
  final bool isTried;
  final String? imagePath;
  final String? imageUrl;
  final String? sku;
  final double? price;
  final String? thumbnailUrl;
  final String? sommelierNote;
  final String? inventoryUrl;
  final DateTime addedAt;
  final DateTime? tastedAt;
  final List<String> flavors;
  final List<String> aromas;
  final List<String> bodyStyle;
  final String? purchaseNotes;

  RemoteWineEntry({
    required this.id,
    required this.userId,
    required this.wineName,
    required this.wineType,
    required this.rating,
    required this.tastingNotes,
    required this.isTried,
    required this.imagePath,
    required this.imageUrl,
    required this.sku,
    required this.price,
    required this.thumbnailUrl,
    required this.sommelierNote,
    required this.inventoryUrl,
    required this.addedAt,
    this.tastedAt,
    List<String>? flavors,
    List<String>? aromas,
    List<String>? bodyStyle,
    this.purchaseNotes,
  })  : flavors = flavors ?? const [],
        aromas = aromas ?? const [],
        bodyStyle = bodyStyle ?? const [];

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  factory RemoteWineEntry.fromJson(Map<String, dynamic> json) {
    return RemoteWineEntry(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      wineName: json['wine_name'] as String,
      wineType: json['wine_type'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      tastingNotes: json['tasting_notes'] as String?,
      isTried: json['is_tried'] as bool? ?? false,
      imagePath: json['image_path'] as String?,
      imageUrl: json['image_url'] as String?,
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      sommelierNote: json['sommelier_note'] as String?,
      inventoryUrl: json['inventory_url'] as String?,
      addedAt: DateTime.tryParse(json['added_at'] as String? ?? '') ??
          DateTime.now(),
      tastedAt: json['tasted_at'] != null
          ? DateTime.tryParse(json['tasted_at'] as String)
          : null,
      flavors: _parseStringList(json['flavors']),
      aromas: _parseStringList(json['aromas']),
      bodyStyle: _parseStringList(json['body_style']),
      purchaseNotes: json['purchase_notes'] as String?,
    );
  }
}

class CellarApiService {
  CellarApiService(this._dio);

  final Dio _dio;

  factory CellarApiService.create() {
    final dio = DioClient.create();
    return CellarApiService(dio);
  }

  Future<List<RemoteWineEntry>> fetch({bool? isTried}) async {
    debugPrint('CellarApiService.fetch: isTried=$isTried');
    final response = await _dio.get(
      '/cellar',
      queryParameters: {
        if (isTried != null) 'is_tried': isTried,
      },
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(RemoteWineEntry.fromJson)
        .toList();
  }

  Future<RemoteWineEntry> create({
    required String wineName,
    required String wineType,
    bool isTried = false,
    double? rating,
    String? tastingNotes,
    String? imageUrl,
    String? sku,
    double? price,
    String? thumbnailUrl,
    String? sommelierNote,
    String? inventoryUrl,
  }) async {
    debugPrint(
        'CellarApiService.create: wineName="$wineName", wineType=$wineType, isTried=$isTried, sku=$sku');
    final response = await _dio.post(
      '/cellar',
      data: {
        'wine_name': wineName,
        'wine_type': wineType,
        'is_tried': isTried,
        'rating': rating,
        'tasting_notes': tastingNotes,
        'image_url': imageUrl,
        'sku': sku,
        'price': price,
        'thumbnail_url': thumbnailUrl,
        'sommelier_note': sommelierNote,
        'inventory_url': inventoryUrl,
      },
    );
    debugPrint(
        'CellarApiService.create: response status=${response.statusCode}');
    return RemoteWineEntry.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RemoteWineEntry> createCustomFromScan({
    required String? recognizedName,
    required String? recognizedWinery,
    required String? recognizedVintage,
    required String? editedName,
    required String? editedWinery,
    required String? editedVintage,
    required bool isTried,
    double? rating,
    String? tastingNotes,
    String? imageUrl,
  }) async {
    debugPrint(
        'CellarApiService.createCustomFromScan: isTried=$isTried, recognizedName="$recognizedName"');
    final response = await _dio.post(
      '/cellar/custom',
      data: {
        'recognized_name': recognizedName,
        'recognized_winery': recognizedWinery,
        'recognized_vintage': recognizedVintage,
        'edited_name': editedName,
        'edited_winery': editedWinery,
        'edited_vintage': editedVintage,
        'image_url': imageUrl,
        'is_tried': isTried,
        'rating': rating,
        'tasting_notes': tastingNotes,
      },
    );
    return RemoteWineEntry.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RemoteWineEntry> update({
    required int id,
    double? rating,
    String? tastingNotes,
    bool? isTried,
    String? wineType,
    String? imageUrl,
    String? thumbnailUrl,
    DateTime? tastedAt,
    List<String>? flavors,
    List<String>? aromas,
    List<String>? bodyStyle,
    String? purchaseNotes,
    double? price,
  }) async {
    debugPrint(
        'CellarApiService.update: id=$id, rating=$rating, isTried=$isTried');
    final data = <String, dynamic>{
      if (rating != null) 'rating': rating,
      if (tastingNotes != null) 'tasting_notes': tastingNotes,
      if (isTried != null) 'is_tried': isTried,
      if (wineType != null) 'wine_type': wineType,
      if (imageUrl != null) 'image_url': imageUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (tastedAt != null) 'tasted_at': tastedAt.toIso8601String(),
      if (flavors != null) 'flavors': flavors,
      if (aromas != null) 'aromas': aromas,
      if (bodyStyle != null) 'body_style': bodyStyle,
      if (purchaseNotes != null) 'purchase_notes': purchaseNotes,
      if (price != null) 'price': price,
    };
    debugPrint('CellarApiService.update: sending payload keys: ${data.keys.join(", ")}');
    final response = await _dio.patch(
      '/cellar/$id',
      data: data,
    );
    debugPrint(
        'CellarApiService.update: response status=${response.statusCode}');
    return RemoteWineEntry.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> delete(int id) async {
    debugPrint('CellarApiService.delete: id=$id');
    final response = await _dio.delete('/cellar/$id');
    debugPrint('CellarApiService.delete: response status=${response.statusCode}');
  }

  Future<CellarInsights> fetchInsights() async {
    debugPrint('CellarApiService.fetchInsights');
    final response = await _dio.get('/cellar/insights');
    final data = response.data as Map<String, dynamic>;
    return CellarInsights.fromJson(data);
  }
}

class CellarInsights {
  final String? summaryText;
  final List<String> preferredWineTypes;
  final List<String> preferredFlavors;
  final List<String> preferredBodyStyles;
  final double? averagePreferredPrice;
  final bool enoughData;

  const CellarInsights({
    this.summaryText,
    this.preferredWineTypes = const [],
    this.preferredFlavors = const [],
    this.preferredBodyStyles = const [],
    this.averagePreferredPrice,
    this.enoughData = false,
  });

  factory CellarInsights.fromJson(Map<String, dynamic> json) {
    return CellarInsights(
      summaryText: json['summary_text'] as String?,
      preferredWineTypes: _parseStringList(json['preferred_wine_types']),
      preferredFlavors: _parseStringList(json['preferred_flavors']),
      preferredBodyStyles: _parseStringList(json['preferred_body_styles']),
      averagePreferredPrice:
          (json['average_preferred_price'] as num?)?.toDouble(),
      enoughData: json['enough_data'] as bool? ?? false,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}

