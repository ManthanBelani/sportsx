# SportX Flutter App - Role-Based Screen Implementation

## Overview

This document maps each user role to their required screens, organized by:
- **Auth Flow** - Screens for login/registration
- **Onboarding** - Role-specific onboarding flows
- **Dashboard** - Role-specific dashboard
- **Core Features** - Screens specific to that role
- **Shared Screens** - Common screens accessible by that role
- **Settings & Profile** - Profile management

---

## ROLE: ATHLETE

### Design Files Required (10 screens)
| Design File | Flutter Implementation | Route | Status |
|-------------|----------------------|-------|--------|
| `shared/login.html` | `login_screen.dart` | `/login` | ✅ |
| `shared/sign-up.html` | `sign_up_screen.dart` | `/sign-up` | ✅ |
| `shared/otp-verification.html` | `otp_screen.dart` | `/otp` | ✅ |
| `onboarding-sport.html` | `onboarding_sport_age_screen.dart` | `/onboarding-1` | ✅ |
| `onboarding-location.html` | `onboarding_skill_location_screen.dart` | `/onboarding-2` | ✅ |
| `home-dashboard.html` | `home_screen.dart` | `/home` | ✅ |
| `athlete/apply-sponsor.html` | `sponsor_pitch_screen.dart` | `/sponsor-pitch/:id` | ✅ |
| `athlete/enquire-coach.html` | `enquire_screen.dart` | `/enquire/:type/:id/:title` | ✅ |
| `athlete/media-gallery.html` | `media_gallery_screen.dart` | `/media-gallery` | ✅ |
| `athlete/scholarship-detail.html` | `scholarship_detail_screen.dart` | `/scholarship-detail/:id` | ✅ |
| `athlete/scholarship-feed.html` | `scholarship_list_screen.dart` | `/scholarships` | ✅ |
| `athlete/settings.html` | `profile_screen.dart` | `/profile` | ✅ |
| `athlete/sponsorship-detail.html` | — | — | ❌ MISSING |
| `athlete/sponsorship-list.html` | `shortlist_screen.dart` | `/shortlist` | ⚠️ PARTIAL |
| `athlete/tournament-detail.html` | `tournament_detail_screen.dart` | `/tournament-detail/:id` | ✅ |
| `athlete/tournament-registration.html` | `tournament_registration_screen.dart` | `/tournament-registration/:id` | ✅ |
| `profile-view.html` | `profile_screen.dart` | `/profile` | ✅ |
| `profile-edit.html` | `edit_profile_screen.dart` | `/edit-profile` | ✅ |
| `saved-items.html` | `saved_screen.dart` | `/saved` | ✅ |
| `notifications.html` | `notifications_screen.dart` | `/notifications` | ✅ |
| `settings.html` | `settings_screen.dart` | `/settings` | ✅ |
| `help-support.html` | `help_support_screen.dart` | `/help-support` | ✅ |
| `universal-search.html` | `universal_search_screen.dart` | `/universal-search` | ✅ |
| `activity-hub.html` | `activity_hub_screen.dart` | `/activity-hub` | ✅ |
| `trial-detail.html` | `trial_detail_screen.dart` | `/trial-detail/:id` | ✅ |
| `trial-listings.html` | `trial_directory_screen.dart` | `/trials` | ✅ |
| `trial-registration.html` | `trial_registration_screen.dart` | `/trial-registration/:id` | ✅ |
| `registration-confirmation.html` | `registration_confirmation_screen.dart` | `/registration-confirmation` | ✅ |
| `coach-detail.html` | `coach_detail_screen.dart` | `/coach-detail/:id` | ✅ |
| `coach-directory.html` | `coach_directory_screen.dart` | `/coaches` | ✅ |
| `academy-detail.html` | `academy_detail_screen.dart` | `/academy-detail/:id` | ✅ |
| `academy-directory.html` | `academy_directory_screen.dart` | `/academies` | ✅ |
| `search-results.html` | `universal_search_screen.dart` | `/universal-search` | ✅ |

### Athlete Summary
| Category | Required | Implemented | Missing |
|----------|----------|-------------|---------|
| Auth | 4 | 4 | 0 |
| Onboarding | 2 | 2 | 0 |
| Dashboard/Home | 1 | 1 | 0 |
| Core Features | 10 | 8 | 2 |
| Shared | 11 | 11 | 0 |
| **TOTAL** | **28** | **26** | **2** |

### Athlete Missing Screens
1. `athlete/sponsorship-detail.html` - View individual sponsorship details
2. `athlete/sponsorship-list.html` - List of athlete's sponsorship applications (partial: `shortlist_screen.dart` only covers shortlist, not full sponsorship list)

---

## ROLE: COACH

### Design Files Required (7 screens)
| Design File | Flutter Implementation | Route | Status |
|-------------|----------------------|-------|--------|
| `shared/login.html` | `login_screen.dart` | `/login` | ✅ |
| `shared/sign-up.html` | `sign_up_screen.dart` | `/sign-up` | ✅ |
| `shared/otp-verification.html` | `otp_screen.dart` | `/otp` | ✅ |
| `coach/coach-onboarding.html` | `coach_onboarding_screen.dart` | `/coach-onboarding` | ✅ |
| `coach/coach-dashboard.html` | `coach_dashboard_screen.dart` | `/coach-dashboard` | ✅ |
| `coach/coach-profile-edit.html` | `coach_profile_edit_screen.dart` | `/coach-profile-edit` | ✅ |
| `coach/enquiry-inbox.html` | `coach_enquiry_inbox_screen.dart` | `/coach-enquiry-inbox` | ✅ |
| `coach/enquiry-detail.html` | `coach_enquiry_detail_screen.dart` | `/coach-enquiry-detail` | ✅ |
| `coach-detail.html` | `coach_detail_screen.dart` | `/coach-detail/:id` | ✅ |
| `coach-directory.html` | `coach_directory_screen.dart` | `/coaches` | ✅ |
| `profile-view.html` | `view_profile_screen.dart` | `/view-profile` | ✅ |
| `profile-edit.html` | `coach_profile_edit_screen.dart` | `/coach-profile-edit` | ✅ |
| `notifications.html` | `notifications_screen.dart` | `/notifications` | ✅ |
| `settings.html` | `settings_screen.dart` | `/settings` | ✅ |
| `help-support.html` | `help_support_screen.dart` | `/help-support` | ✅ |
| `universal-search.html` | `universal_search_screen.dart` | `/universal-search` | ✅ |
| `activity-hub.html` | `activity_hub_screen.dart` | `/activity-hub` | ✅ |
| `saved-items.html` | `saved_screen.dart` | `/saved` | ✅ |
| `athlete/enquire-coach.html` | `enquire_screen.dart` | `/enquire/:type/:id/:title` | ✅ |
| `athlete/media-gallery.html` | `media_gallery_screen.dart` | `/media-gallery` | ✅ |
| `settings.html` | `settings_screen.dart` | `/settings` | ✅ |

### Coach Additional Screens (not in design but implemented)
| Screen | Route | Notes |
|--------|-------|-------|
| `coach_profile_posting_screen.dart` | `/edit-coach-profile` | Coach profile creation |
| `add_credential_screen.dart` | `/add-credential` | Add credentials |
| `edit_facilities_screen.dart` | `/edit-facilities` | Edit facilities |
| `showcase_athletes_screen.dart` | `/showcase-athletes` | Showcase athletes |
| `sponsor_directory_screen.dart` | `/sponsor-directory-coach` | Sponsor directory |
| `coach_profile_detail_screen.dart` | `/coach-profile-detail/:id` | Coach profile detail |
| `enquiry_inbox_screen.dart` | `/enquiry-inbox` | Academy/Organizer enquiry inbox |

### Coach Summary
| Category | Required | Implemented | Missing |
|----------|----------|-------------|---------|
| Auth | 3 | 3 | 0 |
| Onboarding | 1 | 1 | 0 |
| Dashboard | 1 | 1 | 0 |
| Core Features | 7 | 7 | 0 |
| Shared | 10 | 10 | 0 |
| **TOTAL** | **22** | **22** | **0** |

---

## ROLE: ACADEMY

### Design Files Required (9 screens)
| Design File | Flutter Implementation | Route | Status |
|-------------|----------------------|-------|--------|
| `shared/login.html` | `login_screen.dart` | `/login` | ✅ |
| `shared/sign-up.html` | `sign_up_screen.dart` | `/sign-up` | ✅ |
| `shared/otp-verification.html` | `otp_screen.dart` | `/otp` | ✅ |
| `academy/academy-onboarding.html` | `academy_onboarding_screen.dart` | `/academy-onboarding` | ✅ |
| `academy/academy-dashboard.html` | `academy_dashboard_screen.dart` | `/academy-dashboard` | ✅ |
| `academy/academy-listing-edit.html` | `academy_profile_posting_screen.dart` | `/edit-academy-profile` | ✅ |
| `academy/my-trials.html` | `my_trials_management_screen.dart` | `/my-trials` | ✅ |
| `academy/registrant-detail.html` | `registrant_detail_screen.dart` | `/registrant-detail` | ✅ |
| `academy/registrant-list.html` | `registrant_list_screen.dart` | `/registrant-list` | ✅ |
| `academy/trial-posting-form.html` | `trial_posting_screen.dart` | `/post-trial` | ✅ |
| `academy-detail.html` | `academy_detail_screen.dart` | `/academy-detail/:id` | ✅ |
| `academy-directory.html` | `academy_directory_screen.dart` | `/academies` | ✅ |
| `profile-view.html` | `view_profile_screen.dart` | `/view-profile` | ✅ |
| `profile-edit.html` | `academy_profile_posting_screen.dart` | `/edit-academy-profile` | ✅ |
| `notifications.html` | `notifications_screen.dart` | `/notifications` | ✅ |
| `settings.html` | `settings_screen.dart` | `/settings` | ✅ |
| `help-support.html` | `help_support_screen.dart` | `/help-support` | ✅ |
| `universal-search.html` | `universal_search_screen.dart` | `/universal-search` | ✅ |
| `activity-hub.html` | `activity_hub_screen.dart` | `/activity-hub` | ✅ |
| `saved-items.html` | `saved_screen.dart` | `/saved` | ✅ |
| `athlete/enquire-coach.html` | `enquire_screen.dart` | `/enquire/:type/:id/:title` | ✅ |
| `enquiry-inbox.html` | `enquiry_inbox_screen.dart` | `/enquiry-inbox` | ✅ |
| `enquiry-detail.html` | `enquiry_detail_screen.dart` | `/enquiry-detail` | ✅ |

### Academy Summary
| Category | Required | Implemented | Missing |
|----------|----------|-------------|---------|
| Auth | 3 | 3 | 0 |
| Onboarding | 1 | 1 | 0 |
| Dashboard | 1 | 1 | 0 |
| Core Features | 9 | 9 | 0 |
| Shared | 12 | 12 | 0 |
| **TOTAL** | **26** | **26** | **0** |

---

## ROLE: ORGANIZER

### Design Files Required (7 screens)
| Design File | Flutter Implementation | Route | Status |
|-------------|----------------------|-------|--------|
| `shared/login.html` | `login_screen.dart` | `/login` | ✅ |
| `shared/sign-up.html` | `sign_up_screen.dart` | `/sign-up` | ✅ |
| `shared/otp-verification.html` | `otp_screen.dart` | `/otp` | ✅ |
| `organizer/organizer-onboarding.html` | `organizer_onboarding_screen.dart` | `/organizer-onboarding` | ✅ |
| `organizer/organizer-dashboard.html` | `organizer_dashboard_screen.dart` | `/organizer-dashboard` | ✅ |
| `organizer/tournament-create.html` | `tournament_posting_screen.dart` | `/post-tournament` | ✅ |
| `organizer/my-tournaments.html` | `my_tournaments_management_screen.dart` | `/my-tournaments` | ✅ |
| `organizer/registration-management.html` | `registration_management_screen.dart` | `/registration-management` | ✅ |
| `organizer/capacity-management.html` | `capacity_management_screen.dart` | `/capacity-management` | ✅ |
| `organizer/results-publishing.html` | `results_publishing_screen.dart` | `/results-publishing` | ✅ |
| `tournament-calendar.html` | — | — | ❌ MISSING |
| `profile-view.html` | `view_profile_screen.dart` | `/view-profile` | ✅ |
| `profile-edit.html` | `tournament_posting_screen.dart` | `/post-tournament` | ⚠️ PARTIAL |
| `notifications.html` | `notifications_screen.dart` | `/notifications` | ✅ |
| `settings.html` | `settings_screen.dart` | `/settings` | ✅ |
| `help-support.html` | `help_support_screen.dart` | `/help-support` | ✅ |
| `universal-search.html` | `universal_search_screen.dart` | `/universal-search` | ✅ |
| `activity-hub.html` | `activity_hub_screen.dart` | `/activity-hub` | ✅ |
| `saved-items.html` | `saved_screen.dart` | `/saved` | ✅ |
| `tournament-detail.html` | `tournament_detail_screen.dart` | `/tournament-detail/:id` | ✅ |
| `athlete/enquire-coach.html` | `enquire_screen.dart` | `/enquire/:type/:id/:title` | ✅ |
| `enquiry-inbox.html` | `enquiry_inbox_screen.dart` | `/enquiry-inbox` | ✅ |
| `enquiry-detail.html` | `enquiry_detail_screen.dart` | `/enquiry-detail` | ✅ |

### Organizer Additional Screens
| Screen | Route | Notes |
|--------|-------|-------|
| `results_view_screen.dart` | `/results-view` | View published results |

### Organizer Summary
| Category | Required | Implemented | Missing |
|----------|----------|-------------|---------|
| Auth | 3 | 3 | 0 |
| Onboarding | 1 | 1 | 0 |
| Dashboard | 1 | 1 | 0 |
| Core Features | 8 | 7 | 1 |
| Shared | 11 | 11 | 0 |
| **TOTAL** | **24** | **23** | **1** |

### Organizer Missing Screens
1. `tournament-calendar.html` - Calendar view of tournaments

---

## ROLE: SPONSOR

### Design Files Required (7 screens)
| Design File | Flutter Implementation | Route | Status |
|-------------|----------------------|-------|--------|
| `shared/login.html` | `login_screen.dart` | `/login` | ✅ |
| `shared/sign-up.html` | `sign_up_screen.dart` | `/sign-up` | ✅ |
| `shared/otp-verification.html` | `otp_screen.dart` | `/otp` | ✅ |
| `sponsor/sponsor-onboarding.html` | `sponsor_onboarding_screen.dart` | `/sponsor-onboarding` | ✅ |
| `sponsor/sponsor-dashboard.html` | `sponsor_dashboard_screen.dart` | `/sponsor-dashboard` | ✅ |
| `sponsor/sponsorship-create.html` | `sponsorship_posting_screen.dart` | `/sponsor-posting` | ✅ |
| `sponsor/applications-inbox.html` | `applications_inbox_screen.dart` | `/applications-inbox` | ✅ |
| `sponsor/application-detail.html` | `application_detail_screen.dart` | `/application-detail` | ✅ |
| `sponsor/athlete-discovery.html` | `athlete_discovery_screen.dart` | `/athlete-discovery` | ✅ |
| `sponsor/athlete-profile-view.html` | `athlete_profile_view_screen.dart` | `/athlete-profile-view` | ✅ |
| `profile-view.html` | `view_profile_screen.dart` | `/view-profile` | ✅ |
| `profile-edit.html` | `sponsor_onboarding_screen.dart` | `/sponsor-onboarding` | ⚠️ PARTIAL |
| `notifications.html` | `notifications_screen.dart` | `/notifications` | ✅ |
| `settings.html` | `settings_screen.dart` | `/settings` | ✅ |
| `help-support.html` | `help_support_screen.dart` | `/help-support` | ✅ |
| `universal-search.html` | `universal_search_screen.dart` | `/universal-search` | ✅ |
| `activity-hub.html` | `activity_hub_screen.dart` | `/activity-hub` | ✅ |
| `saved-items.html` | `saved_screen.dart` | `/saved` | ✅ |
| `athlete/apply-sponsor.html` | `sponsor_pitch_screen.dart` | `/sponsor-pitch/:id` | ✅ |

### Sponsor Additional Screens
| Screen | Route | Notes |
|--------|-------|-------|
| `shortlist_screen.dart` | `/shortlist` | Shortlisted athletes |
| `my_sponsorships_management_screen.dart` | `/my-sponsorships` | Manage sponsorships |

### Sponsor Summary
| Category | Required | Implemented | Missing |
|----------|----------|-------------|---------|
| Auth | 3 | 3 | 0 |
| Onboarding | 1 | 1 | 0 |
| Dashboard | 1 | 1 | 0 |
| Core Features | 7 | 7 | 0 |
| Shared | 8 | 8 | 0 |
| **TOTAL** | **20** | **20** | **0** |

---

## ROLE: ADMIN

### Design Files Required (10 screens)
| Design File | Flutter Implementation | Route | Status |
|-------------|----------------------|-------|--------|
| `shared/login.html` | `admin_login_screen.dart` | `/admin/login` | ✅ |
| `admin/admin-dashboard.html` | `admin_dashboard_screen.dart` | `/admin/dashboard` | ✅ |
| `admin/admin-user-management.html` | `manage_users_screen.dart` | `/admin/users` | ✅ |
| `admin/admin-report-center.html` | `platform_reports_screen.dart` | `/admin/reports` | ✅ |
| `admin/admin-sponsor-verification.html` | `user_detail_verify_screen.dart` | `/admin/users/:id/verify` | ✅ |
| `admin/admin-content-flagging.html` | `moderation_queue_screen.dart` | `/admin/moderation` | ⚠️ PARTIAL |
| `admin/admin-listing-moderation.html` | `pending_approvals_screen.dart` | `/admin/approvals` | ⚠️ PARTIAL |
| `admin/admin-analytics.html` | — | — | ❌ MISSING |
| `admin/admin-notification-templates.html` | `compose_notification_screen.dart` | `/admin/notifications/compose` | ⚠️ PARTIAL |
| `admin/admin-sport-category-management.html` | `notification_targeting_screen.dart` | `/admin/notifications/targeting` | ⚠️ PARTIAL |
| `admin/admin-system-settings.html` | — | — | ❌ MISSING |

### Admin Additional Screens
| Screen | Route | Notes |
|--------|-------|-------|
| `opp_approval_queue_screen.dart` | `/admin/opportunities` | Opportunity approval |
| `opp_review_detail_screen.dart` | `/admin/opportunities/:id` | Opportunity review |
| `report_detail_screen.dart` | `/admin/reports/:id` | Report detail |
| `admin_content_picker_screen.dart` | — | Content picker |
| `admin_content_list_screen.dart` | — | Content list |

### Admin Summary
| Category | Required | Implemented | Missing |
|----------|----------|-------------|---------|
| Auth | 1 | 1 | 0 |
| Dashboard | 1 | 1 | 0 |
| Core Features | 10 | 4 | 6 |
| **TOTAL** | **12** | **6** | **6** |

### Admin Missing Screens
1. `admin/admin-analytics.html` - Analytics dashboard
2. `admin/admin-system-settings.html` - System settings
3. `admin/admin-content-flagging.html` - Content flagging (partially covered by `moderation_queue_screen.dart`)
4. `admin/admin-listing-moderation.html` - Listing moderation (partially covered by `pending_approvals_screen.dart`)
5. `admin/admin-notification-templates.html` - Notification templates (partially covered by `compose_notification_screen.dart`)
6. `admin/admin-sport-category-management.html` - Sport category management (partially covered by `notification_targeting_screen.dart`)

---

## SHARED / COMMON SCREENS

These screens are accessible across all roles:

| Screen | Route | Implemented | Notes |
|--------|-------|-------------|-------|
| Splash | `/splash` | ✅ | `splash_screen.dart` |
| Role Selection | `/role-selection` | ✅ | `role_selection_screen.dart` |
| Home | `/home` | ✅ | `home_screen.dart` |
| Universal Search | `/universal-search` | ✅ | `universal_search_screen.dart` |
| Search Filter | `/search-filter` | ✅ | `search_filter_screen.dart` |
| Discover | `/discover` | ✅ | `discover_screen.dart` |
| Saved Items | `/saved` | ✅ | `saved_screen.dart` |
| Activity Hub | `/activity-hub` | ✅ | `activity_hub_screen.dart` |
| Notifications | `/notifications` | ✅ | `notifications_screen.dart` |
| Settings | `/settings` | ✅ | `settings_screen.dart` |
| Help & Support | `/help-support` | ✅ | `help_support_screen.dart` |
| Chat List | `/chat-list` | ✅ | `chat_list_screen.dart` |
| Chat Screen | `/chat-screen` | ✅ | `chat_screen.dart` |
| Connections | `/my-connections` | ✅ | `my_connections_screen.dart` |
| Connection Requests | `/connection-requests` | ✅ | `connection_requests_screen.dart` |
| View Profile | `/view-profile` | ✅ | `view_profile_screen.dart` |
| Create Post | `/create-post` | ✅ | `create_post_screen.dart` |
| Post Detail | `/post-detail/:id` | ✅ | `post_detail_screen.dart` |
| Sports Venues | `/sports-venues` | ✅ | `sports_venue_list_screen.dart` |
| Sports Venue Detail | `/sports-venue-detail/:id` | ✅ | `sports_venue_detail_screen.dart` |

---

## COMPLETION SUMMARY BY ROLE

| Role | Screens Required | Implemented | Missing | Completion |
|------|-----------------|-------------|---------|------------|
| **Athlete** | 28 | 26 | 2 | 93% |
| **Coach** | 22 | 22 | 0 | 100% |
| **Academy** | 26 | 26 | 0 | 100% |
| **Organizer** | 24 | 23 | 1 | 96% |
| **Sponsor** | 20 | 20 | 0 | 100% |
| **Admin** | 12 | 6 | 6 | 50% |

### Overall Statistics
- **Total Unique Routes in App**: 70+
- **Fully Complete Roles**: Coach, Academy, Sponsor (100%)
- **Nearly Complete**: Athlete (93%), Organizer (96%)
- **Needs Attention**: Admin (50%)

---

## PRIORITY SCREENS TO IMPLEMENT

### High Priority
1. **Admin Analytics** (`admin/admin-analytics.html`) - Admin dashboard analytics
2. **Admin System Settings** (`admin/admin-system-settings.html`) - Platform settings
3. **Athlete Sponsorship Detail** (`athlete/sponsorship-detail.html`) - View sponsorship details
4. **Athlete Sponsorship List** (`athlete/sponsorship-list.html`) - List sponsorships

### Medium Priority
5. **Tournament Calendar** (`tournament-calendar.html`) - Calendar view
6. **Content Flagging** - Full implementation for admin moderation
7. **Listing Moderation** - Full implementation for admin approvals
8. **Notification Templates** - Full admin notification management
9. **Sport Category Management** - Full admin category management

---

## APP NAVIGATION STRUCTURE

```
App Entry
    │
    ├── Splash Screen (/splash)
    │
    ├── Unauthenticated Routes
    │   ├── Role Selection (/role-selection)
    │   ├── Sign Up (/sign-up)
    │   ├── Login (/login)
    │   └── OTP (/otp)
    │
    ├── Onboarding (role-based)
    │   ├── Athlete: /onboarding-1 → /onboarding-2
    │   ├── Coach: /coach-onboarding
    │   ├── Academy: /academy-onboarding
    │   ├── Organizer: /organizer-onboarding
    │   └── Sponsor: /sponsor-onboarding
    │
    ├── Main App Shell (bottom nav)
    │   ├── Home (/home)
    │   ├── Search (/universal-search)
    │   ├── Saved (/saved)
    │   ├── Activity (/activity-hub)
    │   └── Profile (/profile or /dashboard)
    │
    ├── Role Dashboards
    │   ├── Coach: /coach-dashboard
    │   ├── Academy: /academy-dashboard
    │   ├── Organizer: /organizer-dashboard
    │   ├── Sponsor: /sponsor-dashboard
    │   └── Admin: /admin/dashboard
    │
    └── Feature Screens (role-specific)
        ├── Directory screens (academies, coaches, trials, tournaments)
        ├── Detail screens
        ├── Registration screens
        ├── Management screens
        └── Settings & Profile
```

---

## FILES REFERENCE

### Flutter App Structure
```
sportx_app/lib/
├── main.dart
├── core/
│   ├── router.dart (70+ routes)
│   ├── config/
│   └── utils/
├── features/
│   ├── academy/presentation/screens/ (9 screens)
│   ├── admin/presentation/screens/ (14 screens)
│   ├── athlete/presentation/screens/ (4 screens)
│   ├── auth/presentation/screens/ (5 screens)
│   ├── chat/presentation/screens/ (2 screens)
│   ├── coach/presentation/screens/ (10 screens)
│   ├── connections/presentation/screens/ (2 screens)
│   ├── home/presentation/screens/ (3 screens)
│   ├── notifications/presentation/screens/ (1 screen)
│   ├── onboarding/presentation/screens/ (2 screens)
│   ├── organizer/presentation/screens/ (7 screens)
│   ├── saved/presentation/screens/ (1 screen)
│   ├── scholarship/presentation/screens/ (2 screens)
│   ├── search/presentation/screens/ (2 screens)
│   ├── settings/presentation/screens/ (2 screens)
│   ├── social/presentation/screens/ (2 screens)
│   ├── sponsor/presentation/screens/ (8 screens)
│   ├── sports_venue/presentation/screens/ (2 screens)
│   ├── tournament/presentation/screens/ (3 screens)
│   └── trial/presentation/screens/ (3 screens)
├── shared/presentation/screens/ (9 screens)
└── theme/
```
