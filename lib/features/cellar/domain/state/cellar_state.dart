import '../models/cellar_wine.dart';
import '../models/tried_wine_entry.dart';

class CellarState {
  final List<CellarWine> wants;
  final List<TriedWineEntry> tried;

  const CellarState({
    required this.wants,
    required this.tried,
  });

  CellarState copyWith({
    List<CellarWine>? wants,
    List<TriedWineEntry>? tried,
  }) {
    return CellarState(
      wants: wants ?? this.wants,
      tried: tried ?? this.tried,
    );
  }
}

