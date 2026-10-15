import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
    final startTime = DateTime.now();
    final token = await _storage.getToken();
    if (!mounted) {
      return;
    }
    
    if (token == null) {
      await _ensureMinSplashDuration(startTime);
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
      return;
    }
    
    try {
      final resp = await _dio.get('/auth/me');
      if (!mounted) {
        return;
      }
      final data = resp.data['data'] as Map<String, dynamic>;
      
      await _ensureMinSplashDuration(startTime);
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = AuthState(
        status: AuthStatus.authenticated,
        user: User.fromJson(data),
        needsOnboarding: data['needs_onboarding'] == true,
        );
      }
    } catch (_) {
      await _storage.deleteToken();
      if (!mounted) {
        return;
      }
      
      await _ensureMinSplashDuration(startTime);
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> _ensureMinSplashDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsed.inMilliseconds));
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      final respData = resp.data;
      final authToken = respData['token'] as String;
      await _storage.saveToken(authToken);
      if (!mounted) {
        return;
      }
      final user = User.fromJson(respData['user'] as Map<String, dynamic>);
      final needsOnboarding = respData['needs_onboarding'] == true;
      if (mounted) {
        state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: needsOnboarding);
      }
      await _registerFcmToken();
      if (!mounted) {
        return;
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> verifyEmail(String token) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final resp = await _dio.post('/auth/verify-email', data: {'token': token});
      if (!mounted) {
        return;
      }
      final data = resp.data;
      final authToken = data['token'] as String;
      await _storage.saveToken(authToken);
      if (!mounted) {
        return;
      }
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final needsOnboarding = data['needs_onboarding'] == true;
      if (mounted) {
        state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: needsOnboarding);
      }
      await _registerFcmToken();
      if (!mounted) {
        return;
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> sendOtp({required String email, String purpose = 'signup'}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _dio.post('/auth/send-otp', data: {
        'channel': 'email',
        'destination': email,
        'purpose': purpose,
      });
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
    String purpose = 'signup',
    String? name,
    String? role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = <String, dynamic>{
        'channel': 'email',
        'destination': email,
        'code': otp,
        'purpose': purpose,
      };
      if (name != null) data['name'] = name;
      if (role != null) data['role'] = role;
      final resp = await _dio.post('/auth/verify-otp', data: data);
      if (!mounted) {
        return;
      }
      await _persistAuth(resp.data as Map<String, dynamic>);
      if (!mounted) {
        return;
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> resendOtp(String email, {String purpose = 'signup'}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _dio.post('/auth/resend-otp', data: {
        'channel': 'email',
        'destination': email,
        'purpose': purpose,
      });
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  /// "Continue with Google" — the app obtains the ID token natively
  /// (google_sign_in) and hands it to the backend, which verifies it.
  /// On success the same post-login sequence runs as password login:
  /// persist token → refresh user → register the FCM token.
  Future<void> signInWithGoogle({required String idToken, String? role}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = <String, dynamic>{'id_token': idToken};
      if (role != null) data['role'] = role;
      final resp = await _dio.post('/auth/google', data: data);
      if (!mounted) {
        return;
      }
      await _persistAuth(resp.data as Map<String, dynamic>);
      if (!mounted) {
        return;
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> _persistAuth(Map<String, dynamic> respData) async {
    final authToken = respData['token'] as String;
    await _storage.saveToken(authToken);
    if (!mounted) {
      return;
    }
    final user = User.fromJson(respData['user'] as Map<String, dynamic>);
    final needsOnboarding = respData['needs_onboarding'] == true;
    if (mounted) {
      state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: needsOnboarding);
    }
    await _registerFcmToken();
    if (!mounted) {
      return;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final resp = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      if (!mounted) {
        return;
      }
      final data = resp.data;
      final token = data['token'] as String;
      await _storage.saveToken(token);
      if (!mounted) {
        return;
      }
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final needsOnboarding = data['needs_onboarding'] == true;
      if (mounted) {
        state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: needsOnboarding);
      }
      await _registerFcmToken();
      if (!mounted) {
        return;
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
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
      if (!mounted) {
        return;
      }
      final data = resp.data;
      final authToken = data['token'] as String;
      await _storage.saveToken(authToken);
      if (!mounted) {
        return;
      }
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      if (mounted) {
        state = AuthState(status: AuthStatus.authenticated, user: user, needsOnboarding: false);
      }
      await _registerFcmToken();
      if (!mounted) {
        return;
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<void> logout() async {
    await _unregisterFcmToken();
    if (!mounted) {
      return;
    }
    try {
      await _dio.post('/auth/logout');
      if (!mounted) {
        return;
      }
    } catch (_) {}
    await _storage.deleteToken();
    if (!mounted) {
      return;
    }
    if (mounted) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (!mounted) {
        return;
      }
      if (token != null) {
        final deviceType = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        await _dio.post('/me/device-tokens', data: {
          'token': token,
          'device_type': deviceType,
        });
        if (!mounted) {
          return;
        }
      }
    } catch (_) {
      // Firebase not configured or FCM unavailable — skip token registration.
    }
  }

  Future<void> _unregisterFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (!mounted) {
        return;
      }
      if (token != null) {
        await _dio.delete('/me/device-tokens', data: {'token': token});
        if (!mounted) {
          return;
        }
      }
    } catch (_) {
      // Firebase not configured or FCM unavailable — skip token unregistration.
    }
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
      if (!mounted) {
        return;
      }
      final data = resp.data['data'] as Map<String, dynamic>;
      if (mounted) {
        state = state.copyWith(
        user: User.fromJson(data),
        needsOnboarding: data['needs_onboarding'] == true,
        );
      }
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
