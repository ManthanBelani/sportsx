import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class ActivityEntry {
  final String id;
  final String title;
  final String status;
  final String? date;
  final String category;
  final String? entityType;
  final String? entityId;

  ActivityEntry({
    required this.id,
    required this.title,
    required this.status,
    this.date,
    required this.category,
    this.entityType,
    this.entityId,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json, {String? forcedCategory}) {
    final type = (json['type'] as String? ?? json['category'] as String? ?? forcedCategory ?? '').toLowerCase();
    final registration = json['registration'] ?? json;
    return ActivityEntry(
      id: (registration['id'] ?? json['id'])?.toString() ?? '',
      title: registration['title'] as String? ?? registration['name'] as String? ?? json['title'] as String? ?? json['name'] as String? ?? 'Untitled',
      status: (registration['status'] as String? ?? json['status'] as String? ?? 'pending').toLowerCase(),
      date: registration['date'] as String? ?? registration['start_date'] as String? ?? registration['trial_date'] as String? ?? registration['event_datetime'] as String? ?? registration['created_at'] as String? ?? json['created_at'] as String?,
      category: forcedCategory ?? (type.contains('tournament')
          ? 'tournament'
          : type.contains('sponsor') || type.contains('application')
              ? 'sponsorship'
              : 'trial'),
      entityType: json['registrable_type'] as String? ?? type,
      entityId: registration['id']?.toString() ?? json['id']?.toString(),
    );
  }

  factory ActivityEntry.fromTrialRegistration(Map<String, dynamic> json) {
    final trial = json['trial'] as Map<String, dynamic>? ?? json;
    return ActivityEntry(
      id: json['id']?.toString() ?? '',
      title: trial['title'] as String? ?? trial['name'] as String? ?? 'Trial',
      status: json['verification_status'] as String? ?? json['document_status'] as String? ?? 'registered',
      date: trial['trial_date'] as String? ?? trial['event_datetime'] as String? ?? json['created_at'] as String?,
      category: 'trial',
      entityType: 'trial',
      entityId: trial['id']?.toString() ?? json['trial_id']?.toString(),
    );
  }

  factory ActivityEntry.fromTournamentRegistration(Map<String, dynamic> json) {
    final tournament = json['tournament'] as Map<String, dynamic>? ?? json;
    return ActivityEntry(
      id: json['id']?.toString() ?? '',
      title: tournament['title'] as String? ?? tournament['name'] as String? ?? 'Tournament',
      status: json['status'] as String? ?? 'registered',
      date: tournament['start_date'] as String? ?? tournament['event_datetime'] as String? ?? json['created_at'] as String?,
      category: 'tournament',
      entityType: 'tournament',
      entityId: tournament['id']?.toString() ?? json['tournament_id']?.toString(),
    );
  }

  factory ActivityEntry.fromSponsorshipApplication(Map<String, dynamic> json) {
    final sponsorship = json['sponsorship'] as Map<String, dynamic>? ?? json;
    return ActivityEntry(
      id: json['id']?.toString() ?? '',
      title: sponsorship['title'] as String? ?? 'Sponsorship',
      status: json['status'] as String? ?? 'pending',
      date: sponsorship['application_deadline'] as String? ?? sponsorship['deadline'] as String? ?? json['created_at'] as String?,
      category: 'sponsorship',
      entityType: 'sponsorship',
      entityId: sponsorship['id']?.toString() ?? json['sponsorship_id']?.toString(),
    );
  }

  factory ActivityEntry.fromEnquiry(Map<String, dynamic> json) {
    return ActivityEntry(
      id: json['id']?.toString() ?? '',
      title: json['subject'] as String? ?? 'Enquiry: ${json['recipient_name'] ?? ''}',
      status: json['status'] as String? ?? 'new',
      date: json['created_at'] as String?,
      category: 'enquiry',
      entityType: 'enquiry',
      entityId: json['id']?.toString(),
    );
  }
}

class ActivityState {
  final List<ActivityEntry> items;
  final bool isLoading;
  final String? error;

  ActivityState({this.items = const [], this.isLoading = false, this.error});

  ActivityState copyWith({List<ActivityEntry>? items, bool? isLoading, String? error}) {
    return ActivityState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  final Dio _dio;

  ActivityNotifier(this._dio) : super(ActivityState()) {
    load();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final List<ActivityEntry> allItems = [];

      // Fetch all registrations (trials + tournaments) from unified endpoint
      try {
        final regResp = await _dio.get('/me/registrations');
        final regList = (regResp.data['data'] as List? ?? []);
        for (final item in regList) {
          final type = item['type'] as String? ?? '';
          if (type == 'trial') {
            allItems.add(ActivityEntry.fromTrialRegistration(item as Map<String, dynamic>));
          } else if (type == 'tournament') {
            allItems.add(ActivityEntry.fromTournamentRegistration(item as Map<String, dynamic>));
          }
        }
      } catch (_) {}

      // Fetch sponsorship applications
      try {
        final sponsorResp = await _dio.get('/me/sponsorship-applications');
        final sponsorList = (sponsorResp.data['data'] as List? ?? sponsorResp.data as List? ?? []);
        for (final item in sponsorList) {
          allItems.add(ActivityEntry.fromSponsorshipApplication(item as Map<String, dynamic>));
        }
      } catch (_) {}

      // Fetch enquiries
      try {
        final enquiryResp = await _dio.get('/me/enquiries');
        final enquiryList = (enquiryResp.data['data'] as List? ?? enquiryResp.data as List? ?? []);
        for (final item in enquiryList) {
          allItems.add(ActivityEntry.fromEnquiry(item as Map<String, dynamic>));
        }
      } catch (_) {}

      // Fallback: try /me/activity if no items found
      if (allItems.isEmpty) {
        try {
          final resp = await _dio.get('/me/activity');
          final list = (resp.data['data'] as List? ?? resp.data as List? ?? []);
          for (final item in list) {
            allItems.add(ActivityEntry.fromJson(item as Map<String, dynamic>));
          }
        } catch (_) {}
      }

      state = ActivityState(items: allItems);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load activity: $e');
    }
  }
}

final activityProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier(ref.watch(dioProvider));
});
