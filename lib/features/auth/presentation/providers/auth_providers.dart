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
  final int? userId;
  final String? errorMessage;
  final String? firstName;

  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    required this.token,
    this.userId,
    required this.errorMessage,
    required this.firstName,
  });

  factory AuthState.initial() => const AuthState(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        userId: null,
        errorMessage: null,
        firstName: null,
      );

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? token,
    int? userId,
    bool clearUserId = false,
    String? errorMessage,
    String? firstName,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userId: clearUserId ? null : (userId ?? this.userId),
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
      final hasToken = token != null && token.isNotEmpty;
      int? userId;
      if (hasToken) {
        try {
          final profile = await _repo.fetchProfile();
          userId = profile['id'] as int?;
        } catch (_) {
          // Token may be expired; leave userId null
        }
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: hasToken,
        token: token,
        userId: userId,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        clearUserId: true,
        errorMessage: 'Failed to restore session',
      );
    }
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
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
      int? userId;
      try {
        final profile = await _repo.fetchProfile();
        userId = profile['id'] as int?;
      } catch (_) {
        // Profile fetch failed; userId stays null
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        token: token,
        userId: userId,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        token: null,
        clearUserId: true,
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

