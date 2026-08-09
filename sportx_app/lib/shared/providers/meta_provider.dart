import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';

class MetaState {
  final List<Sport> sports;
  final List<City> cities;
  final List<AgeGroup> ageGroups;
  final bool isLoading;
  final String? error;

  MetaState({
    this.sports = const [],
    this.cities = const [],
    this.ageGroups = const [],
    this.isLoading = false,
    this.error,
  });

  MetaState copyWith({List<Sport>? sports, List<City>? cities, List<AgeGroup>? ageGroups, bool? isLoading, String? error}) {
    return MetaState(
      sports: sports ?? this.sports,
      cities: cities ?? this.cities,
      ageGroups: ageGroups ?? this.ageGroups,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MetaNotifier extends StateNotifier<MetaState> {
  final Dio _dio;

  MetaNotifier(this._dio) : super(MetaState()) {
    loadMeta();
  }

  Future<void> loadMeta() async {
    state = state.copyWith(isLoading: true);
    try {
      final futures = await Future.wait([
        _dio.get('/meta/sports'),
        _dio.get('/meta/cities'),
        _dio.get('/meta/age-groups'),
      ]);
      final sports = (futures[0].data['data'] as List).map((e) => Sport.fromJson(e)).toList();
      final cities = (futures[1].data['data'] as List).map((e) => City.fromJson(e)).toList();
      final ageGroups = (futures[2].data['data'] as List).map((e) => AgeGroup.fromJson(e)).toList();
      state = MetaState(sports: sports, cities: cities, ageGroups: ageGroups);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> refresh() async {
    await loadMeta();
  }
}

final metaProvider = StateNotifierProvider<MetaNotifier, MetaState>((ref) {
  return MetaNotifier(ref.watch(dioProvider));
});
