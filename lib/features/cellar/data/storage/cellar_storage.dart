import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/cellar_wine.dart';
import '../../domain/models/tried_wine_entry.dart';

class CellarStorage {
  static const _kWants = 'cellar.wants.v1';
  static const _kTried = 'cellar.tried.v1';

  Future<List<CellarWine>> loadWants() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWants);
    return _decodeList(raw, (m) => CellarWine.fromJson(m));
  }

  Future<List<CellarWine>> loadCellar() async {
    // Deprecated: legacy key migration placeholder. Keep returning empty.
    return const [];
  }

  Future<List<TriedWineEntry>> loadTried() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTried);
    return _decodeList(raw, (m) => TriedWineEntry.fromJson(m));
  }

  Future<void> saveWants(List<CellarWine> wants) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWants, _encodeList(wants.map((e) => e.toJson())));
  }

  Future<void> saveCellar(List<CellarWine> cellar) async {
    // Deprecated: no-op (Cellar section removed).
  }

  Future<void> saveTried(List<TriedWineEntry> tried) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTried, _encodeList(tried.map((e) => e.toJson())));
  }

  String _encodeList(Iterable<Map<String, dynamic>> list) {
    return jsonEncode(list.toList());
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(fromMap)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

