import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/models/scan_wine_response.dart';
import '../../domain/models/scan_history_entry.dart';

class ScannerApiService {
  ScannerApiService(this._dio);

  final Dio _dio;

  factory ScannerApiService.create() {
    return ScannerApiService(DioClient.create());
  }

  /// Send wine label image to backend for AI recognition. Returns parsed scan result.
  Future<ScanWineResponse> scanWineLabel(File image) async {
    debugPrint('Sending image to scan API');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split(RegExp(r'[/\\]')).last,
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/scan',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No response from scan API');
    }
    debugPrint('Scan result received');
    return ScanWineResponse.fromJson(data);
  }

  Future<void> saveScanHistory({
    required String wineName,
    String? sku,
    String? imageUrl,
  }) async {
    try {
      await _dio.post<void>(
        '/scan/history',
        data: {
          'wine_name': wineName,
          'sku': sku,
          'image_url': imageUrl,
        },
      );
    } on DioException catch (e) {
      debugPrint('ScannerApiService.saveScanHistory error: $e');
    }
  }

  Future<List<ScanHistoryEntry>> fetchScanHistory() async {
    try {
      final response = await _dio.get<List<dynamic>>('/scan/history');
      final data = response.data;
      if (data == null) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ScanHistoryEntry.fromJson)
          .toList();
    } on DioException catch (e) {
      debugPrint('ScannerApiService.fetchScanHistory error: $e');
      return const [];
    }
  }

  Future<void> deleteScanHistory(int id) async {
    try {
      await _dio.delete<void>('/scan/history/$id');
    } on DioException catch (e) {
      debugPrint('ScannerApiService.deleteScanHistory error: $e');
    }
  }
}
