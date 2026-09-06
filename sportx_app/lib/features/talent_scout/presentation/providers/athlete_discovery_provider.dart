import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/talent_scout/data/models/athlete_discovery_model.dart';

class AthleteDiscoveryState {
  final List<AthleteDiscovery> athletes;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  AthleteDiscoveryState({
    this.athletes = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  AthleteDiscoveryState copyWith({
    List<AthleteDiscovery>? athletes,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return AthleteDiscoveryState(
      athletes: athletes ?? this.athletes,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

class AthleteDiscoveryNotifier extends StateNotifier<AthleteDiscoveryState> {
  final Dio _dio;

  AthleteDiscoveryNotifier(this._dio) : super(AthleteDiscoveryState());

  Future<void> searchAthletes({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, error: null, currentPage: 1);
    try {
      final params = <String, dynamic>{'page': 1, 'per_page': 20};
      if (filters != null) params.addAll(filters);
      final resp = await _dio.get('/athletes', queryParameters: params);
      final data = resp.data['data'];
      final list = (data as List? ?? [])
          .map((e) => AthleteDiscovery.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        athletes: list,
        isLoading: false,
        hasMore: list.length >= 20,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> loadMore({Map<String, dynamic>? filters}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final params = <String, dynamic>{'page': nextPage, 'per_page': 20};
      if (filters != null) params.addAll(filters);
      final resp = await _dio.get('/athletes', queryParameters: params);
      final data = resp.data['data'];
      final list = (data as List? ?? [])
          .map((e) => AthleteDiscovery.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        athletes: [...state.athletes, ...list],
        isLoading: false,
        hasMore: list.length >= 20,
        currentPage: nextPage,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  void reset() {
    state = AthleteDiscoveryState();
  }
}

final athleteDiscoveryProvider =
    StateNotifierProvider<AthleteDiscoveryNotifier, AthleteDiscoveryState>((ref) {
  return AthleteDiscoveryNotifier(ref.watch(dioProvider));
});
