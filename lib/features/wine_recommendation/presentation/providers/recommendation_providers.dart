import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/wine_api_service.dart';
import '../../data/models/recommendation_request.dart';
import '../../data/repositories/wine_repository.dart';
import '../../domain/entities/wine_entity.dart';
import '../../domain/repositories/wine_repository_base.dart';
import '../../domain/usecases/fetch_recommendations_usecase.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

final wineApiServiceProvider = Provider<WineApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return WineApiService(dio);
});

final wineRepositoryProvider = Provider<WineRepositoryBase>((ref) {
  final api = ref.watch(wineApiServiceProvider);
  return WineRepository(api);
});

final fetchRecommendationsUseCaseProvider =
    Provider<FetchRecommendationsUseCase>((ref) {
  final repo = ref.watch(wineRepositoryProvider);
  return FetchRecommendationsUseCase(repo);
});

class RecommendationState {
  final AsyncValue<List<WineEntity>> results;
  final bool isSubmitting;

  const RecommendationState({
    required this.results,
    required this.isSubmitting,
  });

  factory RecommendationState.initial() {
    return const RecommendationState(
      results: AsyncValue.data(<WineEntity>[]),
      isSubmitting: false,
    );
  }

  RecommendationState copyWith({
    AsyncValue<List<WineEntity>>? results,
    bool? isSubmitting,
  }) {
    return RecommendationState(
      results: results ?? this.results,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final FetchRecommendationsUseCase _useCase;

  RecommendationNotifier(this._useCase)
      : super(RecommendationState.initial());

  Future<List<WineEntity>> fetch(RecommendationRequest request) async {
    if (state.isSubmitting) {
      return state.results.value ?? <WineEntity>[];
    }

    state = state.copyWith(
      isSubmitting: true,
      results: const AsyncValue.loading(),
    );

    try {
      final wines = await _useCase(request).timeout(
        const Duration(seconds: 15),
      );
      state = state.copyWith(
        results: AsyncValue.data(wines),
        isSubmitting: false,
      );
      return wines;
    } on Exception catch (e, st) {
      state = state.copyWith(
        results: AsyncValue.error(e, st),
        isSubmitting: false,
      );
      rethrow;
    }
  }

  Future<void> retry() async {}

  void clear() {
    state = RecommendationState.initial();
  }
}

final recommendationNotifierProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  final useCase = ref.watch(fetchRecommendationsUseCaseProvider);
  return RecommendationNotifier(useCase);
});

