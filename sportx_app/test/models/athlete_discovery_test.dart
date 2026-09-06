import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/features/talent_scout/data/models/athlete_discovery_model.dart';

void main() {
  group('AthleteDiscovery', () {
    test('fromJson parses athlete with nested user object', () {
      final json = {
        'id': '42',
        'user': {'name': 'Rahul Sharma'},
        'photo': {'url': '/storage/photos/rahul.jpg'},
        'sports': [
          {'name': 'Cricket'},
          {'name': 'Football'},
        ],
        'age_group': {'name': 'Under 18'},
        'city': {'name': 'Mumbai'},
        'skill_level': 'advanced',
        'achievements_count': 5,
      };

      final athlete = AthleteDiscovery.fromJson(json);

      expect(athlete.id, '42');
      expect(athlete.fullName, 'Rahul Sharma');
      expect(athlete.photoUrl, '/storage/photos/rahul.jpg');
      expect(athlete.sports, ['Cricket', 'Football']);
      expect(athlete.ageGroupName, 'Under 18');
      expect(athlete.cityName, 'Mumbai');
      expect(athlete.skillLevel, 'advanced');
      expect(athlete.achievementsCount, 5);
    });

    test('fromJson handles flat full_name without nested user', () {
      final json = {
        'id': '10',
        'full_name': 'Priya Patel',
        'sports': ['Tennis'],
        'skill_level': 'beginner',
      };

      final athlete = AthleteDiscovery.fromJson(json);

      expect(athlete.id, '10');
      expect(athlete.fullName, 'Priya Patel');
      expect(athlete.sports, ['Tennis']);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'id': '1',
        'user': {'name': 'Test'},
      };

      final athlete = AthleteDiscovery.fromJson(json);

      expect(athlete.sports, isEmpty);
      expect(athlete.ageGroupName, isNull);
      expect(athlete.cityName, isNull);
      expect(athlete.skillLevel, isNull);
      expect(athlete.achievementsCount, 0);
    });

    test('fromJson handles sports as plain strings', () {
      final json = {
        'id': '1',
        'user': {'name': 'Test'},
        'sports': ['Cricket', 'Hockey'],
      };

      final athlete = AthleteDiscovery.fromJson(json);

      expect(athlete.sports, ['Cricket', 'Hockey']);
    });

    test('fromJson defaults fullName to Athlete when user and full_name are null', () {
      final json = {
        'id': '1',
      };

      final athlete = AthleteDiscovery.fromJson(json);

      expect(athlete.fullName, 'Athlete');
    });
  });
}
