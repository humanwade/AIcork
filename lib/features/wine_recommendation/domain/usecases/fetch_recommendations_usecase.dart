import '../entities/wine_entity.dart';
import '../repositories/wine_repository_base.dart';
import '../../data/models/recommendation_request.dart';

class FetchRecommendationsUseCase {
  final WineRepositoryBase _repository;

  FetchRecommendationsUseCase(this._repository);

  Future<List<WineEntity>> call(RecommendationRequest request) {
    return _repository.getRecommendations(request);
  }
}

