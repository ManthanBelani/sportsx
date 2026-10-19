import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/coach.dart';

class CoachState {
  final Coach? coachProfile;
  final List<String> certifications;
  final List<Map<String, dynamic>> facilities;
  final List<Map<String, dynamic>> showcaseAthletes;
  final bool isLoading;
  final String? error;

  CoachState({
    this.coachProfile,
    this.certifications = const [],
    this.facilities = const [],
    this.showcaseAthletes = const [],
    this.isLoading = false,
    this.error,
  });

  CoachState copyWith({
    Coach? coachProfile,
    List<String>? certifications,
    List<Map<String, dynamic>>? facilities,
    List<Map<String, dynamic>>? showcaseAthletes,
    bool? isLoading,
    String? error,
  }) {
    return CoachState(
      coachProfile: coachProfile ?? this.coachProfile,
      certifications: certifications ?? this.certifications,
      facilities: facilities ?? this.facilities,
      showcaseAthletes: showcaseAthletes ?? this.showcaseAthletes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }
  return [];
}

/// Result of an athlete search: either rows, or a human-readable error message.
/// Returned instead of throwing so callers can distinguish "no matches" from
/// "the request failed".
typedef AthleteSearchResult = ({List<Map<String, dynamic>> rows, String? error});

/// Builds a PUT payload for a partial `/me/coach-profile` update.
///
/// The same endpoint is also written with a *full* payload by the profile edit
/// screen, so we cannot assume the backend merges partial bodies. Merging the
/// current profile over [changed] is safe under either interpretation (full
/// replace or merge) and prevents silently dropping other fields.
Map<String, dynamic> buildCoachProfilePayload(
  Map<String, dynamic> changed,
  Coach? current,
) {
  final profile = current?.toJson();
  if (profile == null) return changed;
  // Read-only / server-computed fields are never writable.
  profile.remove('id');
  profile.remove('user_id');
  profile.remove('status');
  profile.remove('rating');
  profile.remove('avg_rating');
  profile.remove('profile_photo_url');
  return {...profile, ...changed};
}

class CoachNotifier extends StateNotifier<CoachState> {
  final Dio _dio;

  CoachNotifier(this._dio) : super(CoachState());

  Future<void> loadCoachProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/me/coach-profile');
      if (!mounted) {
        return;
      }
      final data = response.data['data'];
      if (data != null) {
        if (mounted) {
          state = state.copyWith(
          coachProfile: Coach.fromJson(data),
          certifications: _parseStringList(data['certifications']),
          facilities: _parseStringList(data['facilities']).map((e) => {'name': e}).toList(),
          showcaseAthletes: List<Map<String, dynamic>>.from(data['showcase_athletes'] ?? []),
          isLoading: false,
          );
        }
      } else {
        if (mounted) {
          state = state.copyWith(isLoading: false);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
      }
    }
  }

  Map<String, dynamic> _partialUpdatePayload(Map<String, dynamic> changed) =>
      buildCoachProfilePayload(changed, state.coachProfile);

  Future<void> addCredential(String credential) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedCredentials = [...state.certifications, credential];
      await _dio.put('/me/coach-profile',
          data: _partialUpdatePayload({'certifications': updatedCredentials}));
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(
        certifications: updatedCredentials,
        isLoading: false,
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
      }
    }
  }

  Future<void> removeCredential(int index) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedCredentials = List<String>.from(state.certifications);
      updatedCredentials.removeAt(index);
      await _dio.put('/me/coach-profile',
          data: _partialUpdatePayload({'certifications': updatedCredentials}));
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(
        certifications: updatedCredentials,
        isLoading: false,
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
      }
    }
  }

  Future<void> updateFacilities(List<Map<String, dynamic>> facilities) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.put('/me/coach-profile',
          data: _partialUpdatePayload({'facilities': facilities}));
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(
        facilities: facilities,
        isLoading: false,
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
      }
    }
  }

  Future<void> updateShowcaseAthletes(List<Map<String, dynamic>> athletes) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.put('/me/coach-profile',
          data: _partialUpdatePayload({'showcase_athletes': athletes}));
      if (!mounted) {
        return;
      }
      if (mounted) {
        state = state.copyWith(
        showcaseAthletes: athletes,
        isLoading: false,
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
      }
    }
  }

  /// Searches athletes. Returns [AthleteSearchResult] rather than throwing so the
  /// caller can distinguish "no matches" from "the request failed".
  Future<AthleteSearchResult> searchAthletes(String query) async {
    const noRows = <Map<String, dynamic>>[];
    try {
      final response = await _dio.get('/athletes', queryParameters: {'search': query});
      final data = response.data['data'];
      if (data is List) {
        return (rows: data.cast<Map<String, dynamic>>(), error: null);
      }
      return (rows: noRows, error: null);
    } on DioException catch (e) {
      return (rows: noRows, error: ApiException.fromDio(e).message);
    } catch (e) {
      return (rows: noRows, error: ApiException.messageFor(e));
    }
  }
}

final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  final dio = ref.watch(dioProvider);
  return CoachNotifier(dio);
});
