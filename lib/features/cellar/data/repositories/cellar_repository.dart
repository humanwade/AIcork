import '../../domain/models/cellar_wine.dart';
import '../../domain/models/tried_wine_entry.dart';
import '../storage/cellar_storage.dart';

class CellarRepository {
  final CellarStorage _storage;
  CellarRepository(this._storage);

  Future<List<CellarWine>> loadWants() => _storage.loadWants();
  Future<List<TriedWineEntry>> loadTried() => _storage.loadTried();

  Future<void> saveWants(List<CellarWine> wants) => _storage.saveWants(wants);
  Future<void> saveTried(List<TriedWineEntry> tried) => _storage.saveTried(tried);
}

