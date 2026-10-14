import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Phase 7 leaderboard (v3 S.6 + AT.1 strip).
/// Backend: GET /leaderboard (podium + ranks 4-10), GET /leaderboard/strip.

class LeaderboardEntry {
  final int rank;
  final int points;
  final String athleteProfileId;
  final String displayName;
  final bool isMinor;
  final String? sportName;

  LeaderboardEntry({
    required this.rank,
    required this.points,
    required this.athleteProfileId,
    required this.displayName,
    this.isMinor = false,
    this.sportName,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        points: (json['points'] as num?)?.toInt() ?? 0,
        athleteProfileId: (json['athlete_profile_id'] ?? '').toString(),
        displayName: (json['display_name'] ?? 'Athlete').toString(),
        isMinor: json['is_minor'] == true,
        sportName: (json['sport'] as Map?)?['name']?.toString(),
      );
}

class LeaderboardState {
  final List<LeaderboardEntry> podium;
  final List<LeaderboardEntry> ranks;
  final bool isLoading;
  final String? error;

  LeaderboardState({this.podium = const [], this.ranks = const [], this.isLoading = false, this.error});
}

final leaderboardProvider =
    FutureProvider.family<LeaderboardState, Map<String, dynamic>>((ref, filters) async {
  try {
    final resp = await ref.watch(dioProvider).get('/leaderboard', queryParameters: filters.isEmpty ? null : filters);
    final data = resp.data['data'] as Map<String, dynamic>;
    List<LeaderboardEntry> parse(List? l) =>
        (l ?? []).map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
    return LeaderboardState(
      podium: parse(data['podium'] as List?),
      ranks: parse(data['ranks'] as List?),
    );
  } on DioException catch (e) {
    return LeaderboardState(error: ApiException.fromDio(e).message);
  }
});

final leaderboardStripProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  try {
    final resp = await ref.watch(dioProvider).get('/leaderboard/strip');
    final list = resp.data['data'] as List? ?? [];
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException {
    return [];
  }
});
