import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

/// Organizer profile (GET /me/organizer)
final myOrganizerProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/organizer');
  final body = resp.data;
  if (body is Map && body['data'] is Map) return Map<String, dynamic>.from(body['data'] as Map);
  return Map<String, dynamic>.from(body as Map);
});

/// Organizer's own tournaments (GET /me/tournaments).
final myTournamentsProvider =
    StateNotifierProvider<DirectoryNotifier<Tournament>, DirectoryState<Tournament>>((ref) {
  return DirectoryNotifier<Tournament>(ref.watch(dioProvider), '/me/tournaments', Tournament.fromJson);
});

/// Registrations for a tournament (GET /tournaments/{id}/registrations).
final tournamentRegistrationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/registrations');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Results for a tournament (GET /tournaments/{id}/results).
final tournamentResultsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/results');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Capacity for a tournament (GET /tournaments/{id}/capacity).
final tournamentCapacityProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/capacity');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Pending requests for a tournament (GET /tournaments/{id}/pending-requests)
final tournamentPendingRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/pending-requests');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Registrations filtered by approval_status (per_page 100 to cover pagination for organizer).
/// A status of `'all'` omits the filter and returns every registration.
final tournamentRegistrationsByStatusProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({String tournamentId, String status})>((ref, args) async {
  final query = <String, dynamic>{'per_page': 100};
  if (args.status != 'all') query['approval_status'] = args.status;
  final resp = await ref.watch(dioProvider).get('/tournaments/${args.tournamentId}/registrations', queryParameters: query);
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Organizer team members (GET /me/organizer/team).
class OrganizerTeamMember {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;

  OrganizerTeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  factory OrganizerTeamMember.fromJson(Map<String, dynamic> json) => OrganizerTeamMember(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'volunteer').toString(),
        status: (json['status'] ?? 'pending').toString(),
      );

  String get roleLabel => switch (role) {
        'co_organizer' => 'Co-organizer',
        'volunteer' => 'Volunteer',
        'staff' => 'Staff',
        'finance' => 'Finance',
        _ => role,
      };

  bool get isPending => status == 'pending';
}

final organizerTeamProvider = FutureProvider<List<OrganizerTeamMember>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/organizer/team');
  final data = resp.data['data'];
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((e) => OrganizerTeamMember.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

/// Actions on the organizer's team (invite / update / remove).
class OrganizerTeamActions {
  final Dio _dio;
  final Ref _ref;

  OrganizerTeamActions(this._dio, this._ref);

  Future<(bool, String?)> invite({
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      await _dio.post('/me/organizer/team', data: {
        'name': name,
        'email': email,
        'role': role,
      });
      _ref.invalidate(organizerTeamProvider);
      return (true, null);
    } catch (e) {
      return (false, e is DioException ? ApiException.fromDio(e).message : ApiException.messageFor(e));
    }
  }

  Future<(bool, String?)> updateRole(int id, String role) async {
    try {
      await _dio.patch('/me/organizer/team/$id', data: {'role': role});
      _ref.invalidate(organizerTeamProvider);
      return (true, null);
    } catch (e) {
      return (false, e is DioException ? ApiException.fromDio(e).message : ApiException.messageFor(e));
    }
  }

  Future<(bool, String?)> remove(int id) async {
    try {
      await _dio.delete('/me/organizer/team/$id');
      _ref.invalidate(organizerTeamProvider);
      return (true, null);
    } catch (e) {
      return (false, e is DioException ? ApiException.fromDio(e).message : ApiException.messageFor(e));
    }
  }
}

final organizerTeamActionsProvider = Provider<OrganizerTeamActions>((ref) {
  return OrganizerTeamActions(ref.watch(dioProvider), ref);
});

/// Organizer profile completion percentage (GET /me/completion-checklist).
final organizerCompletionProvider = FutureProvider<int>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/completion-checklist');
  final data = resp.data['data'];
  if (data is Map) {
    final pct = data['completion'];
    if (pct is num) return pct.round();
  }
  return 0;
});

/// Organizer analytics (GET /me/organizer/analytics)
class OrganizerAnalytics {
  final int totalTournaments;
  final int publishedTournaments;
  final int draftTournaments;
  final int closedTournaments;
  final int totalTrials;
  final int publishedTrials;
  final int draftTrials;
  final int totalRegistrations;
  final int pendingRegistrations;
  final int approvedRegistrations;
  final int rejectedRegistrations;
  final double approvalRate;
  final double revenueEstimate;
  final int totalCapacity;
  final int totalRegistered;
  final double utilizationPercent;
  final int spotsLeft;
  final int views;
  final List<({String date, int count})> dailySeries;
  final List<Map<String, dynamic>> topSources;
  final Map<String, dynamic>? deadlineAlert;
  final List<Map<String, dynamic>> categoryBreakdown;

  OrganizerAnalytics({
    required this.totalTournaments,
    required this.publishedTournaments,
    required this.draftTournaments,
    required this.closedTournaments,
    required this.totalTrials,
    required this.publishedTrials,
    required this.draftTrials,
    required this.totalRegistrations,
    required this.pendingRegistrations,
    required this.approvedRegistrations,
    required this.rejectedRegistrations,
    required this.approvalRate,
    required this.revenueEstimate,
    required this.totalCapacity,
    required this.totalRegistered,
    required this.utilizationPercent,
    required this.spotsLeft,
    this.views = 0,
    this.dailySeries = const [],
    this.topSources = const [],
    this.deadlineAlert,
    required this.categoryBreakdown,
  });

  factory OrganizerAnalytics.fromJson(Map<String, dynamic> json) {
    final series = <({String date, int count})>[];
    for (final row in (json['daily_series'] as List? ?? [])) {
      if (row is! Map) continue;
      series.add((
        date: (row['date'] ?? '').toString(),
        count: (row['count'] is num) ? (row['count'] as num).toInt() : 0,
      ));
    }
    return OrganizerAnalytics(
      totalTournaments: (json['tournaments']?['total'] ?? 0) as int,
      publishedTournaments: (json['tournaments']?['published'] ?? 0) as int,
      draftTournaments: (json['tournaments']?['draft'] ?? 0) as int,
      closedTournaments: (json['tournaments']?['closed'] ?? 0) as int,
      totalTrials: (json['trials']?['total'] ?? 0) as int,
      publishedTrials: (json['trials']?['published'] ?? 0) as int,
      draftTrials: (json['trials']?['draft'] ?? 0) as int,
      totalRegistrations: (json['registrations']?['total'] ?? 0) as int,
      pendingRegistrations: (json['registrations']?['pending'] ?? 0) as int,
      approvedRegistrations: (json['registrations']?['approved'] ?? 0) as int,
      rejectedRegistrations: (json['registrations']?['rejected'] ?? 0) as int,
      approvalRate: ((json['registrations']?['approval_rate'] ?? 0) as num).toDouble(),
      revenueEstimate: ((json['revenue']?['total_estimate'] ?? 0) as num).toDouble(),
      totalCapacity: (json['capacity']?['total_capacity'] ?? 0) as int,
      totalRegistered: (json['capacity']?['total_registered'] ?? 0) as int,
      utilizationPercent: ((json['capacity']?['utilization_percent'] ?? 0) as num).toDouble(),
      spotsLeft: (json['capacity']?['spots_left'] ?? 0) as int,
      views: (json['views'] ?? 0) is num ? ((json['views'] ?? 0) as num).toInt() : 0,
      dailySeries: series,
      topSources: (json['top_sources'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      deadlineAlert: json['deadline_alert'] as Map<String, dynamic>?,
      categoryBreakdown: (json['category_breakdown'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  /// Total events the organizer runs (tournaments + trials) — the "Events"
  /// tile of the design board's home stat row.
  int get totalEvents => totalTournaments + totalTrials;

  /// Series slice for a range pill (7D / 30D / 3M / 1Y) of the analytics card.
  List<({String date, int count})> seriesFor(int days) {
    if (dailySeries.isEmpty) return const [];
    if (days <= dailySeries.length) return dailySeries.sublist(dailySeries.length - days);
    return dailySeries;
  }
}

final organizerAnalyticsProvider = FutureProvider<OrganizerAnalytics>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/organizer/analytics');
  final data = resp.data['data'] as Map<String, dynamic>;
  return OrganizerAnalytics.fromJson(data);
});

class ProviderTournamentActions {
  final Dio _dio;
  final Ref _ref;
  ProviderTournamentActions(this._dio, this._ref);

  String _msg(Object e) => e is DioException ? ApiException.fromDio(e).message : ApiException.messageFor(e);

  Future<(bool, String?)> create(Map<String, dynamic> data) async {
    try {
      await _dio.post('/me/tournaments', data: data);
      _ref.read(myTournamentsProvider.notifier).refresh();
      _ref.invalidate(myEventsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> publish(String id) async {
    try {
      await _dio.post('/me/tournaments/$id/publish');
      _ref.read(myTournamentsProvider.notifier).refresh();
      _ref.invalidate(myEventsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> close(String id) async {
    try {
      await _dio.post('/me/tournaments/$id/close');
      _ref.read(myTournamentsProvider.notifier).refresh();
      _ref.invalidate(myEventsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> publishResult(String tournamentId, String resultId) async {
    try {
      await _dio.post('/tournaments/$tournamentId/results/$resultId/publish');
      _ref.invalidate(tournamentResultsProvider(tournamentId));
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> unpublishResult(String tournamentId, String resultId) async {
    try {
      await _dio.post('/tournaments/$tournamentId/results/$resultId/unpublish');
      _ref.invalidate(tournamentResultsProvider(tournamentId));
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> updatePayment(String registrationId, String paymentStatus) async {
    try {
      await _dio.patch('/registrations/tournaments/$registrationId/payment', data: {'payment_status': paymentStatus});
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> approveRegistration(String registrationId) async {
    try {
      await _dio.patch('/registrations/tournaments/$registrationId/approve');
      _ref.invalidate(tournamentRegistrationsProvider);
      _ref.invalidate(organizerAnalyticsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> rejectRegistration(String registrationId, String reason) async {
    try {
      await _dio.patch('/registrations/tournaments/$registrationId/reject', data: {'rejection_reason': reason});
      _ref.invalidate(tournamentRegistrationsProvider);
      _ref.invalidate(organizerAnalyticsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> approveTrialRegistration(String registrationId) async {
    try {
      await _dio.patch('/registrations/trials/$registrationId/approve');
      _ref.invalidate(organizerAnalyticsProvider);
      _ref.invalidate(trialRegistrantsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> rejectTrialRegistration(String registrationId, String reason) async {
    try {
      await _dio.patch('/registrations/trials/$registrationId/reject', data: {'rejection_reason': reason});
      _ref.invalidate(organizerAnalyticsProvider);
      _ref.invalidate(trialRegistrantsProvider);
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(String?, String?)> downloadTournamentIcs(String registrationId) async {
    try {
      final resp = await _dio.get('/registrations/tournaments/$registrationId/ics');
      final ics = resp.data is String ? resp.data as String : resp.data.toString();
      return (ics, null);
    } catch (e) {
      return (null, _msg(e));
    }
  }

  // Back-compat boolean wrappers
  Future<bool> createLegacy(Map<String, dynamic> data) async => (await create(data)).$1;
}

final providerTournamentActionsProvider = Provider<ProviderTournamentActions>((ref) {
  return ProviderTournamentActions(ref.watch(dioProvider), ref);
});
