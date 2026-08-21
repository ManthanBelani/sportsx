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
  final Map<String, String> fieldErrors;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.needsOnboarding = false,
    this.error,
    this.fieldErrors = const {},
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? needsOnboarding,
    String? error,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      error: error ?? this.error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
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
      // Backend returns { "data": { <user fields…>, "needs_onboarding": bool } }
      // with the user fields flattened into `data` (no nested `data.user`).
      final data = resp.data['data'] as Map<String, dynamic>;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: User.fromJson(data),
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
        'role': role,
      };
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;

      // Email/password-only auth: backend returns a token immediately (no OTP).
      final resp = await _dio.post('/auth/register', data: data);
      final respData = resp.data;
      final authToken = respData['token'] as String;
      await _storage.saveToken(authToken);
      final user = User.fromJson(respData['user'] as Map<String, dynamic>);
      final needsOnboarding = respData['needs_onboarding'] == true;
      state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: needsOnboarding);
    } on DioException catch (e) {
      _fail(e);
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
      _fail(e);
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    state = state.copyWith(status: AuthStatus.error, error: 'OTP verification is not supported - email is auto-verified on registration');
  }

  Future<void> resendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.error, error: 'Resend OTP is not supported - emails are auto-verified on registration');
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
      _fail(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on DioException catch (e) {
      _fail(e);
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
      _fail(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void forceLogout() {
    _storage.deleteToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.unauthenticated, error: null, fieldErrors: const {});
  }

  /// Clears any transient error/field messages without changing auth status —
  /// used to dismiss inline field errors as the user edits the form.
  void clearFieldErrors() {
    state = state.copyWith(error: null, fieldErrors: const {});
  }

  /// Refreshes user data from the server (e.g., after onboarding completes
  /// when profile name may have been updated).
  Future<void> refreshUser() async {
    try {
      final resp = await _dio.get('/auth/me');
      final data = resp.data['data'] as Map<String, dynamic>;
      state = state.copyWith(
        user: User.fromJson(data),
        needsOnboarding: data['needs_onboarding'] == true,
      );
    } catch (_) {
      // Silently fail - user data refresh is best-effort
    }
  }

  void _fail(DioException e) {
    final api = ApiException.fromDio(e);
    state = state.copyWith(
      status: AuthStatus.error,
      error: api.message,
      fieldErrors: api.fieldErrors,
    );
  }

  /// Called when a role finishes its onboarding flow so the router stops
  /// redirecting to the onboarding screens.
  void markOnboardingComplete() {
    state = state.copyWith(needsOnboarding: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider), ref.watch(storageServiceProvider));
});
