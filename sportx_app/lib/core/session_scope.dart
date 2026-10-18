import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/features/coach/presentation/providers/coaching_enrollment_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/athlete_directory_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/connections_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/follow_block_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/scout_directory_provider.dart';
import 'package:sportx_app/features/connections/presentation/providers/scout_requests_provider.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:sportx_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/features/program/presentation/providers/program_provider.dart';
import 'package:sportx_app/features/saved/presentation/providers/saved_provider.dart';
import 'package:sportx_app/features/search/presentation/providers/search_provider.dart';
import 'package:sportx_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/athlete_discovery_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/leaderboard_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/observation_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/talent_scout_provider.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/features/athlete/presentation/providers/achievements_provider.dart';
import 'package:sportx_app/shared/providers/activity_provider.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/shared/providers/profile_provider.dart';
import 'package:sportx_app/shared/providers/registration_provider.dart';

/// Drops every user-scoped provider state.
///
/// Called on logout, on 401-driven force-logout, and whenever the signed-in
/// user id changes (account switch). Without this, StateNotifiers keep the
/// previous account's feed, chats, saved items and notifications in memory
/// and show them to the next account — a privacy defect, not just staleness.
///
/// Deliberately excluded: auth/dio/storage infra, public meta/trending
/// (static reference data), and the retired sponsor-era providers (their
/// screens are unreachable and never instantiated).
void resetUserScopedProviders(Ref ref) {
  // Shared.
  ref.invalidate(activityProvider);
  ref.invalidate(myTrialRegistrationsProvider);
  ref.invalidate(myTournamentRegistrationsProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(enquiryInboxProvider);
  ref.invalidate(enquiryDetailProvider);
  ref.invalidate(academiesProvider);
  ref.invalidate(coachesProvider);
  ref.invalidate(trialsProvider);
  ref.invalidate(tournamentsProvider);
  ref.invalidate(sportsVenuesProvider);
  ref.invalidate(athletesProvider);
  ref.invalidate(athleteDetailProvider);
  ref.invalidate(academyDetailProvider);
  ref.invalidate(coachDetailProvider);
  ref.invalidate(trialDetailProvider);
  ref.invalidate(tournamentDetailProvider);
  ref.invalidate(sportsVenueDetailProvider);

  // Feature state.
  ref.invalidate(myAcademyProvider);
  ref.invalidate(myTrialsProvider);
  ref.invalidate(trialRegistrantsProvider);
  ref.invalidate(adminProvider);
  ref.invalidate(conversationsProvider);
  ref.invalidate(conversationDetailProvider);
  ref.invalidate(coachProvider);
  ref.invalidate(coachEnrollmentsProvider);
  ref.invalidate(myCoachingEnrollmentsProvider);
  ref.invalidate(myConnectionsProvider);
  ref.invalidate(connectionRequestsProvider);
  ref.invalidate(connectionStatusProvider);
  ref.invalidate(connectionCountProvider);
  ref.invalidate(followingProvider);
  ref.invalidate(followersProvider);
  ref.invalidate(blockedUsersProvider);
  ref.invalidate(myReportsProvider);
  ref.invalidate(athleteDirectoryProvider);
  ref.invalidate(scoutDirectoryProvider);
  ref.invalidate(scoutRequestsProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(notificationPrefsProvider);
  ref.invalidate(onboardingProvider);
  ref.invalidate(opportunitiesProvider);
  ref.invalidate(opportunityDetailProvider);
  ref.invalidate(myOpportunitiesProvider);
  ref.invalidate(myOrganizerProvider);
  ref.invalidate(myTournamentsProvider);
  ref.invalidate(tournamentRegistrationsProvider);
  ref.invalidate(tournamentResultsProvider);
  ref.invalidate(tournamentCapacityProvider);
  ref.invalidate(tournamentPendingRequestsProvider);
  ref.invalidate(tournamentRegistrationsByStatusProvider);
  ref.invalidate(organizerAnalyticsProvider);
  ref.invalidate(programsProvider);
  ref.invalidate(programDetailProvider);
  ref.invalidate(myProgramsProvider);
  ref.invalidate(facilitiesProvider);
  ref.invalidate(savedProvider);
  ref.invalidate(searchProvider);
  ref.invalidate(settingsProvider);
  ref.invalidate(postsFeedProvider);
  ref.invalidate(postDetailProvider);
  ref.invalidate(postCommentsProvider);
  ref.invalidate(athleteDiscoveryProvider);
  ref.invalidate(leaderboardProvider);
  ref.invalidate(leaderboardStripProvider);
  ref.invalidate(observationsProvider);
  ref.invalidate(scoutConnectionProvider);
  ref.invalidate(scoutShortlistProvider);
  ref.invalidate(talentScoutProvider);
  ref.invalidate(myEventsProvider);
  ref.invalidate(eventRegistrationsProvider);
  ref.invalidate(eventResultsProvider);
}
