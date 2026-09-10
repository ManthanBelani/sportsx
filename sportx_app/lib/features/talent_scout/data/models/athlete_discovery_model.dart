import 'package:sportx_app/core/utils/media_utils.dart';

class AthleteDiscovery {
  final String id;
  final String fullName;
  final String? photoUrl;
  final List<String> sports;
  final String? ageGroupName;
  final String? cityName;
  final String? skillLevel;
  final int achievementsCount;

  AthleteDiscovery({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.sports = const [],
    this.ageGroupName,
    this.cityName,
    this.skillLevel,
    this.achievementsCount = 0,
  });

  factory AthleteDiscovery.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final sportsList = json['sports'] as List<dynamic>?;
    final sportsNames = sportsList
        ?.map((s) => s is Map<String, dynamic> ? (s['name'] ?? '').toString() : s.toString())
        .where((s) => s.isNotEmpty)
        .toList();
    final ageGroup = json['age_group'] as Map<String, dynamic>?;
    final city = json['city'] as Map<String, dynamic>?;
    final photo = json['photo'] as Map<String, dynamic>?;

    return AthleteDiscovery(
      id: (json['id'] ?? '').toString(),
      fullName: user?['name'] as String? ?? json['full_name'] as String? ?? 'Athlete',
      photoUrl: MediaUtils.resolveNullable(photo?['url'] as String?),
      sports: sportsNames ?? [],
      ageGroupName: ageGroup?['name'] as String?,
      cityName: city?['name'] as String?,
      skillLevel: json['skill_level'] as String?,
      achievementsCount: json['achievements_count'] as int? ?? 0,
    );
  }
}
