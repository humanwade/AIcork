import '../../domain/entities/wine_entity.dart';
import '../../domain/repositories/wine_repository_base.dart';
import '../datasources/wine_api_service.dart';
import '../models/recommendation_request.dart';

class WineRepository implements WineRepositoryBase {
  final WineApiService _apiService;

  WineRepository(this._apiService);

  @override
  Future<List<WineEntity>> getRecommendations(
    RecommendationRequest request,
  ) async {
    final models = await _apiService.fetchRecommendations(request);
    return models.map((m) => m.toEntity()).toList();
  }
}

