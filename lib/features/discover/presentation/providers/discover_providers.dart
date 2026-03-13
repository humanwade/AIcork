import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wine_recommendation/data/models/wine_recommendation.dart';
import '../../data/datasources/discover_api_service.dart';
import '../../data/models/discover_collection.dart';

final discoverApiProvider = Provider<DiscoverApiService>((ref) {
  return DiscoverApiService.create();
});

final discoverDailyProvider =
    FutureProvider<List<WineRecommendationModel>>((ref) async {
  final api = ref.watch(discoverApiProvider);
  return api.fetchDaily();
});

final discoverCollectionsProvider =
    FutureProvider<List<DiscoverCollection>>((ref) async {
  final api = ref.watch(discoverApiProvider);
  return api.fetchCollections();
});

final discoverRecommendedProvider =
    FutureProvider<List<WineRecommendationModel>>((ref) async {
  final api = ref.watch(discoverApiProvider);
  return api.fetchRecommended();
});

final discoverBudgetProvider =
    FutureProvider<List<WineRecommendationModel>>((ref) async {
  final api = ref.watch(discoverApiProvider);
  return api.fetchBudget(maxPrice: 20);
});

