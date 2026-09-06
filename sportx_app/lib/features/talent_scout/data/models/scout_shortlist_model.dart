import 'package:sportx_app/features/talent_scout/data/models/athlete_discovery_model.dart';

class ScoutShortlistItem {
  final String id;
  final AthleteDiscovery athlete;
  final String? notes;

  ScoutShortlistItem({
    required this.id,
    required this.athlete,
    this.notes,
  });

  factory ScoutShortlistItem.fromJson(Map<String, dynamic> json) {
    final athleteJson = json['athlete'] as Map<String, dynamic>?;
    return ScoutShortlistItem(
      id: (json['id'] ?? '').toString(),
      athlete: AthleteDiscovery.fromJson(athleteJson ?? {}),
      notes: json['notes'] as String?,
    );
  }
}
