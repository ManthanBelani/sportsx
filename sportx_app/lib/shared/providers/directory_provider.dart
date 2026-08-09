import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';

class DirectoryState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  DirectoryState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  DirectoryState<T> copyWith({List<T>? items, bool? isLoading, bool? hasMore, int? page, String? error}) {
    return DirectoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error ?? this.error,
    );
  }
}

class DirectoryNotifier<T> extends StateNotifier<DirectoryState<T>> {
  final Dio _dio;
  final String endpoint;
  final T Function(Map<String, dynamic>) fromJson;

  DirectoryNotifier(this._dio, this.endpoint, this.fromJson) : super(DirectoryState()) {
    load();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, page: 1);
    try {
      final resp = await _dio.get(endpoint, queryParameters: {'page': 1, 'per_page': 20});
      final data = resp.data['data'] as List;
      final items = data.map((e) => fromJson(e)).toList();
      final hasMore = resp.data['meta']?['current_page'] < resp.data['meta']?['last_page'];
      state = DirectoryState(items: items, hasMore: hasMore, page: 1);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final resp = await _dio.get(endpoint, queryParameters: {'page': nextPage, 'per_page': 20});
      final data = resp.data['data'] as List;
      final newItems = data.map((e) => fromJson(e)).toList();
      final hasMore = resp.data['meta']?['current_page'] < resp.data['meta']?['last_page'];
      state = state.copyWith(
        items: [...state.items, ...newItems],
        hasMore: hasMore,
        page: nextPage,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(items: [], hasMore: true, page: 0);
    await load();
  }
}

// Typed notifier providers for each directory type
final academiesProvider = StateNotifierProvider<DirectoryNotifier<Academy>, DirectoryState<Academy>>((ref) {
  return DirectoryNotifier<Academy>(ref.watch(dioProvider), '/academies', Academy.fromJson);
});

final coachesProvider = StateNotifierProvider<DirectoryNotifier<Coach>, DirectoryState<Coach>>((ref) {
  return DirectoryNotifier<Coach>(ref.watch(dioProvider), '/coaches', Coach.fromJson);
});

final trialsProvider = StateNotifierProvider<DirectoryNotifier<Trial>, DirectoryState<Trial>>((ref) {
  return DirectoryNotifier<Trial>(ref.watch(dioProvider), '/trials', Trial.fromJson);
});

final tournamentsProvider = StateNotifierProvider<DirectoryNotifier<Tournament>, DirectoryState<Tournament>>((ref) {
  return DirectoryNotifier<Tournament>(ref.watch(dioProvider), '/tournaments', Tournament.fromJson);
});

final scholarshipsProvider = StateNotifierProvider<DirectoryNotifier<Scholarship>, DirectoryState<Scholarship>>((ref) {
  return DirectoryNotifier<Scholarship>(ref.watch(dioProvider), '/scholarships', Scholarship.fromJson);
});

final sponsorshipsProvider = StateNotifierProvider<DirectoryNotifier<Sponsorship>, DirectoryState<Sponsorship>>((ref) {
  return DirectoryNotifier<Sponsorship>(ref.watch(dioProvider), '/sponsorships', Sponsorship.fromJson);
});

final sportsVenuesProvider = StateNotifierProvider<DirectoryNotifier<SportsVenue>, DirectoryState<SportsVenue>>((ref) {
  return DirectoryNotifier<SportsVenue>(ref.watch(dioProvider), '/sports-venues', SportsVenue.fromJson);
});
