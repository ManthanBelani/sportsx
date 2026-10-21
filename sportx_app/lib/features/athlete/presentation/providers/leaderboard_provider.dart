import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';

enum LeaderboardPeriod { weekly, monthly, season, allTime }
enum LeaderboardCategory { xp, matches, wins, achievements, connections }

/// Unit label shown next to a score for the selected category.
String leaderboardCategoryUnit(LeaderboardCategory c) {
  switch (c) {
    case LeaderboardCategory.xp:
      return 'XP';
    case LeaderboardCategory.matches:
      return 'matches';
    case LeaderboardCategory.wins:
      return 'wins';
    case LeaderboardCategory.achievements:
      return 'achievements';
    case LeaderboardCategory.connections:
      return 'connections';
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int score;
  final String sport;
  final String level;
  final bool isCurrentUser;
  final String? city;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.score,
    required this.sport,
    required this.level,
    required this.isCurrentUser,
    this.city,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['athlete_profile_id']?.toString() ??
          json['id']?.toString() ??
          json['user_id']?.toString() ??
          '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? 'Athlete',
      avatarUrl: MediaUtils.resolveNullable(
          json['avatar_url']?.toString() ?? json['profile_photo_url']?.toString()),
      score: (json['score'] as num?)?.toInt() ?? (json['xp'] as num?)?.toInt() ?? 0,
      sport: json['sport']?.toString() ?? json['sport_name']?.toString() ?? 'General',
      level: json['level']?.toString() ?? json['skill_level']?.toString() ?? 'Beginner',
      isCurrentUser: json['is_current_user'] == true,
      city: json['city'] is Map
          ? (json['city'] as Map)['name']?.toString()
          : json['city']?.toString(),
    );
  }
}

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUserEntry;
  final int totalParticipants;
  final bool isLoading;
  final String? error;

  LeaderboardState({
    this.entries = const [],
    this.currentUserEntry,
    this.totalParticipants = 0,
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardEntry? currentUserEntry,
    int? totalParticipants,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      currentUserEntry: currentUserEntry ?? this.currentUserEntry,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Fetches leaderboard data with period, category, and sport filters
final leaderboardProvider = FutureProvider.family<LeaderboardState, ({
  LeaderboardPeriod period,
  LeaderboardCategory category,
  String? sportId,
})>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/me/leaderboard', queryParameters: {
    'period': params.period.name,
    'category': params.category.name,
    if (params.sportId != null) 'sport_id': params.sportId,
  });

  final data = (resp.data is Map ? resp.data['data'] : null) as Map<String, dynamic>?;
  final entries = (data?['entries'] as List? ?? [])
      .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList()
    // Do not rely on API ordering: sort by rank, then score as a tie-break.
    ..sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      return b.score.compareTo(a.score);
    });

  LeaderboardEntry? currentUserEntry;
  try {
    final raw = data?['current_user'];
    if (raw is Map<String, dynamic>) {
      currentUserEntry = LeaderboardEntry.fromJson(raw);
    }
  } catch (_) {}

  return LeaderboardState(
    entries: entries,
    currentUserEntry: currentUserEntry,
    totalParticipants:
        (data?['total_participants'] as num?)?.toInt() ?? entries.length,
  );
});

/// Optimistic update helper for XP changes
Future<void> refreshLeaderboard(WidgetRef ref, ({
  LeaderboardPeriod period,
  LeaderboardCategory category,
  String? sportId,
}) params) async {
  ref.invalidate(leaderboardProvider(params));
}