import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class SettingsState {
  final Map<String, bool> notificationPrefs;
  final String language;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  SettingsState({
    this.notificationPrefs = const {'email': true, 'push': true, 'sms': false, 'in_app': true},
    this.language = 'en',
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SettingsState copyWith({
    Map<String, bool>? notificationPrefs,
    String? language,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return SettingsState(
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Dio _dio;

  SettingsNotifier(this._dio) : super(SettingsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _dio.get('/me/settings');
      final data = resp.data['data'] as Map<String, dynamic>;
      state = SettingsState(
        notificationPrefs: Map<String, bool>.from(data['notification_prefs'] ?? {}),
        language: data['language'] as String? ?? 'en',
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<bool> updatePrefs(Map<String, bool> prefs) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _dio.put('/me/settings', data: {'notification_prefs': prefs});
      state = state.copyWith(notificationPrefs: prefs, isLoading: false, successMessage: 'Preferences saved');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      return false;
    }
  }

  Future<bool> updateLanguage(String lang) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _dio.put('/me/settings', data: {'language': lang});
      state = state.copyWith(language: lang, isLoading: false, successMessage: 'Language updated');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      return false;
    }
  }

  Future<bool> deleteAccount(String password) async {
    try {
      await _dio.delete('/me/account', data: {'password': password});
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _dio.put('/me/settings/password', data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      });
      state = state.copyWith(isLoading: false, successMessage: 'Password updated');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(dioProvider));
});
