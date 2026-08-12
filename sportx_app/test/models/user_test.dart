import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/user.dart';

void main() {
  group('User.fromJson (regression: B2 — /auth/me returns user fields flat in data)', () {
    // The /auth/me response is { "data": { <user fields>, "needs_onboarding" } };
    // the app now parses `data` directly (not data.user).
    test('parses user fields directly from the flat data object', () {
      final u = User.fromJson({
        'id': 5,
        'role': 'athlete',
        'name': 'QA Test',
        'email': 'qa@example.com',
        'phone': null,
        'email_verified_at': '2026-08-12T10:32:18+00:00',
        'status': 'active',
        'needs_onboarding': true, // extra key must be ignored by fromJson
      });

      expect(u.id, 5);
      expect(u.role, 'athlete');
      expect(u.email, 'qa@example.com');
      expect(u.userRole, UserRole.athlete);
    });
  });
}
