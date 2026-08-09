import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/storage_service.dart';
import 'package:sportx_app/shared/models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool needsOnboarding;
  final String? error;

  AuthState({this.status = AuthStatus.initial, this.user, this.needsOnboarding = false, this.error});

  AuthState copyWith({AuthStatus? status, User? user, bool? needsOnboarding, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final StorageService _storage;

  AuthNotifier(this._dio, this._storage) : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _storage.getToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final resp = await _dio.get('/auth/me');
      final data = resp.data['data'] as Map<String, dynamic>;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: User.fromJson(data['user'] as Map<String, dynamic>),
        needsOnboarding: data['needs_onboarding'] == true,
      );
    } catch (_) {
      await _storage.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> register({required String email, required String password, required String role, String? name, String? phone}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = {
        'email': email,
        'password': password,
        'password_confirmation': password,
        'role': role,
      };
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      
      await _dio.post('/auth/register', data: data);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> verifyEmail(String token) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final resp = await _dio.post('/auth/verify-email', data: {'token': token});
      final data = resp.data;
      final authToken = data['token'] as String;
      await _storage.saveToken(authToken);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final needsOnboarding = data['needs_onboarding'] == true;
      state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: needsOnboarding);
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final resp = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final data = resp.data;
      final token = data['token'] as String;
      await _storage.saveToken(token);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final needsOnboarding = data['needs_onboarding'] == true;
      state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: needsOnboarding);
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> resetPassword({required String email, required String token, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final resp = await _dio.post('/auth/reset-password', data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': password,
      });
      final data = resp.data;
      final authToken = data['token'] as String;
      await _storage.saveToken(authToken);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: false);
    } on DioException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.unauthenticated, error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider), ref.watch(storageServiceProvider));
});
