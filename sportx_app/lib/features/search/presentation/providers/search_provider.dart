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
  athletes,
  coaches,
  academies,
  trials,
  tournaments,
  scholarships,
  sponsors,
}

class SearchFilters {
  final List<String> sports;
  final List<String> locations;
  final List<String> achievementLevels;
  final List<String> ageGroups;

  const SearchFilters({
    this.sports = const [],
    this.locations = const [],
    this.achievementLevels = const [],
    this.ageGroups = const [],
  });

  SearchFilters copyWith({
    List<String>? sports,
    List<String>? locations,
    List<String>? achievementLevels,
    List<String>? ageGroups,
  }) {
    return SearchFilters(
      sports: sports ?? this.sports,
      locations: locations ?? this.locations,
      achievementLevels: achievementLevels ?? this.achievementLevels,
      ageGroups: ageGroups ?? this.ageGroups,
    );
  }

  bool get hasActiveFilters =>
      sports.isNotEmpty ||
      locations.isNotEmpty ||
      achievementLevels.isNotEmpty ||
      ageGroups.isNotEmpty;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (sports.isNotEmpty) params['sports'] = sports.join(',');
    if (locations.isNotEmpty) params['locations'] = locations.join(',');
    if (achievementLevels.isNotEmpty) params['achievement_levels'] = achievementLevels.join(',');
    if (ageGroups.isNotEmpty) params['age_groups'] = ageGroups.join(',');
    return params;
  }
}

class SearchResult {
  final List<Map<String, dynamic>> athletes;
  final List<Map<String, dynamic>> coaches;
  final List<Map<String, dynamic>> academies;
  final List<Map<String, dynamic>> trials;
  final List<Map<String, dynamic>> tournaments;
  final List<Map<String, dynamic>> scholarships;
  final List<Map<String, dynamic>> sponsors;

  SearchResult({
    this.athletes = const [],
    this.coaches = const [],
    this.academies = const [],
    this.trials = const [],
    this.tournaments = const [],
    this.scholarships = const [],
    this.sponsors = const [],
  });

  int get totalCount =>
      athletes.length +
      coaches.length +
      academies.length +
      trials.length +
      tournaments.length +
      scholarships.length +
      sponsors.length;
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

  Future<void> search(String query, {bool appendResults = false}) async {
    if (query.trim().isEmpty && state.filters.hasActiveFilters) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null, query: query);

    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'page': appendResults ? state.page + 1 : 1,
        'per_page': 20,
      };
      queryParams.addAll(state.filters.toQueryParams());

      final response = await _dio.get('/search', queryParameters: queryParams);
      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      final newResults = SearchResult(
        athletes: List<Map<String, dynamic>>.from(data['athletes'] ?? []),
        coaches: List<Map<String, dynamic>>.from(data['coaches'] ?? []),
        academies: List<Map<String, dynamic>>.from(data['academies'] ?? []),
        trials: List<Map<String, dynamic>>.from(data['trials'] ?? []),
        tournaments: List<Map<String, dynamic>>.from(data['tournaments'] ?? []),
        scholarships: List<Map<String, dynamic>>.from(data['scholarships'] ?? []),
        sponsors: List<Map<String, dynamic>>.from(data['sponsors'] ?? []),
      );

      final meta = response.data['meta'] as Map<String, dynamic>?;
      final currentPage = meta?['current_page'] ?? 1;
      final lastPage = meta?['last_page'] ?? 1;

      if (appendResults && state.results != null) {
        state = state.copyWith(
          results: SearchResult(
            athletes: [...state.results!.athletes, ...newResults.athletes],
            coaches: [...state.results!.coaches, ...newResults.coaches],
            academies: [...state.results!.academies, ...newResults.academies],
            trials: [...state.results!.trials, ...newResults.trials],
            tournaments: [...state.results!.tournaments, ...newResults.tournaments],
            scholarships: [...state.results!.scholarships, ...newResults.scholarships],
            sponsors: [...state.results!.sponsors, ...newResults.sponsors],
          ),
          isLoading: false,
          page: currentPage,
          hasMore: currentPage < lastPage,
        );
      } else {
        state = state.copyWith(
          results: newResults,
          isLoading: false,
          page: currentPage,
          hasMore: currentPage < lastPage,
        );
      }

      // Save to recent searches
      if (query.trim().isNotEmpty) {
        _saveRecentSearch(query);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Search failed. Please try again.',
      );
    }
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
