import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/scanner_api_service.dart';

final scannerApiProvider = Provider<ScannerApiService>((ref) {
  return ScannerApiService.create();
});

/// Count of scan history entries for the current user.
/// Uses real data from /scan/history.
final scanHistoryCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(scannerApiProvider);
  final list = await api.fetchScanHistory();
  return list.length;
});
