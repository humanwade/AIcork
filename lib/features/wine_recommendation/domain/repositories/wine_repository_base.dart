import '../entities/wine_entity.dart';
import '../../data/models/recommendation_request.dart';

abstract class WineRepositoryBase {
  Future<List<WineEntity>> getRecommendations(RecommendationRequest request);
}

