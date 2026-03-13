import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentSearch {
  final String query;
  final double maxBudget;
  final int topK;

  const RecentSearch({
    required this.query,
    required this.maxBudget,
    required this.topK,
  });
}

class RecentSearchesNotifier extends StateNotifier<List<RecentSearch>> {
  RecentSearchesNotifier() : super(const []);

  void add(RecentSearch search) {
    final newList = [
      search,
      ...state.where((s) => s.query != search.query),
    ];
    state = newList.take(5).toList();
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<RecentSearch>>(
  (ref) => RecentSearchesNotifier(),
);

