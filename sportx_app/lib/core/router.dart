import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:sportx_app/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:sportx_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:sportx_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sportx_app/features/home/presentation/screens/home_screen.dart';
import 'package:sportx_app/features/saved/presentation/screens/saved_screen.dart';
import 'package:sportx_app/features/athlete/presentation/screens/profile_screen.dart';
import 'package:sportx_app/features/onboarding/presentation/screens/onboarding_sport_age_screen.dart';
import 'package:sportx_app/features/onboarding/presentation/screens/onboarding_skill_location_screen.dart';
import 'package:sportx_app/features/academy/presentation/screens/academy_directory_screen.dart';
import 'package:sportx_app/features/academy/presentation/screens/academy_detail_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_directory_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_detail_screen.dart';
import 'package:sportx_app/features/trial/presentation/screens/trial_directory_screen.dart';
import 'package:sportx_app/features/trial/presentation/screens/trial_detail_screen.dart';
import 'package:sportx_app/features/tournament/presentation/screens/tournament_directory_screen.dart';
import 'package:sportx_app/features/tournament/presentation/screens/tournament_detail_screen.dart';
import 'package:sportx_app/shared/presentation/screens/enquire_screen.dart';
import 'package:sportx_app/features/trial/presentation/screens/trial_registration_screen.dart';
import 'package:sportx_app/features/tournament/presentation/screens/tournament_registration_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/registration_confirmation_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_dashboard_screen.dart';
import 'package:sportx_app/features/academy/presentation/screens/academy_dashboard_screen.dart';
import 'package:sportx_app/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/enquiry_inbox_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/enquiry_detail_screen.dart';
import 'package:sportx_app/features/academy/presentation/screens/trial_posting_screen.dart';
import 'package:sportx_app/features/organizer/presentation/screens/tournament_posting_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_profile_posting_screen.dart';
import 'package:sportx_app/features/academy/presentation/screens/academy_profile_posting_screen.dart';
import 'package:sportx_app/features/organizer/presentation/screens/organizer_onboarding_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/sponsor_onboarding_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/sponsorship_posting_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/sponsor_pitch_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/registrant_detail_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_onboarding_screen.dart';
import 'package:sportx_app/features/academy/presentation/screens/academy_onboarding_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/registrant_list_screen.dart';
import 'package:sportx_app/features/organizer/presentation/screens/registration_management_screen.dart';
import 'package:sportx_app/features/organizer/presentation/screens/capacity_management_screen.dart';
import 'package:sportx_app/features/organizer/presentation/screens/results_publishing_screen.dart';
import 'package:sportx_app/features/organizer/presentation/screens/results_view_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/sponsor_dashboard_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/athlete_discovery_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/athlete_profile_view_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/applications_inbox_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/application_detail_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/shortlist_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/my_trials_management_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/my_tournaments_management_screen.dart';
import 'package:sportx_app/features/sponsor/presentation/screens/my_sponsorships_management_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/activity_hub_screen.dart';
import 'package:sportx_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sportx_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sportx_app/features/settings/presentation/screens/help_support_screen.dart';
import 'package:sportx_app/features/scholarship/presentation/screens/scholarship_list_screen.dart';
import 'package:sportx_app/features/sports_venue/presentation/screens/sports_venue_list_screen.dart';
import 'package:sportx_app/features/social/presentation/screens/create_post_screen.dart';
import 'package:sportx_app/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:sportx_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:sportx_app/features/athlete/presentation/screens/edit_profile_screen.dart';
import 'package:sportx_app/features/athlete/presentation/screens/add_achievement_screen.dart';
import 'package:sportx_app/features/athlete/presentation/screens/media_gallery_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/add_credential_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/edit_facilities_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/showcase_athletes_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/sponsor_directory_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_profile_detail_screen.dart';
import 'package:sportx_app/features/search/presentation/screens/search_filter_screen.dart';
import 'package:sportx_app/features/search/presentation/screens/universal_search_screen.dart';
import 'package:sportx_app/features/connections/presentation/screens/my_connections_screen.dart';
import 'package:sportx_app/features/connections/presentation/screens/connection_requests_screen.dart';
import 'package:sportx_app/features/home/presentation/screens/discover_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/view_profile_screen.dart';
import 'package:sportx_app/features/social/presentation/screens/post_detail_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_login_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/platform_reports_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/manage_users_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/user_detail_verify_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/pending_approvals_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/moderation_queue_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/report_detail_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/compose_notification_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/opp_approval_queue_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/opp_review_detail_screen.dart';
import 'package:sportx_app/features/admin/presentation/screens/notification_targeting_screen.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';

/// Maps a user role to the first onboarding screen they must complete.
/// Returns null for roles with no onboarding (e.g. admin).
String? _onboardingRouteFor(String? role) {
  switch (role) {
    case 'athlete':
      return '/onboarding-1';
    case 'coach':
      return '/coach-onboarding';
    case 'academy':
      return '/academy-onboarding';
    case 'organizer':
      return '/organizer-onboarding';
    case 'sponsor':
      return '/sponsor-onboarding';
    default:
      return null;
  }
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != next.status || previous?.needsOnboarding != next.needsOnboarding) {
        notifyListeners();
      }
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final authState = ref.read(authProvider);
      final status = authState.status;
      const authScreens = ['/splash', '/role-selection', '/sign-up', '/login'];
      const onboardingScreens = [
        '/onboarding-1', '/onboarding-2',
        '/coach-onboarding', '/academy-onboarding',
        '/organizer-onboarding', '/sponsor-onboarding',
      ];

      if (status == AuthStatus.authenticated) {
        final onboardingRoute = _onboardingRouteFor(authState.user?.role);
        // Needs onboarding → force the user through their role onboarding first.
        if (authState.needsOnboarding && onboardingRoute != null) {
          if (onboardingScreens.contains(loc)) {
            return null; // Let them move freely between onboarding steps
          }
          return onboardingRoute; // Otherwise, force them to start onboarding
        }
        // Fully set up → never show auth / onboarding screens.
        if (authScreens.contains(loc) || onboardingScreens.contains(loc)) {
          return '/home';
        }
        return null;
      }

      if (status == AuthStatus.unauthenticated) {
        if (authScreens.contains(loc)) return null;
        return '/role-selection';
      }

      return null; // AuthStatus.initial / loading — let the current screen show.
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/role-selection', builder: (context, state) => const RoleSelectionScreen()),
      GoRoute(path: '/sign-up', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SignUpScreen(role: extra?['role'] as String? ?? 'athlete');
      }),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/onboarding-1', builder: (context, state) => const OnboardingSportAgeScreen()),
      GoRoute(path: '/onboarding-2', builder: (context, state) => const OnboardingSkillLocationScreen()),
      GoRoute(path: '/academies', builder: (context, state) => const AcademyDirectoryScreen()),
      GoRoute(path: '/academy-detail/:id', builder: (context, state) => AcademyDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/coaches', builder: (context, state) => const CoachDirectoryScreen()),
      GoRoute(path: '/coach-detail/:id', builder: (context, state) => CoachDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/trials', builder: (context, state) => const TrialDirectoryScreen()),
      GoRoute(path: '/trial-detail/:id', builder: (context, state) => TrialDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/tournaments', builder: (context, state) => const TournamentDirectoryScreen()),
      GoRoute(path: '/tournament-detail/:id', builder: (context, state) => TournamentDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/enquire/:title', builder: (context, state) => EnquireScreen(title: state.pathParameters['title']!)),
      GoRoute(path: '/trial-registration/:id', builder: (context, state) => TrialRegistrationScreen(trialId: state.pathParameters['id']!)),
      GoRoute(path: '/tournament-registration/:id', builder: (context, state) => TournamentRegistrationScreen(tournamentId: state.pathParameters['id']!)),
      GoRoute(path: '/registration-confirmation', builder: (context, state) => const RegistrationConfirmationScreen()),
      GoRoute(path: '/coach-dashboard', builder: (context, state) => const CoachDashboardScreen()),
      GoRoute(path: '/academy-dashboard', builder: (context, state) => const AcademyDashboardScreen()),
      GoRoute(path: '/organizer-dashboard', builder: (context, state) => const OrganizerDashboardScreen()),
      GoRoute(path: '/enquiry-inbox', builder: (context, state) => const EnquiryInboxScreen()),
      GoRoute(path: '/enquiry-detail', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EnquiryDetailScreen(id: extra?['id'] as String? ?? '');
      }),
      GoRoute(path: '/post-trial', builder: (context, state) => const TrialPostingScreen()),
      GoRoute(path: '/post-tournament', builder: (context, state) => const TournamentPostingScreen()),
      GoRoute(path: '/edit-coach-profile', builder: (context, state) => const CoachProfilePostingScreen()),
      GoRoute(path: '/edit-academy-profile', builder: (context, state) => const AcademyProfilePostingScreen()),
      GoRoute(path: '/organizer-onboarding', builder: (context, state) => const OrganizerOnboardingScreen()),
      GoRoute(path: '/sponsor-onboarding', builder: (context, state) => const SponsorOnboardingScreen()),
      GoRoute(path: '/sponsor-posting', builder: (context, state) => const SponsorshipPostingScreen()),
      GoRoute(path: '/sponsor-pitch/:id', builder: (context, state) => SponsorPitchScreen(sponsorId: state.pathParameters['id']!)),
      GoRoute(path: '/registrant-detail', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RegistrantDetailScreen(registrationId: extra?['id'] as String? ?? '');
      }),
      GoRoute(path: '/coach-onboarding', builder: (context, state) => const CoachOnboardingScreen()),
      GoRoute(path: '/academy-onboarding', builder: (context, state) => const AcademyOnboardingScreen()),
      GoRoute(path: '/registrant-list', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RegistrantListScreen(
          trialId: extra?['id'] as String? ?? '',
          title: extra?['title'] as String? ?? 'Trial',
        );
      }),
      GoRoute(path: '/registration-management', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RegistrationManagementScreen(
          tournamentId: extra?['id'] as String? ?? '',
          title: extra?['title'] as String? ?? 'Tournament',
        );
      }),
      GoRoute(path: '/capacity-management', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CapacityManagementScreen(tournamentId: extra?['id'] as String? ?? '');
      }),
      GoRoute(path: '/results-publishing', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResultsPublishingScreen(
          tournamentId: extra?['id'] as String? ?? '',
          title: extra?['title'] as String? ?? 'Tournament',
        );
      }),
      GoRoute(path: '/results-view', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResultsViewScreen(
          tournamentId: extra?['id'] as String? ?? '',
          title: extra?['title'] as String? ?? 'Tournament',
        );
      }),
      GoRoute(path: '/sponsor-dashboard', builder: (context, state) => const SponsorDashboardScreen()),
      GoRoute(path: '/athlete-discovery', builder: (context, state) => const AthleteDiscoveryScreen()),
      GoRoute(path: '/athlete-profile-view', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AthleteProfileViewScreen(athleteId: extra?['id'] as String? ?? '');
      }),
      GoRoute(path: '/applications-inbox', builder: (context, state) => const ApplicationsInboxScreen()),
      GoRoute(path: '/application-detail', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ApplicationDetailScreen(
          sponsorshipId: extra?['sponsorship_id'] as String? ?? '',
          applicationId: extra?['id'] as String? ?? '',
        );
      }),
      GoRoute(path: '/shortlist', builder: (context, state) => const ShortlistScreen()),
      GoRoute(path: '/my-trials', builder: (context, state) => const MyTrialsManagementScreen()),
      GoRoute(path: '/my-tournaments', builder: (context, state) => const MyTournamentsManagementScreen()),
      GoRoute(path: '/my-sponsorships', builder: (context, state) => const MySponsorshipsManagementScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/help-support', builder: (context, state) => const HelpSupportScreen()),
      GoRoute(path: '/scholarships', builder: (context, state) => const ScholarshipListScreen()),
      GoRoute(path: '/sports-venues', builder: (context, state) => const SportsVenueListScreen()),
      GoRoute(path: '/create-post', builder: (context, state) => const CreatePostScreen()),
      GoRoute(path: '/chat-list', builder: (context, state) => const ChatListScreen()),
      GoRoute(path: '/chat-screen', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ChatScreen(
          chatId: extra?['id'] as String? ?? '',
          chatName: extra?['name'] as String? ?? '',
          chatAvatar: extra?['avatar'] as String? ?? '',
        );
      }),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/add-achievement', builder: (context, state) => const AddAchievementScreen()),
      GoRoute(path: '/media-gallery', builder: (context, state) => const MediaGalleryScreen()),
      GoRoute(path: '/add-credential', builder: (context, state) => const AddCredentialScreen()),
      GoRoute(path: '/edit-facilities', builder: (context, state) => const EditFacilitiesScreen()),
      GoRoute(path: '/showcase-athletes', builder: (context, state) => const ShowcaseAthletesScreen()),
      GoRoute(path: '/sponsor-directory-coach', builder: (context, state) => const SponsorDirectoryCoachScreen()),
      GoRoute(path: '/coach-profile-detail/:id', builder: (context, state) => CoachProfileDetailScreen(coachId: state.pathParameters['id']!)),
      GoRoute(path: '/search-filter', builder: (context, state) => const SearchFilterScreen()),
      GoRoute(path: '/my-connections', builder: (context, state) => const MyConnectionsScreen()),
      GoRoute(path: '/connection-requests', builder: (context, state) => const ConnectionRequestsScreen()),
      GoRoute(path: '/discover', builder: (context, state) => const DiscoverScreen()),
      GoRoute(path: '/view-profile', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ViewProfileScreen(
          type: extra?['type'] as String? ?? 'athlete',
          id: extra?['id'] as String? ?? '',
        );
      }),
      GoRoute(path: '/post-detail/:id', builder: (context, state) => PostDetailScreen(postId: state.pathParameters['id']!)),
      GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/reports', builder: (context, state) => const PlatformReportsScreen()),
      GoRoute(path: '/admin/users', builder: (context, state) => const ManageUsersScreen()),
      GoRoute(path: '/admin/users/:id/verify', builder: (context, state) {
        final user = state.extra as AdminUser?;
        return UserDetailVerifyScreen(user: user ?? AdminUser(id: '', name: '', email: '', role: 'athlete'));
      }),
      GoRoute(path: '/admin/approvals', builder: (context, state) => const PendingApprovalsScreen()),
      GoRoute(path: '/admin/moderation', builder: (context, state) => const ModerationQueueScreen()),
      GoRoute(path: '/admin/reports/:id', builder: (context, state) {
        final report = state.extra as Report?;
        return ReportDetailScreen(report: report ?? Report(id: '', reportedBy: '', reportedByName: '', reason: '', contentType: 'post', contentId: '', createdAt: ''));
      }),
      GoRoute(path: '/admin/notifications/compose', builder: (context, state) => const ComposeNotificationScreen()),
      GoRoute(path: '/admin/opportunities', builder: (context, state) => const OppApprovalQueueScreen()),
      GoRoute(path: '/admin/opportunities/:id', builder: (context, state) {
        final opportunity = state.extra as Opportunity?;
        return OppReviewDetailScreen(opportunity: opportunity ?? Opportunity(id: '', title: '', sponsorName: '', status: 'pending', createdAt: ''));
      }),
      GoRoute(path: '/admin/notifications/targeting', builder: (context, state) => const NotificationTargetingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/universal-search', builder: (context, state) => const UniversalSearchScreen()),
          GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
          GoRoute(path: '/activity-hub', builder: (context, state) => const ActivityHubScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(context, 1, Icons.search_outlined, Icons.search, 'Search'),
                _buildNavItem(context, 2, Icons.bookmark_outline, Icons.bookmark, 'Saved'),
                _buildNavItem(context, 3, Icons.list_alt_outlined, Icons.list_alt, 'Activity'),
                _buildNavItem(context, 4, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _calculateSelectedIndex(context) == index;
    final color = isSelected ? const Color(0xFF1677ff) : const Color(0xFF6b7280);
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search') || location.startsWith('/universal-search')) return 1;
    if (location.startsWith('/saved')) return 2;
    if (location.startsWith('/activity-hub')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/universal-search'); break;
      case 2: context.go('/saved'); break;
      case 3: context.go('/activity-hub'); break;
      case 4: context.go('/profile'); break;
    }
  }
}
