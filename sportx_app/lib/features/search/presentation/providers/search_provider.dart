import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/coach.dart';
import 'package:sportx_app/shared/models/academy.dart';
import 'package:sportx_app/shared/models/trial.dart';
import 'package:sportx_app/shared/models/tournament.dart';
import 'package:sportx_app/shared/models/scholarship.dart';
import 'package:sportx_app/shared/models/sponsorship.dart';

enum SearchCategory {
  all,
  coaches,
  academies,
  trials,
  tournaments,
  scholarships,
  sponsors,
  sportsVenues,
}

class SearchFilters {
  final List<String> sports;
  final List<String> locations;
  final List<String> achievementLevels;
  final List<String> ageGroups;
  final int? sportId;
  final int? cityId;
  final String gender; // 'all' | 'male' | 'female'
  final double? feeMin;
  final double? feeMax;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const SearchFilters({
    this.sports = const [],
    this.locations = const [],
    this.achievementLevels = const [],
    this.ageGroups = const [],
    this.sportId,
    this.cityId,
    this.gender = 'all',
    this.feeMin,
    this.feeMax,
    this.dateFrom,
    this.dateTo,
  });

  SearchFilters copyWith({
    List<String>? sports,
    List<String>? locations,
    List<String>? achievementLevels,
    List<String>? ageGroups,
    int? sportId,
    bool clearSportId = false,
    int? cityId,
    bool clearCityId = false,
    String? gender,
    double? feeMin,
    bool clearFeeMin = false,
    double? feeMax,
    bool clearFeeMax = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
  }) {
    return SearchFilters(
      sports: sports ?? this.sports,
      locations: locations ?? this.locations,
      achievementLevels: achievementLevels ?? this.achievementLevels,
      ageGroups: ageGroups ?? this.ageGroups,
      sportId: clearSportId ? null : (sportId ?? this.sportId),
      cityId: clearCityId ? null : (cityId ?? this.cityId),
      gender: gender ?? this.gender,
      feeMin: clearFeeMin ? null : (feeMin ?? this.feeMin),
      feeMax: clearFeeMax ? null : (feeMax ?? this.feeMax),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  bool get hasActiveFilters =>
      sports.isNotEmpty ||
      locations.isNotEmpty ||
      achievementLevels.isNotEmpty ||
      ageGroups.isNotEmpty ||
      sportId != null ||
      cityId != null ||
      gender != 'all' ||
      feeMin != null ||
      feeMax != null ||
      dateFrom != null ||
      dateTo != null;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (sportId != null) params['sport_id'] = sportId;
    if (cityId != null) params['city_id'] = cityId;
    if (gender != 'all') params['gender'] = gender;
    if (feeMin != null) params['fee_min'] = feeMin;
    if (feeMax != null) params['fee_max'] = feeMax;
    if (dateFrom != null) {
      params['date_from'] = '${dateFrom!.year.toString().padLeft(4, '0')}-${dateFrom!.month.toString().padLeft(2, '0')}-${dateFrom!.day.toString().padLeft(2, '0')}';
    }
    if (dateTo != null) {
      params['date_to'] = '${dateTo!.year.toString().padLeft(4, '0')}-${dateTo!.month.toString().padLeft(2, '0')}-${dateTo!.day.toString().padLeft(2, '0')}';
    }
    return params;
  }
}

class SearchResult {
  final List<Map<String, dynamic>> coaches;
  final List<Map<String, dynamic>> academies;
  final List<Map<String, dynamic>> trials;
  final List<Map<String, dynamic>> tournaments;
  final List<Map<String, dynamic>> scholarships;
  final List<Map<String, dynamic>> sponsors;
  final List<Map<String, dynamic>> sportsVenues;

  SearchResult({
    this.coaches = const [],
    this.academies = const [],
    this.trials = const [],
    this.tournaments = const [],
    this.scholarships = const [],
    this.sponsors = const [],
    this.sportsVenues = const [],
  });

  int get totalCount =>
      coaches.length +
      academies.length +
      trials.length +
      tournaments.length +
      scholarships.length +
      sponsors.length +
      sportsVenues.length;
}

class SearchState {
  final String query;
  final SearchCategory category;
  final SearchFilters filters;
  final SearchResult? results;
  final List<String> recentSearches;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  SearchState({
    this.query = '',
    this.category = SearchCategory.all,
    this.filters = const SearchFilters(),
    this.results,
    this.recentSearches = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
  });

  SearchState copyWith({
    String? query,
    SearchCategory? category,
    SearchFilters? filters,
    SearchResult? results,
    List<String>? recentSearches,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      category: category ?? this.category,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final Dio _dio;

  SearchNotifier(this._dio) : super(SearchState());

  /// Injects a `type` label into each raw item so the UI can render and
  /// navigate correctly regardless of which API list it came from.
  List<Map<String, dynamic>> _typed(List<dynamic>? raw, String type) {
    return (raw ?? [])
        .whereType<Map>()
        .map((e) => {...e, 'type': type})
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> search(String query, {bool appendResults = false}) async {
    if (query.trim().isEmpty && !state.filters.hasActiveFilters) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null, query: query);

    try {
      final queryParams = <String, dynamic>{
        if (query.trim().isNotEmpty) 'q': query,
        'page': appendResults ? state.page + 1 : 1,
        'per_page': 20,
      };
      queryParams.addAll(state.filters.toQueryParams());

      final response = await _dio.get('/search', queryParameters: queryParams);
      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      final newResults = SearchResult(
        coaches: _typed(data['coaches'], 'coach'),
        academies: _typed(data['academies'], 'academy'),
        trials: _typed(data['trials'], 'trial'),
        tournaments: _typed(data['tournaments'], 'tournament'),
        scholarships: _typed(data['scholarships'], 'scholarship'),
        // API key is `sponsorships` — map into the sponsors bucket.
        sponsors: _typed(data['sponsorships'], 'sponsorship'),
        sportsVenues: _typed(data['sports_venues'], 'sports_venue'),
      );

      SearchResult merged;
      if (appendResults && state.results != null) {
        final prev = state.results!;
        merged = SearchResult(
          coaches: [...prev.coaches, ...newResults.coaches],
          academies: [...prev.academies, ...newResults.academies],
          trials: [...prev.trials, ...newResults.trials],
          tournaments: [...prev.tournaments, ...newResults.tournaments],
          scholarships: [...prev.scholarships, ...newResults.scholarships],
          sponsors: [...prev.sponsors, ...newResults.sponsors],
          sportsVenues: [...prev.sportsVenues, ...newResults.sportsVenues],
        );
      } else {
        merged = newResults;
      }

      final meta = response.data['meta'] as Map<String, dynamic>?;
      final currentPage = meta?['current_page'] ?? 1;
      final lastPage = meta?['last_page'] ?? 1;

      state = state.copyWith(
        results: merged,
        isLoading: false,
        page: currentPage,
        hasMore: currentPage < lastPage,
      );

      // Save to recent searches
      if (query.trim().isNotEmpty) {
        _saveRecentSearch(query);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiException.fromDio(e).message,
      );
    }
  }

  Future<void> loadRecentSearches() async {
    try {
      final resp = await _dio.get('/me/recent-searches');
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      state = state.copyWith(recentSearches: list);
    } catch (_) {
      // Recent searches are non-critical — ignore failures.
    }
  }

  Future<void> removeRecentSearch(String query) async {
    state = state.copyWith(
      recentSearches: state.recentSearches.where((s) => s != query).toList(),
    );
  }

  void setCategory(SearchCategory category) {
    state = state.copyWith(category: category);
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
    if (state.query.isNotEmpty || filters.hasActiveFilters) {
      search(state.query);
    }
  }

  void loadMore() {
    if (!state.isLoading && state.hasMore) {
      search(state.query, appendResults: true);
    }
  }

  void _saveRecentSearch(String query) {
    final updated = [
      query,
      ...state.recentSearches.where((s) => s != query),
    ].take(10).toList();
    state = state.copyWith(recentSearches: updated);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }

  void clearResults() {
    state = state.copyWith(
      results: null,
      query: '',
      page: 1,
      hasMore: false,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final dio = ref.watch(dioProvider);
  return SearchNotifier(dio);
});

// Trending searches mock data
final trendingSearchesProvider = Provider<List<String>>((ref) {
  return [
    'Cricket',
    'Football',
    'Badminton',
    'Tennis',
    'IPL Trials',
    'State Championship',
    'Ahmedabad',
    'Mumbai',
  ];
});
