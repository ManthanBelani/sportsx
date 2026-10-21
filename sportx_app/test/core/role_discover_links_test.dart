import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/core/role_config.dart';

/// The Discover + Community tabs show role-specific shortcuts — the same
/// shell for everybody, but the content each role cares about.
void main() {
  group('RoleConfig.discoverLinks', () {
    test('every role has discover links', () {
      for (final role in SportXRole.values) {
        final config = roleConfigFor(role);
        expect(
          config.discoverLinks,
          isNotEmpty,
          reason: '${config.label} has no discover links',
        );
      }
    });

    test('links are unique per role and point at a route', () {
      for (final role in SportXRole.values) {
        final config = roleConfigFor(role);
        final routes = config.discoverLinks.map((l) => l.route).toList();
        expect(routes.toSet().length, routes.length,
            reason: '${config.label} has duplicate discover links');
        for (final link in config.discoverLinks) {
          expect(link.route, startsWith('/'));
          expect(link.label, isNotEmpty);
        }
      }
    });

    test('the links differ per role (role-specific content)', () {
      final athlete = roleConfigFor(SportXRole.athlete).discoverLinks.map((l) => l.route).toSet();
      final coach = roleConfigFor(SportXRole.coach).discoverLinks.map((l) => l.route).toSet();
      final organizer = roleConfigFor(SportXRole.organizer).discoverLinks.map((l) => l.route).toSet();
      final scout = roleConfigFor(SportXRole.scout).discoverLinks.map((l) => l.route).toSet();

      // Different roles must not end up with the exact same set of shortcuts.
      expect(athlete, isNot(equals(coach)));
      expect(coach, isNot(equals(organizer)));
      expect(organizer, isNot(equals(scout)));
      expect(athlete.intersection(scout), isEmpty);
    });

    test('the organizer sees their events, registrations and venues', () {
      final routes =
          roleConfigFor(SportXRole.organizer).discoverLinks.map((l) => l.route).toSet();
      expect(routes, contains('/my-tournaments'));
      expect(routes, contains('/registration-management'));
      expect(routes, contains('/facilities'));
    });

    test('the scout can discover talent', () {
      final routes = roleConfigFor(SportXRole.scout).discoverLinks.map((l) => l.route).toSet();
      expect(routes, contains('/scout-discovery'));
      expect(routes, contains('/scout-shortlist'));
    });
  });
}
