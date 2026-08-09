import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/coach.dart';

class CoachState {
  final Coach? coachProfile;
  final List<Map<String, dynamic>> credentials;
  final List<Map<String, dynamic>> facilities;
  final List<Map<String, dynamic>> showcaseAthletes;
  final bool isLoading;
  final String? error;

  CoachState({
    this.coachProfile,
    this.credentials = const [],
    this.facilities = const [],
    this.showcaseAthletes = const [],
    this.isLoading = false,
    this.error,
  });

  CoachState copyWith({
    Coach? coachProfile,
    List<Map<String, dynamic>>? credentials,
    List<Map<String, dynamic>>? facilities,
    List<Map<String, dynamic>>? showcaseAthletes,
    bool? isLoading,
    String? error,
  }) {
    return CoachState(
      coachProfile: coachProfile ?? this.coachProfile,
      credentials: credentials ?? this.credentials,
      facilities: facilities ?? this.facilities,
      showcaseAthletes: showcaseAthletes ?? this.showcaseAthletes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
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
          credentials: List<Map<String, dynamic>>.from(data['credentials'] ?? []),
          facilities: List<Map<String, dynamic>>.from(data['facilities'] ?? []),
          showcaseAthletes: List<Map<String, dynamic>>.from(data['showcase_athletes'] ?? []),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addCredential(Map<String, dynamic> credential) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedCredentials = [...state.credentials, credential];
      await _dio.put('/me/coach-profile', data: {
        'credentials': updatedCredentials,
      });
      state = state.copyWith(
        credentials: updatedCredentials,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeCredential(int index) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedCredentials = List<Map<String, dynamic>>.from(state.credentials);
      updatedCredentials.removeAt(index);
      await _dio.put('/me/coach-profile', data: {
        'credentials': updatedCredentials,
      });
      state = state.copyWith(
        credentials: updatedCredentials,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    } catch (e) {
      return [];
    }
  }
}

final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  final dio = ref.watch(dioProvider);
  return CoachNotifier(dio);
});
