import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/models/scan_wine_response.dart';

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
}
