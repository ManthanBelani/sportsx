import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class OnboardingState {
  final Set<int> selectedSportIds;
  final int? selectedAgeGroupId;
  final String? selectedSkillLevel;
  final int? selectedCityId;
  final bool isLoading;
  final String? error;

  OnboardingState({
    this.selectedSportIds = const {},
    this.selectedAgeGroupId,
    this.selectedSkillLevel,
    this.selectedCityId,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    Set<int>? selectedSportIds,
    int? selectedAgeGroupId,
    String? selectedSkillLevel,
    int? selectedCityId,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      selectedSportIds: selectedSportIds ?? this.selectedSportIds,
      selectedAgeGroupId: selectedAgeGroupId ?? this.selectedAgeGroupId,
      selectedSkillLevel: selectedSkillLevel ?? this.selectedSkillLevel,
      selectedCityId: selectedCityId ?? this.selectedCityId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toAthletePayload() {
    return {
      'sport_ids': selectedSportIds.toList(),
      'age_group_id': selectedAgeGroupId,
      'skill_level': selectedSkillLevel,
      'city_id': selectedCityId,
    };
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Dio _dio;

  OnboardingNotifier(this._dio) : super(OnboardingState());

  void setSports(Set<int> ids) {
    state = state.copyWith(selectedSportIds: ids);
  }

  void setAgeGroup(int id) {
    state = state.copyWith(selectedAgeGroupId: id);
  }

  void setSkillLevel(String level) {
    state = state.copyWith(selectedSkillLevel: level);
  }

  void setCity(int id) {
    state = state.copyWith(selectedCityId: id);
  }

  Future<bool> submitAthleteOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/onboarding/athlete', data: state.toAthletePayload());
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      return false;
    }
  }

  void reset() {
    state = OnboardingState();
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.watch(dioProvider));
});
