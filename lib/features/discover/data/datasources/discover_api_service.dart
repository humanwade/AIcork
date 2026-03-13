import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../wine_recommendation/data/models/wine_recommendation.dart';
import '../models/discover_collection.dart';

class DiscoverApiService {
  final Dio _dio;

  DiscoverApiService(this._dio);

  factory DiscoverApiService.create() {
    return DiscoverApiService(DioClient.create());
  }

  Future<List<WineRecommendationModel>> fetchDaily() async {
    final response = await _dio.get<List<dynamic>>('/discover/daily');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(WineRecommendationModel.fromJson)
        .toList();
  }

  Future<List<DiscoverCollection>> fetchCollections() async {
    final response = await _dio.get<List<dynamic>>('/discover/collections');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(DiscoverCollection.fromJson)
        .toList();
  }

  Future<List<WineRecommendationModel>> fetchCollection(String slug) async {
    final response =
        await _dio.get<List<dynamic>>('/discover/collection/$slug');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(WineRecommendationModel.fromJson)
        .toList();
  }

  Future<List<WineRecommendationModel>> fetchRecommended() async {
    final response =
        await _dio.get<List<dynamic>>('/discover/recommended');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(WineRecommendationModel.fromJson)
        .toList();
  }

  /// For You picks using taste profile and/or wine preferences.
  /// Preferences affect ranking only; no wines are filtered.
  Future<List<WineRecommendationModel>> fetchForYouRecommendations({
    List<String>? preferredStyles,
    String? preferredBody,
    List<String>? preferredFlavors,
    double? defaultBudget,
  }) async {
    final params = <String, dynamic>{};
    if (preferredStyles != null && preferredStyles.isNotEmpty) {
      params['preferred_styles'] = preferredStyles.join(',');
    }
    if (preferredBody != null && preferredBody.isNotEmpty) {
      params['preferred_body'] = preferredBody;
    }
    if (preferredFlavors != null && preferredFlavors.isNotEmpty) {
      params['preferred_flavors'] = preferredFlavors.join(',');
    }
    if (defaultBudget != null && defaultBudget > 0) {
      params['default_budget'] = defaultBudget;
    }
    final response = await _dio.get<List<dynamic>>(
      '/discover/for-you',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(WineRecommendationModel.fromJson)
        .toList();
  }

  Future<List<WineRecommendationModel>> fetchBudget(
      {double maxPrice = 20}) async {
    final response = await _dio.get<List<dynamic>>(
      '/discover/budget',
      queryParameters: {'max_price': maxPrice},
    );
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(WineRecommendationModel.fromJson)
        .toList();
  }
}

