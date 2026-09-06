import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/features/talent_scout/data/models/scout_shortlist_model.dart';

void main() {
  group('ScoutShortlistItem', () {
    test('fromJson parses shortlist item with athlete', () {
      final json = {
        'id': '15',
        'athlete': {
          'id': '42',
          'user': {'name': 'Rahul Sharma'},
          'sports': [
            {'name': 'Cricket'},
          ],
          'skill_level': 'advanced',
        },
        'notes': 'Promising fast bowler',
      };

      final item = ScoutShortlistItem.fromJson(json);

      expect(item.id, '15');
      expect(item.athlete.id, '42');
      expect(item.athlete.fullName, 'Rahul Sharma');
      expect(item.athlete.sports, ['Cricket']);
      expect(item.notes, 'Promising fast bowler');
    });

    test('fromJson handles null notes', () {
      final json = {
        'id': '10',
        'athlete': {
          'id': '1',
          'user': {'name': 'Test'},
        },
      };

      final item = ScoutShortlistItem.fromJson(json);

      expect(item.notes, isNull);
    });

    test('fromJson handles missing athlete with empty AthleteDiscovery', () {
      final json = {
        'id': '5',
      };

      final item = ScoutShortlistItem.fromJson(json);

      expect(item.id, '5');
      expect(item.athlete.fullName, 'Athlete');
      expect(item.athlete.sports, isEmpty);
    });
  });
}
