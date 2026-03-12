import 'package:dio/dio.dart';

import '../models/recommendation_request.dart';
import '../models/wine_recommendation.dart';

class WineApiService {
  final Dio _dio;

  WineApiService(this._dio);

  Future<List<WineRecommendationModel>> fetchRecommendations(
    RecommendationRequest request,
  ) async {
    final Response<dynamic> response = await _dio.post(
      '/recommend',
      data: request.toJson(),
    );

    final data = response.data;
    if (data is! List) {
      return [];
    }

    final results = <WineRecommendationModel>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        results.add(WineRecommendationModel.fromJson(item));
      }
    }
    return results;
  }

  Future<List<WineRecommendationModel>> fetchSimilar(String sku) async {
    final Response<dynamic> response = await _dio.get(
      '/wine/$sku/similar',
    );

    final data = response.data;
    if (data is! List) {
      return [];
    }

    final results = <WineRecommendationModel>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        results.add(WineRecommendationModel.fromJson(item));
      }
    }
    return results;
  }
}

