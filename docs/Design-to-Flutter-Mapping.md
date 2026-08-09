# SportX India — Design-to-Flutter Screen Mapping

Maps each screen in `sportsx/src/screens/` (design prototype) to the equivalent Flutter screen in `sportx_app/lib/`.

---

## Auth Screens (`auth.tsx`)

| Design Screen | Screen ID | Flutter Screen | Status |
|---------------|-----------|----------------|--------|
| SplashScreen | S1 | `splash_screen.dart` | ✅ Implemented |
| LoginScreen | S5 | `login_screen.dart` | ✅ Implemented |
| SignupScreen | S3 | `sign_up_screen.dart` | ✅ Implemented |
| OTPScreen | S4 | `otp_screen.dart` | ✅ Implemented |
| RoleSelectScreen | S2 | `role_selection_screen.dart` | ✅ Implemented |
| ForgotPasswordScreen | — | `login_screen.dart` (forgot link) | ⚠️ Partial |
| ResetPasswordScreen | — | ❌ Not implemented | ❌ Missing |

---

## Athlete Screens (`athlete.tsx`)

| Design Screen | Screen ID | Flutter Screen | Status |
|---------------|-----------|----------------|--------|
| AthleteHomeScreen | — | `home_screen.dart` | ⚠️ Partial (feed missing) |
| CreatePostScreen | — | ❌ Not implemented | ❌ Missing |
| MyProfileAthleteScreen | A4 | `profile_screen.dart` | ⚠️ Partial |
| EditProfileScreen | A5 | ❌ Not implemented | ❌ Missing |
| AddAchievementScreen | — | ❌ Not implemented | ❌ Missing |
| AddTournamentScreen | — | ❌ Not implemented | ❌ Missing |
| TournamentHistoryScreen | — | ❌ Not implemented | ❌ Missing |
| EditStatsScreen | — | ❌ Not implemented | ❌ Missing |
| MediaGalleryScreen | A6 | ❌ Not implemented | ❌ Missing |
| UploadMediaScreen | — | ❌ Not implemented | ❌ Missing |
| EditSocialLinksScreen | — | ❌ Not implemented | ❌ Missing |
| DiscoverScreen | — | `search_screen.dart` | ⚠️ Partial |
| MyConnectionsScreen | — | ❌ Not implemented | ❌ Missing |
| ConnectionRequestsScreen | — | ❌ Not implemented | ❌ Missing |
| ChatListScreen | — | ❌ Not implemented | ❌ Missing |
| ChatScreen | — | ❌ Not implemented | ❌ Missing |
| AcademiesDirectoryScreen | A7 | `academy_directory_screen.dart` | ✅ Implemented |
| AcademyDetailScreen | A8 | `academy_detail_screen.dart` | ✅ Implemented |
| CoachDirectoryScreen | A9 | `coach_directory_screen.dart` | ✅ Implemented |
| CoachDetailScreen | A10 | `coach_detail_screen.dart` | ✅ Implemented |
| TrialDirectoryScreen | A12 | `trial_directory_screen.dart` | ✅ Implemented |
| TrialDetailScreen | A13 | `trial_detail_screen.dart` | ✅ Implemented |
| TournamentDirectoryScreen | A16 | `tournament_directory_screen.dart` | ✅ Implemented |
| TournamentDetailScreen | A17 | `tournament_detail_screen.dart` | ✅ Implemented |
| ScholarshipFeedScreen | A19 | `scholarship_list_screen.dart` | ✅ Implemented |
| ScholarshipDetailScreen | A20 | (uses detail_page_template) | ⚠️ Partial |
| SponsorshipListScreen | A21 | (sponsorships via API) | ⚠️ Partial |
| SponsorshipDetailScreen | A22 | (via sponsorship listing) | ⚠️ Partial |
| SportsVenueDirectoryScreen | AS-47 | `sports_venue_list_screen.dart` | ✅ Implemented |
| SportsVenueDetailScreen | AS-47 | (uses detail_page_template) | ⚠️ Partial |
| SavedItemsScreen | A25 | `saved_screen.dart` | ✅ Implemented |
| EnquiryFormScreen | A11 | `enquire_screen.dart` | ✅ Implemented |
| TrialRegistrationScreen | A14 | `trial_registration_screen.dart` | ✅ Implemented |
| RegistrationConfirmationScreen | A15 | `registration_confirmation_screen.dart` | ✅ Implemented |
| SponsorPitchScreen | A23 | `sponsor_pitch_screen.dart` | ✅ Implemented |
| NotificationsScreen | S9 | `notifications_screen.dart` | ✅ Implemented |
| SettingsScreen | S11 | `settings_screen.dart` | ✅ Implemented |
| FilterPanelScreen | S8 | ❌ Not implemented (inline in search) | ⚠️ Partial |

---

## Coach Screens (`coach.tsx`)

| Design Screen | Flutter Screen | Status |
|---------------|----------------|--------|
| CoachHomeScreen | `coach_dashboard_screen.dart` | ⚠️ Partial |
| CoachProfileScreen | `coach_detail_screen.dart` | ✅ Implemented |
| EditCoachProfileScreen | `coach_profile_posting_screen.dart` | ✅ Implemented |
| AddCredentialScreen | ❌ Not implemented | ❌ Missing |
| EditFacilitiesScreen | ❌ Not implemented | ❌ Missing |
| ShowcaseAthletesScreen | ❌ Not implemented | ❌ Missing |
| AthleteDirectoryCoachScreen | `coach_directory_screen.dart` | ✅ Implemented |
| SponsorDirectoryCoachScreen | ❌ Not implemented | ❌ Missing |
| CoachEnquiryInboxScreen | `enquiry_inbox_screen.dart` | ✅ Implemented |
| CoachEnquiryDetailScreen | `enquiry_detail_screen.dart` | ✅ Implemented |

---

## Sponsor Screens (`sponsor.tsx`)

| Design Screen | Flutter Screen | Status |
|---------------|----------------|--------|
| SponsorHomeScreen | `sponsor_dashboard_screen.dart` | ⚠️ Partial |
| SponsorProfileScreen | `sponsor_dashboard_screen.dart` | ⚠️ Partial |
| EditSponsorProfileScreen | `sponsor_onboarding_screen.dart` | ✅ Implemented |
| MyOpportunitiesScreen | `my_sponsorships_management_screen.dart` | ✅ Implemented |
| PastAssociationsScreen | ❌ Not implemented | ❌ Missing |
| AthleteDirectorySponsorScreen | `athlete_discovery_screen.dart` | ✅ Implemented |
| AcademyDirectorySponsorScreen | `athlete_discovery_screen.dart` (filter) | ⚠️ Partial |
| PostOpportunityScreen | `sponsorship_posting_screen.dart` | ✅ Implemented |
| ListingStatusScreen | `my_sponsorships_management_screen.dart` | ⚠️ Partial |
| ApplicationsInboxScreen | `applications_inbox_screen.dart` | ✅ Implemented |
| ApplicationDetailScreen | `application_detail_screen.dart` | ✅ Implemented |
| ShortlistScreen | `shortlist_screen.dart` | ✅ Implemented |
| AthleteProfileViewScreen | `athlete_profile_view_screen.dart` | ✅ Implemented |

---

## Shared Screens (`shared.tsx`)

| Design Screen | Flutter Screen | Status |
|---------------|----------------|--------|
| ViewProfileScreen | (view-only profile) | ⚠️ Partial |
| PostDetailScreen | ❌ Not implemented | ❌ Missing |
| OpportunitiesListScreen | `scholarship_list_screen.dart` | ✅ Implemented |
| OpportunityDetailScreen | (uses detail_page_template) | ⚠️ Partial |
| ApplyFormScreen | `sponsor_pitch_screen.dart` | ✅ Implemented |
| AppSubmittedScreen | (confirmation inline) | ⚠️ Partial |
| SearchFilterScreen | `search_screen.dart` (inline) | ⚠️ Partial |
| NotificationsListScreen | `notifications_screen.dart` | ✅ Implemented |
| NotificationDetailScreen | (inline expansion) | ⚠️ Partial |
| SettingsScreen | `settings_screen.dart` | ✅ Implemented |
| MediaViewerScreen | ❌ Not implemented | ❌ Missing |

---

## Admin Screens (`admin.tsx`)

| Design Screen | Flutter Screen | Status |
|---------------|----------------|--------|
| AdminDashboardScreen | `admin_dashboard_screen.dart` | ✅ Implemented |
| PlatformReportsScreen | ❌ Not implemented | ❌ Missing |
| ManageUsersScreen | ❌ Not implemented | ❌ Missing |
| UserDetailVerifyScreen | ❌ Not implemented | ❌ Missing |
| PendingApprovalsScreen | ❌ Not implemented | ❌ Missing |
| ModerationQueueScreen | ❌ Not implemented | ❌ Missing |
| ReportDetailScreen | ❌ Not implemented | ❌ Missing |
| ComposeNotificationScreen | ❌ Not implemented | ❌ Missing |
| NotificationTargetingScreen | ❌ Not implemented | ❌ Missing |
| OppApprovalQueueScreen | ❌ Not implemented | ❌ Missing |
| OppReviewDetailScreen | ❌ Not implemented | ❌ Missing |
| AdminLoginScreen | `admin_login_screen.dart` | ✅ Implemented |
| AdminContentPickerScreen | `admin_content_picker_screen.dart` | ✅ Implemented |
| AdminContentListScreen | `admin_content_list_screen.dart` | ✅ Implemented |

---

## Summary

| Category | Total Design Screens | Fully Matched | Partial | Missing |
|----------|---------------------|---------------|---------|---------|
| Auth | 7 | 4 | 1 | 2 |
| Athlete | 35 | 16 | 9 | 10 |
| Coach | 10 | 6 | 1 | 3 |
| Sponsor | 13 | 10 | 3 | 0 |
| Shared | 11 | 5 | 5 | 1 |
| Admin | 14 | 4 | 0 | 10 |
| **Total** | **90** | **45 (50%)** | **19 (21%)** | **26 (29%)** |

---

## Key Gaps to Address

1. **Social/Feed features** — CreatePostScreen, ChatScreen, MyConnectionsScreen, PostDetailScreen
2. **Profile completeness** — EditProfileScreen, MediaGalleryScreen, UploadMediaScreen, AddAchievementScreen
3. **Admin panel** — 10 admin screens not implemented in Flutter
4. **Coach features** — AddCredentialScreen, EditFacilitiesScreen, ShowcaseAthletesScreen
5. **Universal search UI** — SearchFilterScreen, SearchResultsScreen
