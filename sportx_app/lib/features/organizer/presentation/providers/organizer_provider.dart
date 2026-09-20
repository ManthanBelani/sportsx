import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
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

/// Registrations filtered by approval_status (per_page 100 to cover pagination for organizer)
final tournamentRegistrationsByStatusProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({String tournamentId, String status})>((ref, args) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/${args.tournamentId}/registrations', queryParameters: {'approval_status': args.status, 'per_page': 100});
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
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
    this.deadlineAlert,
    required this.categoryBreakdown,
  });

  factory OrganizerAnalytics.fromJson(Map<String, dynamic> json) {
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
      deadlineAlert: json['deadline_alert'] as Map<String, dynamic>?,
      categoryBreakdown: (json['category_breakdown'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
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
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> publish(String id) async {
    try {
      await _dio.post('/me/tournaments/$id/publish');
      _ref.read(myTournamentsProvider.notifier).refresh();
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> close(String id) async {
    try {
      await _dio.post('/me/tournaments/$id/close');
      _ref.read(myTournamentsProvider.notifier).refresh();
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
      return (true, null);
    } catch (e) {
      return (false, _msg(e));
    }
  }

  Future<(bool, String?)> rejectTrialRegistration(String registrationId, String reason) async {
    try {
      await _dio.patch('/registrations/trials/$registrationId/reject', data: {'rejection_reason': reason});
      _ref.invalidate(organizerAnalyticsProvider);
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
