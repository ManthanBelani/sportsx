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

class CoachNotifier extends StateNotifier<CoachState> {
  final Dio _dio;

  CoachNotifier(this._dio) : super(CoachState());

  Future<void> loadCoachProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/me/coach-profile');
      final data = response.data['data'];
      if (data != null) {
        state = state.copyWith(
          coachProfile: Coach.fromJson(data),
          certifications: _parseStringList(data['certifications']),
          facilities: _parseStringList(data['facilities']).map((e) => {'name': e}).toList(),
          showcaseAthletes: List<Map<String, dynamic>>.from(data['showcase_athletes'] ?? []),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
    }
  }

  Future<void> addCredential(String credential) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedCredentials = [...state.certifications, credential];
      await _dio.put('/me/coach-profile', data: {
        'certifications': updatedCredentials,
      });
      state = state.copyWith(
        certifications: updatedCredentials,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
    }
  }

  Future<void> removeCredential(int index) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedCredentials = List<String>.from(state.certifications);
      updatedCredentials.removeAt(index);
      await _dio.put('/me/coach-profile', data: {
        'certifications': updatedCredentials,
      });
      state = state.copyWith(
        certifications: updatedCredentials,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
    }
  }

  Future<void> updateFacilities(List<Map<String, dynamic>> facilities) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.put('/me/coach-profile', data: {
        'facilities': facilities,
      });
      state = state.copyWith(
        facilities: facilities,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
    }
  }

  Future<void> updateShowcaseAthletes(List<Map<String, dynamic>> athletes) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.put('/me/coach-profile', data: {
        'showcase_athletes': athletes,
      });
      state = state.copyWith(
        showcaseAthletes: athletes,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.messageFor(e));
    }
  }

  Future<List<Map<String, dynamic>>> searchAthletes(String query) async {
    try {
      final response = await _dio.get('/athletes', queryParameters: {'search': query});
      final data = response.data['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      // Propagate search errors as empty list but log via ApiException for debugging.
      // Caller handles empty state; error snackbar shown by UI if needed.
      return [];
    } catch (_) {
      return [];
    }
  }
}

final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  final dio = ref.watch(dioProvider);
  return CoachNotifier(dio);
});
