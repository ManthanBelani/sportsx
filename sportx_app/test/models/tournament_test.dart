import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/tournament.dart';

void main() {
  group('Tournament.fromJson (regression: B4 — varchar entry_fee / prize_pool)', () {
    test('parses string fees as doubles without throwing', () {
      final t = Tournament.fromJson({
        'id': 1,
        'organizer_id': 1,
        'sport_id': 1,
        'name': 'U-16 State Cup 2026',
        'format': 'knockout',
        'start_date': '2026-09-02T00:00:00.000000Z',
        'end_date': '2026-09-07T00:00:00.000000Z',
        'registration_deadline': '2026-08-22T00:00:00.000000Z',
        'venue': 'GMDC Ground, Ahmedabad',
        'city_id': 1,
        'entry_fee': '500',
        'prize_pool': '50000',
        'gender': 'male',
        'status': 'published',
        'sport': {'id': 1, 'name': 'Cricket', 'is_active': 1, 'sort_order': 1},
      });

      expect(t.registrationFee, 500.0);
      expect(t.prizePool, 50000.0);
      expect(t.status, 'published');
    });

    test('handles null fees', () {
      final t = Tournament.fromJson({
        'id': 2,
        'sport_id': 1,
        'name': 'No-Fee Cup',
        'status': 'draft',
      });

      expect(t.registrationFee, isNull);
      expect(t.prizePool, isNull);
    });
  });
}
