import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/features/talent_scout/data/models/talent_scout_profile.dart';

void main() {
  group('TalentScoutProfile', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'organization': 'Elite Agency',
        'affiliation': 'Cricket Association',
        'sports_specialization': [1, 3],
        'experience_years': 8,
        'city_id': 5,
        'bio': 'Experienced scout',
        'photo_media_id': 42,
        'listing_status': true,
      };

      final profile = TalentScoutProfile.fromJson(json);

      expect(profile.id, 1);
      expect(profile.userId, 10);
      expect(profile.organization, 'Elite Agency');
      expect(profile.affiliation, 'Cricket Association');
      expect(profile.sportsSpecialization, [1, 3]);
      expect(profile.experienceYears, 8);
      expect(profile.cityId, 5);
      expect(profile.bio, 'Experienced scout');
      expect(profile.photoMediaId, 42);
      expect(profile.listingStatus, true);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'sports_specialization': [1],
      };

      final profile = TalentScoutProfile.fromJson(json);

      expect(profile.organization, isNull);
      expect(profile.affiliation, isNull);
      expect(profile.experienceYears, isNull);
      expect(profile.cityId, isNull);
      expect(profile.bio, isNull);
      expect(profile.photoMediaId, isNull);
      expect(profile.listingStatus, false);
    });

    test('fromJson handles listing_status as integer', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'sports_specialization': [1],
        'listing_status': 1,
      };

      final profile = TalentScoutProfile.fromJson(json);
      expect(profile.listingStatus, true);
    });

    test('toJson produces correct map', () {
      final profile = TalentScoutProfile(
        userId: 10,
        organization: 'Agency',
        affiliation: 'Association',
        sportsSpecialization: [1, 2],
        experienceYears: 5,
        cityId: 3,
        bio: 'Bio text',
        photoMediaId: 100,
        listingStatus: true,
      );

      final json = profile.toJson();

      expect(json['organization'], 'Agency');
      expect(json['affiliation'], 'Association');
      expect(json['sports_specialization'], [1, 2]);
      expect(json['experience_years'], 5);
      expect(json['city_id'], 3);
      expect(json['bio'], 'Bio text');
      expect(json['photo_media_id'], 100);
      expect(json['listing_status'], true);
    });

    test('toJson omits photo_media_id when null', () {
      final profile = TalentScoutProfile(
        userId: 10,
        sportsSpecialization: [1],
      );

      final json = profile.toJson();

      expect(json.containsKey('photo_media_id'), false);
    });

    test('roundtrip fromJson -> toJson preserves data', () {
      final original = {
        'id': 5,
        'user_id': 10,
        'organization': 'Agency',
        'affiliation': 'Assoc',
        'sports_specialization': [1, 2, 3],
        'experience_years': 10,
        'city_id': 2,
        'bio': 'Bio',
        'photo_media_id': 99,
        'listing_status': true,
      };

      final profile = TalentScoutProfile.fromJson(original);
      final result = profile.toJson();

      expect(result['organization'], original['organization']);
      expect(result['affiliation'], original['affiliation']);
      expect(result['sports_specialization'], original['sports_specialization']);
      expect(result['experience_years'], original['experience_years']);
      expect(result['city_id'], original['city_id']);
      expect(result['bio'], original['bio']);
      expect(result['photo_media_id'], original['photo_media_id']);
      expect(result['listing_status'], original['listing_status']);
    });
  });
}
