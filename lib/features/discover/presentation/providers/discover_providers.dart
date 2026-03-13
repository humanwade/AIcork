import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../wine_recommendation/data/models/wine_recommendation.dart';
import '../../../auth/presentation/screens/wine_preferences_screen.dart';
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

/// For You section: uses taste profile (same as /recommend, My Cellar Insights).
/// Empty list when not authenticated or insufficient Tried history.
/// Depends on auth so it refetches when user logs in.
final discoverForYouProvider =
    FutureProvider<List<WineRecommendationModel>>((ref) async {
  ref.watch(authProvider);
  final prefs = ref.watch(winePreferencesProvider);
  final api = ref.watch(discoverApiProvider);
  return api.fetchForYouRecommendations(
    preferredStyles: prefs.preferredStyles.toList(),
    preferredBody: prefs.preferredBody.isNotEmpty ? prefs.preferredBody : null,
    preferredFlavors: prefs.preferredFlavors.toList(),
    defaultBudget: prefs.defaultBudget > 0 ? prefs.defaultBudget : null,
  );
});

final discoverBudgetProvider =
    FutureProvider<List<WineRecommendationModel>>((ref) async {
  final api = ref.watch(discoverApiProvider);
  return api.fetchBudget(maxPrice: 20);
});

