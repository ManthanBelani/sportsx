# SportX India — Design-to-Flutter Screen Mapping

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

Maps each design screen to the equivalent Flutter screen in `sportx_app/lib/`.

> **⚠️ [SUPERSEDED — see Backend-Feature-Delta.md].** The old mapping below referenced `sportsx/src/screens/` (TypeScript prototype, **90 screens incl. Sponsor**). The v3 source of truth is `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md` (**129 screens, 6 roles; sponsor removed**), with new modules for feed/posts, follow/connect, chat, leaderboard, opportunities, programs, facilities, verification and guardian consent. **§v3 (below) is authoritative**; old tables are kept for history.

---

## v3 mapping (authoritative) — new screen IDs → Flutter

> Target files use `sportx_app/lib/features/<module>/presentation/screens/`. New modules per `Mobile-Architecture.md` §6. Status: ✅ exists · ⚠️ partial · 🆕 to build.

| New screen | Purpose | Target Flutter file | Status |
|---|---|---|---|
| A.1 Splash | splash | `auth/.../splash_screen.dart` | ✅ |
| A.2 Role Selection | 5 roles | `auth/.../role_selection_screen.dart` | ⚠️ (remove Sponsor card) |
| A.3 Sign Up | phone/email | `auth/.../sign_up_screen.dart` | ⚠️ (add OTP channel) |
| A.4 OTP Verification | OTP + resend | `auth/.../otp_screen.dart` | 🆕 (wire `/auth/send-otp`,`/verify-otp`,`/resend-otp`) |
| A.5 Login | password/OTP | `auth/.../login_screen.dart` | ⚠️ |
| A.6 Forgot/Reset | OTP reset | `auth/.../forgot_password_screen.dart` | 🆕 |
| A.7 Language · A.8 Permissions | locale/permissions | `settings/...`, `onboarding/...` | 🆕 |
| A.9 Guardian Consent | minors | `guardian/.../guardian_consent_screen.dart` | 🆕 |
| A.10 Verification Request | blue check | `verification/.../verification_screen.dart` | 🆕 |
| S.1 Home shell | role dashboard | `home/.../home_screen.dart` | ⚠️ (call `GET /me/home`) |
| S.2/S.3 Explore + category list | discovery | `directory/.../directory_list_screen.dart` + `GET /explore` | ⚠️ |
| S.4 Filter & Sort | filters | `search/.../search_filter_screen.dart` | ⚠️ |
| S.5 Universal Search | search | `search/.../search_screen.dart` | ⚠️ (+athletes group) |
| S.6/S.7 Leaderboard + Info | ranked list | `leaderboard/.../leaderboard_screen.dart` | 🆕 |
| S.8 Create Launcher | action grid | `feed/.../create_launcher_screen.dart` | 🆕 |
| S.9 Create Post | post compose | `feed/.../create_post_screen.dart` | 🆕 |
| S.10 Upload Media · S.11 Achievement | media/achievements | `profile/...`, `profile/.../add_achievement_screen.dart` | 🆕 |
| S.12 Network (P1) · S.13/S.14 Groups (P2) | community | `network/.../network_screen.dart` | 🆕 |
| S.15 More / account hub | account | `settings/.../more_screen.dart` | 🆕 |
| S.16 Notifications | activity | `notifications/.../notifications_screen.dart` | ✅/⚠️ (tabs) |
| S.17/S.18 Inbox + Chat | messaging | `messaging/.../conversations_screen.dart`, `chat_screen.dart` | 🆕 |
| S.19 Connections | network mgmt | `network/.../connections_screen.dart` | 🆕 |
| S.20 Saved | bookmarks | `saved/.../saved_screen.dart` | ✅/⚠️ |
| S.21 My Activity | own feed | `activity/.../activity_hub_screen.dart` | ✅ |
| S.22–S.26 Settings/Safety/Help/About/Report | settings+safety | `settings/...`, `reports/.../report_sheet.dart` | 🆕/⚠️ |
| S.27 Post Detail · S.28 Media Viewer | post/media | `feed/.../post_detail_screen.dart`, `.../media_viewer_screen.dart` | 🆕 |
| S.29 Logout · S.30 Share/Deep link | share | `settings/...`, `share/.../share_sheet.dart` | 🆕 |
| D.1–D.5 Athlete/Coach/Academy/Organizer/Scout profiles | profiles | `directory/.../detail_page_template.dart` + per-role | ⚠️ partial (Organizer/Scout new) |
| D.6–D.8 Event detail/register/confirm | events | `trials/...`, `tournaments/...` | ✅/⚠️ |
| D.9/D.10 Opportunity detail/apply | opportunities | `opportunities/.../opportunity_detail_screen.dart`, `apply_screen.dart` | 🆕 |
| D.11/D.12 Program detail/enquiry | programs | `programs/.../program_detail_screen.dart`, `enquiry_screen.dart` | 🆕 |
| D.13 Facility detail | facilities | `facilities/.../facility_detail_screen.dart` | 🆕 (some via `sports_venue`) |
| D.14/D.15 Reviews (P1) | reviews | `reviews/...` | 🅿️ |
| D.16 Map (P2) · D.17 Team page (P2) | parked | — | ⏸️ |
| AT.1–AT.10 Athlete screens | home/onboarding/profile/opps/regs/guardian | `athlete/...`, `onboarding/...`, `opportunities/...` | ⚠️/🆕 |
| CO.1–CO.8 Coach screens | onboarding/dashboard/programs/events | `coach/...`, `programs/...` | ⚠️/🆕 |
| AC.1–AC.12 Academy screens | onboarding/dashboard/facilities/programs/events/opportunities/athletes | `academy/...`, `facilities/...`, `programs/...` | ⚠️/🆕 |
| OR.1–OR.17 Organizer screens | onboarding/dashboard/events/registrations/venues | `organizer/...`, `facilities/...` | ⚠️/🆕 |
| SC.1–SC.13 Scout screens | onboarding/dashboard/discover/shortlist/observations/opportunities | `scout/...` | 🆕 (was `talent_scout`) |
| AD.1–AD.12 Admin (web) | admin dashboard/users/verification/moderation/master/leaderboard/broadcast | `admin/...` | ⚠️/🆕 |
| ~~Sponsor (SP1–SP9)~~ | — | — | ❌ **REMOVED** |

**Key new build areas (v3):** social feed + posts, follow/connect + messaging, leaderboard, unified opportunities, programs, facilities, verification, guardian consent, and role-aware dashboards via `GET /me/home`.

---

## [SUPERSEDED] old mapping (pre-v3)

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

## Sponsor Screens (`sponsor.tsx`) — **[SUPERSEDED — see Backend-Feature-Delta.md §4]**

> Sponsor role **REMOVED**. Sponsorship is now an Opportunity type (`D.9`/`D.10`/`AT.8`). Table retained for history.

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

## [SUPERSEDED] Summary (pre-v3, 90 screens incl. Sponsor)

| Category | Total Design Screens | Fully Matched | Partial | Missing |
|----------|---------------------|---------------|---------|---------|
| Auth | 7 | 4 | 1 | 2 |
| Athlete | 35 | 16 | 9 | 10 |
| Coach | 10 | 6 | 1 | 3 |
| Sponsor | 13 | 10 | 3 | 0 — **[REMOVED]** |
| Shared | 11 | 5 | 5 | 1 |
| Admin | 14 | 4 | 0 | 10 |
| **Total (old)** | **90** | **45 (50%)** | **19 (21%)** | **26 (29%)** |

**New design (v3):** **129 screens** (`SCREEN_INVENTORY.md`), 6 roles, sponsor removed; see §v3 mapping above for the authoritative screen→Flutter view.

---

## Key Gaps to Address

1. **Social/Feed features** — CreatePostScreen, ChatScreen, MyConnectionsScreen, PostDetailScreen
2. **Profile completeness** — EditProfileScreen, MediaGalleryScreen, UploadMediaScreen, AddAchievementScreen
3. **Admin panel** — 10 admin screens not implemented in Flutter
4. **Coach features** — AddCredentialScreen, EditFacilitiesScreen, ShowcaseAthletesScreen
5. **Universal search UI** — SearchFilterScreen, SearchResultsScreen
