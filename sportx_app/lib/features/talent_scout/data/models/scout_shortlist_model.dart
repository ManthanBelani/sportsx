import 'package:sportx_app/features/talent_scout/data/models/athlete_discovery_model.dart';

class ScoutShortlistItem {
  final String id;
  final AthleteDiscovery athlete;
  final String? notes;
  final String status;
  final List<String> tags;

  ScoutShortlistItem({
    required this.id,
    required this.athlete,
    this.notes,
    this.status = 'under_review',
    this.tags = const [],
  });

  factory ScoutShortlistItem.fromJson(Map<String, dynamic> json) {
    final athleteJson = json['athlete'] as Map<String, dynamic>?;
    return ScoutShortlistItem(
      id: (json['id'] ?? '').toString(),
      athlete: AthleteDiscovery.fromJson(athleteJson ?? {}),
      notes: json['notes'] as String?,
      status: (json['status'] ?? 'under_review').toString(),
      tags: ((json['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }
}
