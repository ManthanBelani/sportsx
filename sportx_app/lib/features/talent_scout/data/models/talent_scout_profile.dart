class TalentScoutProfile {
  final int? id;
  final int userId;
  final String? organization;
  final String? affiliation;
  final List<int> sportsSpecialization;
  final int? experienceYears;
  final int? cityId;
  final String? bio;
  final int? photoMediaId;
  final bool listingStatus;

  TalentScoutProfile({
    this.id,
    required this.userId,
    this.organization,
    this.affiliation,
    this.sportsSpecialization = const [],
    this.experienceYears,
    this.cityId,
    this.bio,
    this.photoMediaId,
    this.listingStatus = true,
  });

  factory TalentScoutProfile.fromJson(Map<String, dynamic> json) {
    return TalentScoutProfile(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      organization: json['organization'] as String?,
      affiliation: json['affiliation'] as String?,
      sportsSpecialization: (json['sports_specialization'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      experienceYears: json['experience_years'] as int?,
      cityId: json['city_id'] as int?,
      bio: json['bio'] as String?,
      photoMediaId: json['photo_media_id'] as int?,
      listingStatus: json['listing_status'] == true || json['listing_status'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization': organization,
      'affiliation': affiliation,
      'sports_specialization': sportsSpecialization,
      'experience_years': experienceYears,
      'city_id': cityId,
      'bio': bio,
      if (photoMediaId != null) 'photo_media_id': photoMediaId,
      'listing_status': listingStatus,
    };
  }
}
