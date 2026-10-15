import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/talent_scout/data/models/talent_scout_profile.dart';

class TalentScoutState {
  final TalentScoutProfile? profile;
  final bool isLoading;
  final String? error;

  TalentScoutState({this.profile, this.isLoading = false, this.error});

  TalentScoutState copyWith({TalentScoutProfile? profile, bool? isLoading, String? error, bool clearError = false}) {
    return TalentScoutState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TalentScoutNotifier extends StateNotifier<TalentScoutState> {
  final Dio _dio;

  TalentScoutNotifier(this._dio) : super(TalentScoutState()) {
    // Called directly (not via microtask): a microtask can run after the
    // provider was already disposed (e.g. session reset), and even the
    // synchronous prefix assignment below would then throw.
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _dio.get('/me/scout-profile');
      if (!mounted) {
        return;
      }
      final data = resp.data['data'];
      if (!mounted) {
        return;
      }
      if (data != null) {
        state = TalentScoutState(profile: TalentScoutProfile.fromJson(data));
      } else {
        state = TalentScoutState(isLoading: false);
      }
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

  Future<bool> createProfile(TalentScoutProfile profile) async {
    try {
      final resp = await _dio.post('/onboarding/talent-scout', data: profile.toJson());
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = TalentScoutState(profile: TalentScoutProfile.fromJson(resp.data['data']));
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

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final resp = await _dio.put('/me/scout-profile', data: data);
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = TalentScoutState(profile: TalentScoutProfile.fromJson(resp.data['data']));
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
}

final talentScoutProvider = StateNotifierProvider<TalentScoutNotifier, TalentScoutState>((ref) {
  return TalentScoutNotifier(ref.watch(dioProvider));
});
