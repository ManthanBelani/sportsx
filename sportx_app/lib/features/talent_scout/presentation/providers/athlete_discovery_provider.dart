import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/talent_scout/data/models/athlete_discovery_model.dart';

class AthleteDiscoveryState {
  final List<AthleteDiscovery> athletes;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final int lastPage;
  final String? error;

  AthleteDiscoveryState({
    this.athletes = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.lastPage = 1,
    this.error,
  });

  AthleteDiscoveryState copyWith({
    List<AthleteDiscovery>? athletes,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    int? lastPage,
    String? error,
  }) {
    return AthleteDiscoveryState(
      athletes: athletes ?? this.athletes,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      error: error,
    );
  }
}

class AthleteDiscoveryNotifier extends StateNotifier<AthleteDiscoveryState> {
  final Dio _dio;

  AthleteDiscoveryNotifier(this._dio) : super(AthleteDiscoveryState());

  Future<void> searchAthletes({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, error: null, currentPage: 1, lastPage: 1);
    try {
      final params = <String, dynamic>{'page': 1, 'per_page': 20};
      if (filters != null) params.addAll(filters);
      final resp = await _dio.get('/athletes', queryParameters: params);
      final body = resp.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => AthleteDiscovery.fromJson(e as Map<String, dynamic>))
          .toList();
      final currentPage = (body['current_page'] as num?)?.toInt() ?? 1;
      final lastPage = (body['last_page'] as num?)?.toInt() ?? (list.length < 20 ? 1 : 2);
      state = AthleteDiscoveryState(
        athletes: list,
        isLoading: false,
        hasMore: currentPage < lastPage,
        currentPage: currentPage,
        lastPage: lastPage,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> loadMore({Map<String, dynamic>? filters}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nextPage = state.currentPage + 1;
      final params = <String, dynamic>{'page': nextPage, 'per_page': 20};
      if (filters != null) params.addAll(filters);
      final resp = await _dio.get('/athletes', queryParameters: params);
      final body = resp.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => AthleteDiscovery.fromJson(e as Map<String, dynamic>))
          .toList();
      final currentPage = (body['current_page'] as num?)?.toInt() ?? nextPage;
      final lastPage = (body['last_page'] as num?)?.toInt() ?? state.lastPage;
      state = AthleteDiscoveryState(
        athletes: [...state.athletes, ...list],
        isLoading: false,
        hasMore: currentPage < lastPage,
        currentPage: currentPage,
        lastPage: lastPage,
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
