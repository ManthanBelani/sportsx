import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class SettingsState {
  final Map<String, bool> notificationPrefs;
  final String language;
  final Map<String, String> privacySettings;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  static const defaultPrivacy = {
    'profile_visibility': 'public',
    'who_can_message': 'everyone',
    'who_can_connect': 'everyone',
  };

  SettingsState({
    this.notificationPrefs = const {'email': true, 'push': true, 'sms': false, 'in_app': true},
    this.language = 'en',
    this.privacySettings = defaultPrivacy,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SettingsState copyWith({
    Map<String, bool>? notificationPrefs,
    String? language,
    Map<String, String>? privacySettings,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return SettingsState(
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      language: language ?? this.language,
      privacySettings: privacySettings ?? this.privacySettings,
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
      Map<String, String> privacy = Map.from(SettingsState.defaultPrivacy);
      try {
        final privacyResp = await _dio.get('/me/privacy');
        final privacyData = privacyResp.data['data'] as Map<String, dynamic>?;
        if (privacyData != null) {
          privacy = {
            'profile_visibility': privacyData['profile_visibility'] as String? ?? 'public',
            'who_can_message': privacyData['who_can_message'] as String? ?? 'everyone',
            'who_can_connect': privacyData['who_can_connect'] as String? ?? 'everyone',
          };
        }
      } catch (_) {}
      state = SettingsState(
        notificationPrefs: Map<String, bool>.from(data['notification_prefs'] ?? {}),
        language: data['language'] as String? ?? 'en',
        privacySettings: privacy,
      );
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
      }
    }
  }

  Future<bool> updatePrefs(Map<String, bool> prefs) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _dio.put('/me/settings', data: {'notification_prefs': prefs});
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = state.copyWith(notificationPrefs: prefs, isLoading: false, successMessage: 'Preferences saved');
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
      }
      return false;
    }
  }

  Future<bool> updateLanguage(String lang) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _dio.put('/me/settings', data: {'language': lang});
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = state.copyWith(language: lang, isLoading: false, successMessage: 'Language updated');
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
      }
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
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = state.copyWith(isLoading: false, successMessage: 'Password updated');
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
      }
      return false;
    }
  }

  Future<bool> updatePrivacy(Map<String, String> privacy) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _dio.put('/me/privacy', data: privacy);
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = state.copyWith(
          privacySettings: {...state.privacySettings, ...privacy},
          isLoading: false,
          successMessage: 'Privacy updated',
        );
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
      }
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
