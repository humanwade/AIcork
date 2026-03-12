import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/auth/token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      await _dio.post(
        '/auth/signup',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        },
      );
    } on DioException catch (e) {
      // Surface a clean error but preserve technical detail in logs.
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      final message = detail.isNotEmpty
          ? 'Sign up failed: $detail'
          : 'Sign up failed. Please try again.';
      throw Exception(message);
    }
  }

  Future<void> sendVerificationCode({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      await _dio.post(
        '/auth/send-verification-code',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        },
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      final message = detail.isNotEmpty
          ? 'Failed to send verification code: $detail'
          : 'Failed to send verification code. Please try again.';
      throw Exception(message);
    }
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      await _dio.post(
        '/auth/verify-email-code',
        queryParameters: {
          'email': email,
          'code': code,
        },
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      final message = detail.isNotEmpty
          ? 'Verification failed: $detail'
          : 'Verification failed. Please try again.';
      throw Exception(message);
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Missing access token from server');
      }

      await TokenStorage.setToken(token);
      return token;
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      final message = detail.isNotEmpty
          ? 'Login failed: $detail'
          : 'Login failed. Please try again.';
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    await TokenStorage.setToken(null);
  }

  Future<String?> loadToken() async {
    await TokenStorage.hydrate();
    return TokenStorage.token;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return data;
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final response = await _dio.patch(
      '/auth/me',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      },
    );
    debugPrint('AuthRepository.updateProfile: status=${response.statusCode}');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final detail = data is Map<String, dynamic>
          ? (data['detail']?.toString() ?? '')
          : '';
      final message = detail.isNotEmpty
          ? detail
          : 'Failed to update password. Please try again.';
      throw Exception(message);
    }
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    try {
      await _dio.delete(
        '/auth/me',
        data: {'current_password': currentPassword},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final detail = data is Map<String, dynamic>
          ? (data['detail']?.toString() ?? '')
          : '';
      final message = detail.isNotEmpty
          ? detail
          : 'Failed to delete account. Please try again.';
      throw Exception(message);
    }
  }
}

