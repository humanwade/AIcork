import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wine_recommendation/domain/entities/wine_entity.dart';
import '../../data/datasources/cellar_api_service.dart'
    show CellarApiService, CellarInsights, RemoteWineEntry;
import '../models/cellar_wine.dart';
import '../models/tried_wine_entry.dart';
import '../models/wine_source.dart';
import '../models/wine_type.dart';
import '../state/cellar_state.dart';

final cellarApiProvider = Provider<CellarApiService>((ref) {
  return CellarApiService.create();
});

final cellarInsightsProvider =
    FutureProvider<CellarInsights>((ref) async {
  ref.watch(cellarControllerProvider); // Refetch when cellar changes
  final api = ref.read(cellarApiProvider);
  return api.fetchInsights();
});

final cellarControllerProvider =
    AsyncNotifierProvider<CellarController, CellarState>(CellarController.new);

/// When set, CellarPage will animate to this tab (0=Wants, 1=Tried).
/// Used when navigating from My Page stat cards.
final cellarNavigateToTabProvider = StateProvider<int?>((ref) => null);

class CellarController extends AsyncNotifier<CellarState> {
  CellarApiService get _api => ref.read(cellarApiProvider);

  static const _empty =
      CellarState(wants: <CellarWine>[], tried: <TriedWineEntry>[]);

  @override
  Future<CellarState> build() async {
    debugPrint('Fetching cellar for current user...');
    final wantsRemote = await _api.fetch(isTried: false);
    final triedRemote = await _api.fetch(isTried: true);

    final wants = wantsRemote.map(_mapRemoteToWant).toList();
    final tried = triedRemote.map(_mapRemoteToTried).toList();

    debugPrint(
        'CellarController.build: fetched wants=${wants.length}, tried=${tried.length}');
    return CellarState(wants: wants, tried: tried);
  }

  bool isSavedWantSku(String sku) {
    final s = state.valueOrNull;
    if (s == null) return false;
    return s.wants.any((w) => w.sku == sku);
  }

  Future<void> toggleWantFromRecommendation(WineEntity wine) async {
    debugPrint('CellarController.toggleWantFromRecommendation: sku=${wine.sku}');
    final current = state.valueOrNull ?? _empty;

    final existsIndex = current.wants.indexWhere((w) => w.sku == wine.sku);
    final wants = [...current.wants];

    if (existsIndex >= 0) {
      final existing = wants.removeAt(existsIndex);
      final remoteId = int.tryParse(existing.id);
      debugPrint(
          'CellarController.toggleWantFromRecommendation: removing existing id=${existing.id}, remoteId=$remoteId');
      if (remoteId != null) {
        await _api.delete(remoteId);
      }
    } else {
      debugPrint(
          'CellarController.toggleWantFromRecommendation: creating new entry for "${wine.title}"');
      final created = await _api.create(
        wineName: wine.title,
        wineType: WineType.fromLabel(wine.wineType).label,
        isTried: false,
        rating: null,
        tastingNotes: wine.tastingNotes,
        imageUrl: wine.thumbnailUrl,
        sku: wine.sku,
        price: wine.price,
        thumbnailUrl: wine.thumbnailUrl,
        sommelierNote: wine.sommelierNote,
        inventoryUrl: wine.inventoryUrl,
      );
      wants.insert(0, _mapRemoteToWant(created));
    }

    state = AsyncValue.data(current.copyWith(wants: wants));
  }

  Future<void> addCustomFromScan({
    required String? recognizedName,
    required String? recognizedWinery,
    required String? recognizedVintage,
    required String? editedName,
    required String? editedWinery,
    required String? editedVintage,
    required bool isTried,
    double? rating,
    String? tastingNotes,
    String? imageUrl,
  }) async {
    final current = state.valueOrNull ?? _empty;
    debugPrint('CellarController.addCustomFromScan: isTried=$isTried');

    final created = await _api.createCustomFromScan(
      recognizedName: recognizedName,
      recognizedWinery: recognizedWinery,
      recognizedVintage: recognizedVintage,
      editedName: editedName,
      editedWinery: editedWinery,
      editedVintage: editedVintage,
      isTried: isTried,
      rating: rating,
      tastingNotes: tastingNotes,
      imageUrl: imageUrl,
    );

    if (isTried) {
      final tried = [_mapRemoteToTried(created), ...current.tried];
      state = AsyncValue.data(current.copyWith(tried: tried));
    } else {
      final wants = [_mapRemoteToWant(created), ...current.wants];
      state = AsyncValue.data(current.copyWith(wants: wants));
    }
  }

  Future<void> addManualWant({
    required String title,
    required WineType type,
  }) async {
    final current = state.valueOrNull ?? _empty;
    debugPrint(
        'CellarController.addManualWant: title="$title", type=${type.label}');

    final created = await _api.create(
      wineName: title,
      wineType: type.label,
      isTried: false,
    );
    final wants = [_mapRemoteToWant(created), ...current.wants];
    state = AsyncValue.data(current.copyWith(wants: wants));
  }

  Future<void> removeWant(String id) async {
    final current = state.valueOrNull ?? _empty;
    debugPrint('CellarController.removeWant: id=$id');
    final remoteId = int.tryParse(id);
    if (remoteId != null) {
      await _api.delete(remoteId);
    }
    final wants = current.wants.where((w) => w.id != id).toList();
    state = AsyncValue.data(current.copyWith(wants: wants));
  }

  Future<void> addTried(TriedWineEntry entry) async {
    final current = state.valueOrNull ?? _empty;
    debugPrint('CellarController.addTried: title="${entry.title}"');
    final created = await _api.create(
      wineName: entry.title,
      wineType: entry.type.label,
      isTried: true,
      rating: entry.rating,
      tastingNotes: entry.customNotes,
      imageUrl: entry.imageUrl,
      sku: entry.sku,
      price: entry.price,
      thumbnailUrl: entry.imageUrl,
      inventoryUrl: entry.inventoryUrl,
    );
    final tried = [_mapRemoteToTried(created), ...current.tried];
    state = AsyncValue.data(current.copyWith(tried: tried));
  }

  Future<void> removeTried(String id) async {
    final current = state.valueOrNull ?? _empty;
    debugPrint('CellarController.removeTried: id=$id');
    final remoteId = int.tryParse(id);
    if (remoteId != null) {
      await _api.delete(remoteId);
    }
    final tried = current.tried.where((e) => e.id != id).toList();
    state = AsyncValue.data(current.copyWith(tried: tried));
  }

  Future<void> moveTriedToWant(TriedWineEntry entry) async {
    final current = state.valueOrNull ?? _empty;
    final remoteId = int.tryParse(entry.id);
    debugPrint('CellarController.moveTriedToWant: id=${entry.id}, remoteId=$remoteId');
    if (remoteId == null) return;

    // Server-side source-of-truth: flip is_tried -> false.
    // We intentionally do not attempt to null out tasting fields here because the
    // current API helper only sends non-null fields (PATCH semantics).
    final updated = await _api.update(
      id: remoteId,
      isTried: false,
    );

    final tried = current.tried.where((e) => e.id != entry.id).toList();

    // Insert as a normal Want item (same mapping/shape used everywhere else).
    final want = _mapRemoteToWant(updated);
    final wants = [
      want,
      ...current.wants.where((w) => w.id != want.id),
    ];

    state = AsyncValue.data(current.copyWith(wants: wants, tried: tried));
  }

  Future<void> updateTried({
    required TriedWineEntry original,
    required double rating,
    required Set<String> flavorTags,
    required Set<String> styleTags,
    required String customNotes,
    required WineType type,
    String? purchaseNotes,
    DateTime? tastedAt,
  }) async {
    final current = state.valueOrNull ?? _empty;
    final remoteId = int.tryParse(original.id);
    debugPrint(
        'CellarController.updateTried: id=${original.id}, remoteId=$remoteId, rating=$rating');
    if (remoteId == null) return;

    final flavorsList =
        flavorTags.isEmpty ? null : (flavorTags.toList()..sort());
    final styleList =
        styleTags.isEmpty ? null : (styleTags.toList()..sort());

    final updated = await _api.update(
      id: remoteId,
      rating: rating,
      tastingNotes: customNotes.trim().isEmpty ? null : customNotes.trim(),
      isTried: true,
       wineType: type.label,
      imageUrl: original.imageUrl,
      thumbnailUrl: original.imageUrl,
      tastedAt: tastedAt,
      flavors: flavorsList,
      aromas: null,
      bodyStyle: styleList,
      purchaseNotes:
          purchaseNotes?.trim().isEmpty ?? true ? null : purchaseNotes!.trim(),
    );

    final updatedEntry = _mapRemoteToTried(updated);
    final tried = current.tried
        .map((e) => e.id == original.id ? updatedEntry : e)
        .toList();
    state = AsyncValue.data(current.copyWith(tried: tried));
  }

  Future<void> markWantAsTried({
    required CellarWine want,
    required double rating,
    required List<String> flavorTags,
    required List<String> styleTags,
    required String customNotes,
    String? purchaseNotes,
    DateTime? tastedAt,
    double? purchaseAmount,
  }) async {
    final current = state.valueOrNull ?? _empty;
    final remoteId = int.tryParse(want.id);
    debugPrint(
        'CellarController.markWantAsTried: id=${want.id}, remoteId=$remoteId, rating=$rating');
    if (remoteId == null) return;

    final existingTriedBySku = want.sku != null && want.sku!.isNotEmpty
        ? current.tried.where((t) => t.sku == want.sku).toList()
        : <TriedWineEntry>[];
    if (existingTriedBySku.isNotEmpty) {
      final existing = existingTriedBySku.first;
      final existingId = int.tryParse(existing.id);
      if (existingId != null) {
        final updated = await _api.update(
          id: existingId,
          rating: rating,
          tastingNotes: customNotes.isEmpty ? null : customNotes,
          isTried: true,
          imageUrl: existing.imageUrl ?? want.imageUrl,
          thumbnailUrl: existing.imageUrl ?? want.imageUrl,
          tastedAt: tastedAt,
          flavors: flavorTags.isEmpty ? null : flavorTags,
          aromas: null,
          bodyStyle: styleTags.isEmpty ? null : styleTags,
          purchaseNotes: purchaseNotes?.trim().isEmpty ?? true ? null : purchaseNotes,
          price: purchaseAmount ?? want.price,
        );
        final wants = current.wants.where((w) => w.id != want.id).toList();
        final tried = current.tried
            .map((t) => t.id == existing.id ? _mapRemoteToTried(updated) : t)
            .toList();
        state = AsyncValue.data(current.copyWith(wants: wants, tried: tried));
        return;
      }
    }

    final updated = await _api.update(
      id: remoteId,
      rating: rating,
      tastingNotes: customNotes.isEmpty ? null : customNotes,
      isTried: true,
      imageUrl: want.imageUrl,
      thumbnailUrl: want.imageUrl,
      tastedAt: tastedAt,
      flavors: flavorTags.isEmpty ? null : flavorTags,
      aromas: null,
      bodyStyle: styleTags.isEmpty ? null : styleTags,
      purchaseNotes: purchaseNotes?.trim().isEmpty ?? true ? null : purchaseNotes,
      price: purchaseAmount ?? want.price,
    );

    final wants = current.wants.where((w) => w.id != want.id).toList();
    final tried = [_mapRemoteToTried(updated), ...current.tried];

    state = AsyncValue.data(current.copyWith(wants: wants, tried: tried));
  }

  CellarWine _mapRemoteToWant(RemoteWineEntry e) {
    return CellarWine(
      id: e.id.toString(),
      title: e.wineName,
      type: WineType.fromLabel(e.wineType),
      imageUrl: e.imageUrl ?? e.thumbnailUrl,
      price: e.price,
      sku: e.sku,
      tastingNotes: e.tastingNotes,
      sommelierNote: e.sommelierNote,
      inventoryUrl: e.inventoryUrl,
      addedAt: e.addedAt,
      source: WineSource.manual,
    );
  }

  TriedWineEntry _mapRemoteToTried(RemoteWineEntry e) {
    return TriedWineEntry(
      id: e.id.toString(),
      title: e.wineName,
      type: WineType.fromLabel(e.wineType),
      imageUrl: e.imageUrl ?? e.thumbnailUrl,
      price: e.price,
      sku: e.sku,
      inventoryUrl: e.inventoryUrl,
      rating: e.rating ?? 0,
      flavorTags: e.flavors,
      aromaTags: e.aromas,
      styleTags: e.bodyStyle,
      customNotes: e.tastingNotes ?? '',
      revisitNotes: e.purchaseNotes,
      addedAt: e.addedAt,
      tastedAt: e.tastedAt ?? e.addedAt,
      source: WineSource.manual,
    );
  }
}

