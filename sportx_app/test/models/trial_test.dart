import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/trial.dart';

void main() {
  group('Trial.fromJson (regression: B4 — varchar fee + JSON documents)', () {
    // Real shape returned by GET /api/v1/trials (entry_fee is a VARCHAR string,
    // required_documents is a JSON array). Previously these casts threw TypeErrors.
    test('parses the real backend payload without throwing', () {
      final t = Trial.fromJson({
        'id': 1,
        'posted_by_user_id': 1,
        'academy_id': null,
        'name': 'U-14 Cricket Trials Ahmedabad',
        'sport_id': 1,
        'event_datetime': '2026-08-26T05:15:29.000000Z',
        'venue': 'Narendra Modi Stadium',
        'city_id': 1,
        'contact_number': '+91 98765 43210',
        'required_documents': ['Aadhaar Card', 'Passport Photo'],
        'vacancies': 30,
        'entry_fee': '200',
        'status': 'published',
        'sport': {'id': 1, 'name': 'Cricket', 'is_active': 1, 'sort_order': 1},
        'city': {'id': 1, 'name': 'Ahmedabad', 'state': 'Gujarat', 'is_active': 1},
      });

      expect(t.id, 1);
      expect(t.title, 'U-14 Cricket Trials Ahmedabad');
      expect(t.registrationFee, 200.0);
      expect(t.totalSpots, 30);
      expect(t.documentRequired, 'Aadhaar Card, Passport Photo');
      expect(t.sport?.name, 'Cricket');
      expect(t.city?.name, 'Ahmedabad');
    });

    test('handles null fee and documents', () {
      final t = Trial.fromJson({'id': 2, 'name': 'X', 'sport_id': 1, 'status': 'draft'});

      expect(t.registrationFee, isNull);
      expect(t.documentRequired, isNull);
    });
  });
}
