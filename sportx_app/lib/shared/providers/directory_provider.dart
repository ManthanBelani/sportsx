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
      // Laravel returns a flat paginator: top-level { current_page, data, last_page, … }
      // (no `meta` wrapper).
      final data = resp.data['data'] as List;
      final items = data.map((e) => fromJson(e)).toList();
      final hasMore = (resp.data['current_page'] ?? 1) < (resp.data['last_page'] ?? 1);
      state = DirectoryState(items: items, hasMore: hasMore, page: 1);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      // Parsing / contract errors (e.g. type mismatches) — surface instead of
      // leaving the directory stuck on an infinite loading spinner.
      state = DirectoryState(isLoading: false, hasMore: false, error: 'Failed to load: $e');
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
      final hasMore = (resp.data['current_page'] ?? 1) < (resp.data['last_page'] ?? 1);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        hasMore: hasMore,
        page: nextPage,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, hasMore: false, error: 'Failed to load more: $e');
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

final athletesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/athletes', queryParameters: {'per_page': 20});
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

final athleteDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/athletes/$id');
  final body = resp.data;
  return body is Map && body['data'] is Map
      ? body['data'] as Map<String, dynamic>
      : body as Map<String, dynamic>;
});

T _detailFromResponse<T>(Response resp, T Function(Map<String, dynamic>) fromJson) {
  final body = resp.data;
  final Map<String, dynamic> data =
      body is Map && body['data'] is Map ? body['data'] as Map<String, dynamic> : body as Map<String, dynamic>;
  return fromJson(data);
}

final academyDetailProvider = FutureProvider.family<Academy, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/academies/$id');
  return _detailFromResponse<Academy>(resp, Academy.fromJson);
});

final coachDetailProvider = FutureProvider.family<Coach, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/coaches/$id');
  return _detailFromResponse<Coach>(resp, Coach.fromJson);
});

final trialDetailProvider = FutureProvider.family<Trial, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/trials/$id');
  return _detailFromResponse<Trial>(resp, Trial.fromJson);
});

final tournamentDetailProvider = FutureProvider.family<Tournament, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$id');
  return _detailFromResponse<Tournament>(resp, Tournament.fromJson);
});

final scholarshipDetailProvider = FutureProvider.family<Scholarship, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/scholarships/$id');
  return _detailFromResponse<Scholarship>(resp, Scholarship.fromJson);
});

final sponsorshipDetailProvider = FutureProvider.family<Sponsorship, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/sponsorships/$id');
  return _detailFromResponse<Sponsorship>(resp, Sponsorship.fromJson);
});

final sportsVenueDetailProvider = FutureProvider.family<SportsVenue, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/sports-venues/$id');
  return _detailFromResponse<SportsVenue>(resp, SportsVenue.fromJson);
});
