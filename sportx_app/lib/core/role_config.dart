import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

/// Unified role model for the v3.2 information architecture.
///
/// Every role shares the same bottom-nav shell
/// [Home] [Explore] [(+) Create] [Community] [More]; only the *content*
/// (create tiles, "More" rows, dashboard target, accent) changes. This file is
/// the single source of truth for that per-role behaviour so screens stay dumb
/// and composable — the "common components" mandate.
enum SportXRole { athlete, coach, academy, organizer, scout, sponsor, admin }

SportXRole? sportXRoleFromId(String? id) {
  switch (id) {
    case 'athlete':
      return SportXRole.athlete;
    case 'coach':
      return SportXRole.coach;
    case 'academy':
      return SportXRole.academy;
    case 'organizer':
      return SportXRole.organizer;
    case 'scout':
    case 'talent_scout':
      return SportXRole.scout;
    case 'sponsor':
      return SportXRole.sponsor;
    case 'admin':
      return SportXRole.admin;
    default:
      return null;
  }
}

/// Role ids allowed to publish listings: opportunities, events/trials,
/// tournaments, training programs and venues. Athletes *consume* listings,
/// so they never get these create actions.
const Set<String> _listingCreatorRoles = {
  'coach',
  'academy',
  'organizer',
  'scout',
  'talent_scout',
  'sponsor',
  'admin',
};

/// Whether [roleId] may open create-listing routes such as /post-opportunity.
bool canCreateListings(String? roleId) => _listingCreatorRoles.contains(roleId);

/// Opportunity publishing (scholarships/sponsorships) — deliberately NOT
/// available to the organizer role (product decision); every other listing
/// creator keeps it.
const Set<String> _opportunityCreatorRoles = {
  'coach',
  'academy',
  'scout',
  'talent_scout',
  'sponsor',
  'admin',
};

/// Whether [roleId] may open /post-opportunity (scholarship or sponsorship).
bool canPostOpportunities(String? roleId) =>
    _opportunityCreatorRoles.contains(roleId);

enum CreatePriority { p0, p1, p2 }

/// A tile in the role-specific Create launcher (S.8).
class CreateTile {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color tintBg;
  final Color tintFg;
  final String route;
  final CreatePriority priority;

  const CreateTile({
    required this.id,
    required this.label,
    this.subtitle = '',
    required this.icon,
    this.tintBg = AppColors.yellowTint,
    this.tintFg = AppColors.warnText,
    required this.route,
    this.priority = CreatePriority.p0,
  });
}

/// A row in the role-specific More / account hub (S.15).
class MoreRow {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color tintBg;
  final Color tintFg;
  final String route;

  const MoreRow({
    required this.label,
    this.subtitle = '',
    required this.icon,
    this.tintBg = AppColors.yellowTint,
    this.tintFg = AppColors.primaryDarker,
    required this.route,
  });
}

/// A role-specific shortcut shown on the Discover (Explore) and Community
/// tabs — the same shell for everybody, the same content for nobody.
class DiscoverLink {
  final String label;
  final IconData icon;
  final String route;

  const DiscoverLink({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Per-role shell configuration.
class RoleConfig {
  final SportXRole role;
  final String label;
  final Color accent;
  final String homeRoute;
  final String? onboardingRoute;

  /// Own-profile entry point used by headers/More rows.
  final String profileRoute;
  final List<CreateTile> createTiles;
  final List<MoreRow> moreRows;

  /// Role-specific shortcuts for the Discover + Community tabs.
  final List<DiscoverLink> discoverLinks;

  const RoleConfig({
    required this.role,
    required this.label,
    required this.accent,
    required this.homeRoute,
    required this.onboardingRoute,
    required this.profileRoute,
    required this.createTiles,
    required this.moreRows,
    this.discoverLinks = const [],
  });
}

/// Shared "More" rows appended for every non-admin role (group A/B of the
/// design board: Saved → Messages).
const List<MoreRow> _sharedMoreRows = [
  MoreRow(label: 'Saved', icon: LucideIcons.bookmark, route: '/saved'),
  MoreRow(label: 'My Activity', icon: LucideIcons.activity, route: '/activity-hub'),
  MoreRow(label: 'Notifications', icon: LucideIcons.bell, route: '/notifications'),
  MoreRow(label: 'Messages', icon: LucideIcons.messageCircle, route: '/chat-list'),
];

/// Shared "More" rows that close the list (group C of the design board).
const List<MoreRow> _sharedMoreRowsTail = [
  MoreRow(label: 'Settings & Privacy', icon: LucideIcons.settings, route: '/settings'),
  MoreRow(label: 'Help & Support', icon: LucideIcons.circleHelp, route: '/help-support'),
];

/// Optional last row — shown for every role except the organizer, whose
/// "More" board stops at Help & Support.
const MoreRow _aboutSportXRow =
    MoreRow(label: 'About SportX', icon: LucideIcons.info, route: '/legal');

RoleConfig roleConfigFor(SportXRole role) {
  switch (role) {
    case SportXRole.athlete:
      return const RoleConfig(
        role: SportXRole.athlete,
        label: 'Athlete',
        accent: AppColors.yellowDeep,
        homeRoute: '/home',
        onboardingRoute: '/onboarding-1',
        profileRoute: '/profile',
        createTiles: [
          CreateTile(id: 'post', label: 'Create Post', subtitle: 'Share an update with your network', icon: LucideIcons.penLine, tintBg: Color(0xFFE3EFFF), tintFg: AppColors.info, route: '/create-post'),
          CreateTile(id: 'achievement', label: 'Add Achievement', subtitle: 'Medals, records & certificates', icon: LucideIcons.award, tintBg: Color(0xFFDCFCE7), tintFg: Color(0xFF15803D), route: '/add-achievement'),
          CreateTile(id: 'media', label: 'Upload Photo/Video', subtitle: 'Showcase your highlights', icon: LucideIcons.imagePlus, tintBg: Color(0xFFFEE2E2), tintFg: AppColors.error, route: '/media-gallery'),
        ],
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/profile'),
          MoreRow(label: 'Profile Completion', icon: LucideIcons.listChecks, route: '/profile-completion'),
          MoreRow(label: 'Leaderboard', icon: LucideIcons.trophy, route: '/athlete-leaderboard'),
          MoreRow(label: 'Manage Sports', icon: LucideIcons.dumbbell, route: '/manage-sports'),
          MoreRow(label: 'Achievements', icon: LucideIcons.award, route: '/achievements'),
          MoreRow(label: 'My Opportunities', icon: LucideIcons.megaphone, route: '/my-opportunities'),
          MoreRow(label: 'My Registrations', icon: LucideIcons.clipboardList, route: '/my-registrations'),
          ..._sharedMoreRows,
          ..._sharedMoreRowsTail,
          _aboutSportXRow,
        ],
        discoverLinks: [
          DiscoverLink(label: 'My Registrations', icon: LucideIcons.clipboardList, route: '/my-registrations'),
          DiscoverLink(label: 'Leaderboard', icon: LucideIcons.trophy, route: '/athlete-leaderboard'),
          DiscoverLink(label: 'My Achievements', icon: LucideIcons.award, route: '/achievements'),
          DiscoverLink(label: 'Nearby Events', icon: LucideIcons.calendar, route: '/tournaments'),
        ],
      );

    case SportXRole.coach:
      return const RoleConfig(
        role: SportXRole.coach,
        label: 'Coach',
        accent: AppColors.coach,
        homeRoute: '/coach-dashboard',
        onboardingRoute: '/coach-onboarding',
        profileRoute: '/coach-profile-edit',
        createTiles: [
          CreateTile(id: 'post', label: 'Create Post', subtitle: 'Share an update with your network', icon: LucideIcons.penLine, tintBg: Color(0xFFE3EFFF), tintFg: AppColors.info, route: '/create-post'),
          CreateTile(id: 'program', label: 'Create Training Program', subtitle: 'Add a new program', icon: LucideIcons.dumbbell, tintBg: Color(0xFFECE9FF), tintFg: AppColors.coach, route: '/post-program'),
          CreateTile(id: 'event', label: 'Create Event / Trial', subtitle: 'Post a new trial or tournament', icon: LucideIcons.calendarPlus, tintBg: Color(0xFFFCE7F3), tintFg: AppColors.organizer, route: '/post-trial'),
          CreateTile(id: 'opportunity', label: 'Create Opportunity', subtitle: 'Scholarships & sponsorships', icon: LucideIcons.megaphone, route: '/post-opportunity', priority: CreatePriority.p1),
          CreateTile(id: 'media', label: 'Upload Photo/Video', subtitle: 'Showcase your coaching', icon: LucideIcons.imagePlus, tintBg: Color(0xFFFEE2E2), tintFg: AppColors.error, route: '/media-gallery'),
          CreateTile(id: 'golive', label: 'Go Live / Webinar', subtitle: 'Host a live session', icon: LucideIcons.radio, tintBg: Color(0xFFFEE2E2), tintFg: AppColors.error, route: '/coach-go-live', priority: CreatePriority.p2),
        ],
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/coach-profile-edit'),
          MoreRow(label: 'My Training Programs', icon: LucideIcons.dumbbell, route: '/my-programs'),
          MoreRow(label: 'My Events', icon: LucideIcons.calendarDays, route: '/my-tournaments'),
          MoreRow(label: 'Achievements', icon: LucideIcons.award, route: '/achievements'),
          MoreRow(label: 'My Opportunities', icon: LucideIcons.megaphone, route: '/my-opportunities'),
          MoreRow(label: 'My Connections', icon: LucideIcons.users, route: '/my-connections'),
          ..._sharedMoreRows,
          ..._sharedMoreRowsTail,
          _aboutSportXRow,
        ],
        discoverLinks: [
          DiscoverLink(label: 'My Training Programs', icon: LucideIcons.dumbbell, route: '/my-programs'),
          DiscoverLink(label: 'My Events', icon: LucideIcons.calendar, route: '/my-tournaments'),
          DiscoverLink(label: 'My Athletes', icon: LucideIcons.users, route: '/athlete-directory'),
          DiscoverLink(label: 'Enquiries', icon: LucideIcons.inbox, route: '/coach-enquiry-inbox'),
        ],
      );

    case SportXRole.academy:
      return const RoleConfig(
        role: SportXRole.academy,
        label: 'Academy',
        accent: AppColors.academy,
        homeRoute: '/academy-dashboard',
        onboardingRoute: '/academy-onboarding',
        profileRoute: '/edit-academy-profile',
        createTiles: [
          CreateTile(id: 'post', label: 'Create Post', subtitle: 'Share an update with your network', icon: LucideIcons.penLine, tintBg: Color(0xFFE3EFFF), tintFg: AppColors.info, route: '/create-post'),
          CreateTile(id: 'program', label: 'Training Program', subtitle: 'Add a new program', icon: LucideIcons.dumbbell, tintBg: Color(0xFFECE9FF), tintFg: AppColors.coach, route: '/post-program'),
          CreateTile(id: 'event', label: 'Event / Trial', subtitle: 'Post a new trial or tournament', icon: LucideIcons.calendarPlus, tintBg: Color(0xFFFCE7F3), tintFg: AppColors.organizer, route: '/post-trial'),
          CreateTile(id: 'opportunity', label: 'Scholarship / Opportunity', subtitle: 'Post a scholarship or sponsorship', icon: LucideIcons.award, route: '/post-opportunity'),
          CreateTile(id: 'facility', label: 'Facility / Venue', subtitle: 'Showcase grounds, courts, gyms', icon: LucideIcons.building2, tintBg: Color(0xFFDBEAFE), tintFg: AppColors.info, route: '/post-facility'),
          CreateTile(id: 'media', label: 'Photos / Videos', subtitle: 'Add to your gallery', icon: LucideIcons.imagePlus, tintBg: Color(0xFFFEE2E2), tintFg: AppColors.error, route: '/media-gallery'),
          CreateTile(id: 'invite', label: 'Invite Athlete', subtitle: 'Link an athlete to your academy', icon: LucideIcons.userPlus, tintBg: Color(0xFFDCFCE7), tintFg: Color(0xFF15803D), route: '/academy-invite-athlete', priority: CreatePriority.p1),
        ],
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/edit-academy-profile'),
          MoreRow(label: 'Academy Programs', icon: LucideIcons.dumbbell, route: '/my-programs'),
          MoreRow(label: 'Our Athletes', icon: LucideIcons.users, route: '/showcase-athletes'),
          MoreRow(label: 'Events / Trials', icon: LucideIcons.calendarDays, route: '/my-trials'),
          MoreRow(label: 'Facilities', icon: LucideIcons.building2, route: '/facilities'),
          MoreRow(label: 'My Opportunities', icon: LucideIcons.award, route: '/my-opportunities'),
          MoreRow(label: 'My Staff', icon: LucideIcons.briefcase, route: '/academy-staff'),
          MoreRow(label: 'Collaborations', icon: LucideIcons.handshake, route: '/academy-collaborations'),
          MoreRow(label: 'Enquiries', icon: LucideIcons.inbox, route: '/enquiry-inbox'),
          ..._sharedMoreRows,
          ..._sharedMoreRowsTail,
          _aboutSportXRow,
        ],
        discoverLinks: [
          DiscoverLink(label: 'Our Athletes', icon: LucideIcons.users, route: '/showcase-athletes'),
          DiscoverLink(label: 'Academy Programs', icon: LucideIcons.dumbbell, route: '/my-programs'),
          DiscoverLink(label: 'Events / Trials', icon: LucideIcons.calendar, route: '/my-trials'),
          DiscoverLink(label: 'Facilities', icon: LucideIcons.building2, route: '/facilities'),
        ],
      );

    case SportXRole.organizer:
      return const RoleConfig(
        role: SportXRole.organizer,
        label: 'Event Organizer',
        accent: AppColors.organizer,
        homeRoute: '/organizer-dashboard',
        onboardingRoute: '/organizer-onboarding',
        profileRoute: '/organizer-profile',
        // Design board · org-create — Event, Venue, Announcement, Staff.
        // Go Live / Sponsorship / Media upload / Poll tiles removed for the
        // organizer role on product request (kept for other roles).
        createTiles: [
          CreateTile(id: 'event', label: 'Create Event', subtitle: 'Post trials, tournaments or camps', icon: LucideIcons.calendarPlus, tintBg: Color(0xFFFDE8E8), tintFg: Color(0xFFD9534F), route: '/post-tournament'),
          CreateTile(id: 'venue', label: 'Add Venue', subtitle: 'List your ground, court or facility', icon: LucideIcons.building2, tintBg: Color(0xFFDFF5E3), tintFg: Color(0xFF3FA55C), route: '/post-facility'),
          CreateTile(id: 'announcement', label: 'Post Announcement', subtitle: 'Share important updates', icon: LucideIcons.megaphone, tintBg: Color(0xFFECE6FB), tintFg: Color(0xFF8A6AEA), route: '/post-announcement'),
          CreateTile(id: 'staff', label: 'Add Staff / Organiser', subtitle: 'Add team members to your event', icon: LucideIcons.users, tintBg: Color(0xFFDFF5E3), tintFg: Color(0xFF3FA55C), route: '/organizer-team', priority: CreatePriority.p1),
        ],
        // Design board · org-more: menu A (8 role rows) → Saved / My Activity →
        // Notifications / Messages → Settings & Privacy / Help & Support.
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/organizer-profile'),
          MoreRow(label: 'My Events', icon: LucideIcons.calendarDays, route: '/my-tournaments'),
          MoreRow(label: 'Registrations & Participants', icon: LucideIcons.clipboardList, route: '/registration-management'),
          MoreRow(label: 'My Opportunities', icon: LucideIcons.megaphone, route: '/my-opportunities'),
          MoreRow(label: 'My Venues', icon: LucideIcons.building2, route: '/facilities'),
          MoreRow(label: 'My Team / Staff', icon: LucideIcons.users, route: '/organizer-team'),
          MoreRow(label: 'My Analytics', icon: LucideIcons.chartLine, route: '/organizer-analytics'),
          MoreRow(label: 'My Collaborations', icon: LucideIcons.handshake, route: '/my-collaborations'),
          ..._sharedMoreRows,
          ..._sharedMoreRowsTail,
        ],
        discoverLinks: [
          DiscoverLink(label: 'My Events', icon: LucideIcons.calendar, route: '/my-tournaments'),
          DiscoverLink(label: 'Registrations', icon: LucideIcons.clipboardList, route: '/registration-management'),
          DiscoverLink(label: 'Find Talent', icon: LucideIcons.search, route: '/scout-discovery'),
          DiscoverLink(label: 'My Venues', icon: LucideIcons.building2, route: '/facilities'),
        ],
      );

    case SportXRole.scout:
      return const RoleConfig(
        role: SportXRole.scout,
        label: 'Talent Scout',
        accent: AppColors.scout,
        homeRoute: '/scout-dashboard',
        onboardingRoute: '/scout-onboarding',
        profileRoute: '/scout-profile',
        createTiles: [
          CreateTile(id: 'shortlist', label: 'Add to Shortlist', subtitle: 'Track a talent in your pipeline', icon: LucideIcons.listPlus, tintBg: Color(0xFFDBEAFE), tintFg: AppColors.scout, route: '/scout-shortlist'),
          CreateTile(id: 'observation', label: 'Add Observation', subtitle: 'Quick scouting note', icon: LucideIcons.notebookPen, route: '/observations'),
          CreateTile(id: 'opportunity', label: 'Scouting Opportunity', subtitle: 'Post a scouting call', icon: LucideIcons.megaphone, route: '/post-opportunity'),
          CreateTile(id: 'event', label: 'Add Event / Trial', subtitle: 'Post a trial or camp', icon: LucideIcons.calendarPlus, tintBg: Color(0xFFFCE7F3), tintFg: AppColors.organizer, route: '/post-trial', priority: CreatePriority.p1),
          CreateTile(id: 'media', label: 'Upload Photo / Video', subtitle: 'Attach footage to reports', icon: LucideIcons.imagePlus, tintBg: Color(0xFFFEE2E2), tintFg: AppColors.error, route: '/media-gallery'),
        ],
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/scout-profile'),
          MoreRow(label: 'Shortlisted Talents', icon: LucideIcons.listPlus, route: '/scout-shortlist'),
          MoreRow(label: 'Scouting Reports', icon: LucideIcons.fileText, route: '/observations'),
          MoreRow(label: 'Discover Talents', icon: LucideIcons.search, route: '/scout-discovery'),
          MoreRow(label: 'My Opportunities', icon: LucideIcons.megaphone, route: '/my-opportunities'),
          MoreRow(label: 'My Connections', icon: LucideIcons.users, route: '/scout-connections'),
          ..._sharedMoreRows,
          ..._sharedMoreRowsTail,
          _aboutSportXRow,
        ],
        discoverLinks: [
          DiscoverLink(label: 'Discover Talents', icon: LucideIcons.search, route: '/scout-discovery'),
          DiscoverLink(label: 'Shortlisted Talents', icon: LucideIcons.listPlus, route: '/scout-shortlist'),
          DiscoverLink(label: 'Scouting Reports', icon: LucideIcons.fileText, route: '/observations'),
          DiscoverLink(label: 'My Opportunities', icon: LucideIcons.megaphone, route: '/my-opportunities'),
        ],
      );

    case SportXRole.sponsor:
      return const RoleConfig(
        role: SportXRole.sponsor,
        label: 'Sponsor',
        accent: AppColors.pink,
        homeRoute: '/sponsor-dashboard',
        onboardingRoute: '/sponsor-onboarding',
        profileRoute: '/profile',
        createTiles: [
          CreateTile(id: 'opportunity', label: 'Create Sponsorship', subtitle: 'Post a sponsorship opportunity', icon: LucideIcons.megaphone, tintBg: Color(0xFFFCE7F3), tintFg: AppColors.pink, route: '/post-opportunity'),
          CreateTile(id: 'post', label: 'Create Post', subtitle: 'Share an update', icon: LucideIcons.penLine, tintBg: Color(0xFFE3EFFF), tintFg: AppColors.info, route: '/create-post'),
          CreateTile(id: 'media', label: 'Upload Media', subtitle: 'Add brand assets', icon: LucideIcons.imagePlus, tintBg: Color(0xFFFEE2E2), tintFg: AppColors.error, route: '/media-gallery'),
        ],
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/profile'),
          MoreRow(label: 'My Sponsorships', icon: LucideIcons.handCoins, route: '/my-opportunities'),
          MoreRow(label: 'Discover Athletes', icon: LucideIcons.search, route: '/scout-discovery'),
          ..._sharedMoreRows,
          ..._sharedMoreRowsTail,
          _aboutSportXRow,
        ],
        discoverLinks: [
          DiscoverLink(label: 'Discover Athletes', icon: LucideIcons.search, route: '/scout-discovery'),
          DiscoverLink(label: 'My Sponsorships', icon: LucideIcons.handCoins, route: '/my-opportunities'),
          DiscoverLink(label: 'Open Opportunities', icon: LucideIcons.megaphone, route: '/opportunities'),
          DiscoverLink(label: 'Discover Events', icon: LucideIcons.calendar, route: '/tournaments'),
        ],
      );

    case SportXRole.admin:
      return const RoleConfig(
        role: SportXRole.admin,
        label: 'Admin',
        accent: AppColors.admin,
        homeRoute: '/admin/dashboard',
        onboardingRoute: null,
        profileRoute: '/admin/dashboard',
        createTiles: [],
        moreRows: [
          MoreRow(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/admin/dashboard'),
          MoreRow(label: 'Users', icon: LucideIcons.users, route: '/admin/users'),
          MoreRow(label: 'Approvals', icon: LucideIcons.badgeCheck, route: '/admin/approvals'),
          MoreRow(label: 'Moderation', icon: LucideIcons.shieldAlert, route: '/admin/moderation'),
          MoreRow(label: 'Content Manager', icon: LucideIcons.database, route: '/admin/content'),
          MoreRow(label: 'Master Data', icon: LucideIcons.listTree, route: '/admin/master-data'),
          MoreRow(label: 'Expiry Rules', icon: LucideIcons.timerOff, route: '/admin/expiry-rules'),
          MoreRow(label: 'Leaderboard Config', icon: LucideIcons.trophy, route: '/admin/leaderboard-config'),
          MoreRow(label: 'Reports', icon: LucideIcons.flag, route: '/admin/reports'),
          MoreRow(label: 'Analytics', icon: LucideIcons.chartLine, route: '/admin/analytics'),
          MoreRow(label: 'Settings', icon: LucideIcons.settings, route: '/admin/settings'),
        ],
        discoverLinks: [
          DiscoverLink(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/admin/dashboard'),
          DiscoverLink(label: 'Users', icon: LucideIcons.users, route: '/admin/users'),
          DiscoverLink(label: 'Approvals', icon: LucideIcons.badgeCheck, route: '/admin/approvals'),
          DiscoverLink(label: 'Moderation', icon: LucideIcons.shieldAlert, route: '/admin/moderation'),
        ],
      );
  }
}
