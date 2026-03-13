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

