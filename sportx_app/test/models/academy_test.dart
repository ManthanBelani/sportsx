import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/academy.dart';

void main() {
  group('Academy.fromJson (backend API wiring)', () {
    test('parses real backend payload with nested logo and cover relations', () {
      final a = Academy.fromJson({
        'id': 1,
        'name': 'Pro Cricket Academy',
        'description': 'Premier cricket training facility',
        'address': '123 Sports Complex, SG Highway',
        'google_maps_url': 'https://maps.google.com/?q=pro-cricket-academy',
        'contact_number': '+91 79 2655 1234',
        'email': 'info@procricketacademy.com',
        'website': 'https://procricketacademy.com',
        'city_id': 1,
        'sport_id': 1,
        'hourly_rate': 500,
        'monthly_rate': 5000,
        'registration_link': 'https://procricketacademy.com/register',
        'status': 'published',
        'logo': {'id': 20, 'url': '/storage/academies/logo1.png', 'name': 'logo'},
        'cover': {'id': 21, 'url': '/storage/academies/cover1.png', 'name': 'cover'},
        'city': {'id': 1, 'name': 'Ahmedabad', 'state': 'Gujarat', 'is_active': 1},
        'sport': {'id': 1, 'name': 'Cricket', 'is_active': 1, 'sort_order': 1},
        'is_saved': false,
      });

      expect(a.id, 1);
      expect(a.name, 'Pro Cricket Academy');
      expect(a.description, 'Premier cricket training facility');
      expect(a.address, '123 Sports Complex, SG Highway');
      expect(a.logoUrl, '/storage/academies/logo1.png');
      expect(a.coverImageUrl, '/storage/academies/cover1.png');
      expect(a.hourlyRate, 500);
      expect(a.monthlyRate, 5000);
      expect(a.city?.name, 'Ahmedabad');
      expect(a.sport?.name, 'Cricket');
      expect(a.isSaved, false);
    });

    test('handles null logo and cover relations', () {
      final a = Academy.fromJson({
        'id': 2,
        'name': 'Local Football Club',
        'sport_id': 2,
        'status': 'published',
        'city': {'id': 2, 'name': 'Mumbai', 'state': 'Maharashtra', 'is_active': 1},
        'sport': {'id': 2, 'name': 'Football', 'is_active': 1, 'sort_order': 2},
        'is_saved': true,
      });

      expect(a.id, 2);
      expect(a.logoUrl, isNull);
      expect(a.coverImageUrl, isNull);
      expect(a.isSaved, true);
    });

    test('handles missing optional fields gracefully', () {
      final a = Academy.fromJson({
        'id': 3,
        'name': 'Minimal Academy',
        'status': 'draft',
      });

      expect(a.id, 3);
      expect(a.name, 'Minimal Academy');
      expect(a.description, isNull);
      expect(a.address, isNull);
      expect(a.logoUrl, isNull);
      expect(a.coverImageUrl, isNull);
      expect(a.city, isNull);
      expect(a.sport, isNull);
    });
  });
}
