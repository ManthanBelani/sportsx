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
      return SportXRole.scout;
    case 'sponsor':
      return SportXRole.sponsor;
    case 'admin':
      return SportXRole.admin;
    default:
      return null;
  }
}

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

  const RoleConfig({
    required this.role,
    required this.label,
    required this.accent,
    required this.homeRoute,
    required this.onboardingRoute,
    required this.profileRoute,
    required this.createTiles,
    required this.moreRows,
  });
}

/// Shared "More" rows appended for every non-admin role.
const List<MoreRow> _sharedMoreRows = [
  MoreRow(label: 'Saved', icon: LucideIcons.bookmark, route: '/saved'),
  MoreRow(label: 'My Activity', icon: LucideIcons.activity, route: '/activity-hub'),
  MoreRow(label: 'Notifications', icon: LucideIcons.bell, route: '/notifications'),
  MoreRow(label: 'Messages', icon: LucideIcons.messageCircle, route: '/chat-list'),
  MoreRow(label: 'Settings & Privacy', icon: LucideIcons.settings, route: '/settings'),
  MoreRow(label: 'Help & Support', icon: LucideIcons.circleHelp, route: '/help-support'),
  MoreRow(label: 'About SportX', icon: LucideIcons.info, route: '/legal'),
];

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
          CreateTile(id: 'opportunity', label: 'Create Opportunity', subtitle: 'Scholarships, sponsorships & more', icon: LucideIcons.megaphone, route: '/post-opportunity', priority: CreatePriority.p1),
          CreateTile(id: 'event', label: 'Create Event', subtitle: 'Post a trial or tournament', icon: LucideIcons.calendarPlus, tintBg: Color(0xFFFCE7F3), tintFg: AppColors.organizer, route: '/post-trial', priority: CreatePriority.p1),
        ],
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/profile'),
          MoreRow(label: 'Profile Completion', icon: LucideIcons.listChecks, route: '/profile-completion'),
          MoreRow(label: 'Manage Sports', icon: LucideIcons.dumbbell, route: '/manage-sports'),
          MoreRow(label: 'Achievements', icon: LucideIcons.award, route: '/achievements'),
          MoreRow(label: 'My Opportunities', icon: LucideIcons.megaphone, route: '/my-opportunities'),
          MoreRow(label: 'My Registrations', icon: LucideIcons.clipboardList, route: '/my-registrations'),
          ..._sharedMoreRows,
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
        ],
      );

    case SportXRole.organizer:
      return const RoleConfig(
        role: SportXRole.organizer,
        label: 'Organizer',
        accent: AppColors.organizer,
        homeRoute: '/organizer-dashboard',
        onboardingRoute: '/organizer-onboarding',
        profileRoute: '/organizer-profile',
        createTiles: [
          CreateTile(id: 'event', label: 'Create Event', subtitle: 'Post a new tournament or trial', icon: LucideIcons.calendarPlus, tintBg: Color(0xFFFCE7F3), tintFg: AppColors.organizer, route: '/post-tournament'),
          CreateTile(id: 'opportunity', label: 'Create Opportunity', subtitle: 'Scholarships & sponsorships', icon: LucideIcons.megaphone, route: '/post-opportunity'),
          CreateTile(id: 'venue', label: 'Add Venue', subtitle: 'Showcase a ground or court', icon: LucideIcons.building2, tintBg: Color(0xFFDBEAFE), tintFg: AppColors.info, route: '/post-facility', priority: CreatePriority.p1),
          CreateTile(id: 'post', label: 'Create Post', subtitle: 'Share an update', icon: LucideIcons.penLine, tintBg: Color(0xFFE3EFFF), tintFg: AppColors.info, route: '/create-post'),
          CreateTile(id: 'media', label: 'Photos / Videos', subtitle: 'Add to your gallery', icon: LucideIcons.imagePlus, tintBg: Color(0xFFFEE2E2), tintFg: AppColors.error, route: '/media-gallery'),
        ],
        moreRows: [
          MoreRow(label: 'My Profile', icon: LucideIcons.user, route: '/organizer-profile'),
          MoreRow(label: 'My Events', icon: LucideIcons.calendarDays, route: '/my-tournaments'),
          MoreRow(label: 'Registrations', icon: LucideIcons.clipboardList, route: '/registration-management'),
          MoreRow(label: 'My Venues', icon: LucideIcons.building2, route: '/facilities'),
          MoreRow(label: 'Analytics', icon: LucideIcons.chartLine, route: '/organizer-analytics'),
          MoreRow(label: 'Post Announcement', icon: LucideIcons.megaphone, route: '/post-announcement'),
          MoreRow(label: 'My Team', icon: LucideIcons.users, route: '/organizer-team'),
          MoreRow(label: 'Collaborations', icon: LucideIcons.handshake, route: '/my-collaborations'),
          MoreRow(label: 'My Opportunities', icon: LucideIcons.megaphone, route: '/my-opportunities'),
          ..._sharedMoreRows,
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
      );
  }
}
