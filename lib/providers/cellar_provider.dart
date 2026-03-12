import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/wine_model.dart';

class CellarNotifier extends StateNotifier<List<WineEntry>> {
  CellarNotifier() : super(_mockData);

  static final List<WineEntry> _mockData = [
    const WineEntry(
      id: '1',
      name: 'Château Margaux 2019',
      type: 'Red',
      isTried: false,
    ),
    const WineEntry(
      id: '2',
      name: 'Cloudy Bay Sauvignon Blanc',
      type: 'White',
      isTried: true,
      rating: 4.5,
      tastingNote: 'Crisp, citrus and tropical fruit. Perfect with seafood.',
      dateConsumed: null,
    ),
    WineEntry(
      id: '3',
      name: 'Barolo DOCG 2018',
      type: 'Red',
      isTried: true,
      rating: 5,
      tastingNote: 'Full-bodied, tannic, notes of cherry and rose. One of my favorites.',
      dateConsumed: DateTime(2024, 2, 15),
    ),
  ];

  void add(WineEntry entry) {
    state = [...state, entry];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void update(WineEntry entry) {
    state = [
      for (final e in state) e.id == entry.id ? entry : e,
    ];
  }

  void toggleTried(WineEntry entry) {
    update(entry.copyWith(
      isTried: !entry.isTried,
      rating: entry.isTried ? 0 : (entry.rating > 0 ? entry.rating : 3),
      tastingNote: entry.isTried ? '' : entry.tastingNote,
    ));
  }
}

final cellarProvider =
    StateNotifierProvider<CellarNotifier, List<WineEntry>>((ref) => CellarNotifier());
