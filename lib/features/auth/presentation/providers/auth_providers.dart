import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/auth_repository.dart';

final authDioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(authDioProvider);
  return AuthRepository(dio);
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? token;
  final String? errorMessage;
  final String? firstName;

  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    required this.token,
    required this.errorMessage,
    required this.firstName,
  });

  factory AuthState.initial() => const AuthState(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        errorMessage: null,
        firstName: null,
      );

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? token,
    String? errorMessage,
    String? firstName,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      errorMessage: errorMessage,
      firstName: firstName ?? this.firstName,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(AuthState.initial());

  final AuthRepository _repo;

  Future<void> hydrate() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _repo.loadToken();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: token != null && token.isNotEmpty,
        token: token,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        errorMessage: 'Failed to restore session',
      );
    }
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String verificationCode,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Ensure email has been verified before creating the account.
      await _repo.verifyEmailCode(email: email, code: verificationCode);
      await _repo.signup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _repo.login(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        token: token,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState.initial();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repo);
  notifier.hydrate();
  return notifier;
});

