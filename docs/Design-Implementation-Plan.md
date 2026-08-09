# SportX India — Design Implementation Plan (v2)

**Date:** 2026-08-09
**Design Source:** `sportsx-design-v1/` (78 HTML screens)
**Target:** Flutter Mobile App + Admin Web Panel
**Architecture Reference:** `docs/Mobile-Architecture.md`, `docs/Admin-Panel-Implementation-Prompt.md`

---

## 1. Overview

This plan outlines how to implement the new mobile and admin panel designs from `sportsx-design-v1/` into the existing SportX India codebase without disrupting the established architecture.

### Design Discrepancies Noted
| Aspect | Existing Docs | New Design (`sportsx-design-v1`) |
|--------|---------------|----------------------------------|
| Font | Poppins | Inter |
| Primary Color | `#2563EB` | `#1677ff` |
| Background | `#FFFFFF` | `#ffffff` |
| Surface | `#F8FAFC` | `#f7f8fa` |

**Resolution:** Use the new design tokens from `sportsx-design-v1/` as the source of truth.

---

## 2. Design Source Analysis

### 2.1 Mobile Screens (63 files)

| Category | Screens | Files |
|----------|---------|-------|
| **Shared/Auth** | Splash, Role Selection, Login, Sign Up, OTP, Onboarding Sport/Location | `shared/`, `splash-screen.html`, `role-selection.html` |
| **Home/Search** | Home Dashboard, Universal Search, Search Results, Filter Panel | `home-dashboard.html`, `universal-search.html`, `search-results.html` |
| **Directory** | Academy Directory/Detail, Coach Directory/Detail | `academy-*.html`, `coach-*.html` |
| **Trials** | Trial Listings, Detail, Registration, Confirmation | `trial-*.html`, `registration-confirmation.html` |
| **Tournaments** | Tournament Calendar | `tournament-calendar.html` |
| **Athlete** | Apply Sponsor, Enquire Coach, Media Gallery, Scholarship, Sponsorship detail/list | `athlete/` |
| **Coach** | Coach Dashboard, Onboarding, Profile Edit, Enquiry Inbox/Detail | `coach/` |
| **Academy** | Academy Dashboard, Listing Edit, Onboarding, My Trials, Registrants | `academy/` |
| **Organizer** | Organizer Dashboard, Capacity Management, My Tournaments, Tournament Create, Registration Management, Results Publishing | `organizer/` |
| **Sponsor** | Sponsor Dashboard, Onboarding, Athlete Discovery, Applications Inbox, Sponsorship Create | `sponsor/` |
| **Profile/Settings** | Profile View/Edit, Settings, Help Support, Notifications | `profile-*.html`, `settings.html`, `help-support.html`, `notifications.html` |
| **Activity** | Activity Hub, Saved Items, Report Listing | `activity-hub.html`, `saved-items.html`, `report-listing.html` |

### 2.2 Admin Screens (11 files)

| Screen | File |
|--------|------|
| Admin Dashboard | `admin/admin-dashboard.html` |
| Analytics | `admin/admin-analytics.html` |
| User Management | `admin/admin-user-management.html` |
| Content Moderation | `admin/admin-listing-moderation.html` |
| Content Flagging | `admin/admin-content-flagging.html` |
| Sponsor Verification | `admin/admin-sponsor-verification.html` |
| Sport Category Management | `admin/admin-sport-category-management.html` |
| Report Center | `admin/admin-report-center.html` |
| Notification Templates | `admin/admin-notification-templates.html` |
| System Settings | `admin/admin-system-settings.html` |

---

## 3. Implementation Strategy

### 3.1 Token Extraction

Extract from `sportsx-design-v1/` CSS variables:

```dart
// Updated colors.dart
class AppColors {
  static const Color primary = Color(0xFF1677ff);      // New accent from design
  static const Color background = Color(0xFFffffff);
  static const Color surface = Color(0xFFf7f8fa);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6b7280);
  static const Color border = Color(0xFFd9dee7);
  static const Color success = Color(0xFF22c55e);
  static const Color error = Color(0xFFef4444);
  static const Color warning = Color(0xFFf59e0b);
}
```

### 3.2 Screen Mapping to Flutter

| Design File | Flutter Screen | Action |
|-------------|----------------|--------|
| `splash-screen.html` | `splash_screen.dart` | Update UI to match design |
| `role-selection.html` | `role_selection_screen.dart` | Update UI to match design |
| `shared/login.html` | `login_screen.dart` | Update UI to match design |
| `shared/sign-up.html` | `sign_up_screen.dart` | Update UI to match design |
| `shared/otp-verification.html` | `otp_screen.dart` | Update UI to match design |
| `onboarding-sport.html` | Sport selection in onboarding | Update |
| `onboarding-location.html` | Location selection in onboarding | Update |
| `home-dashboard.html` | `home_screen.dart` | **Full redesign** |
| `universal-search.html` | `universal_search_screen.dart` | Update |
| `search-results.html` | `search_filter_screen.dart` | Update |
| `shared/filter-panel.html` | `search_filter_screen.dart` | Merge into search |
| `academy-directory.html` | `academy_directory_screen.dart` | Update |
| `academy-detail.html` | `academy_detail_screen.dart` | Update |
| `academy/academy-dashboard.html` | `academy_dashboard_screen.dart` | Update |
| `academy/academy-onboarding.html` | `academy_onboarding_screen.dart` | Update |
| `academy/academy-listing-edit.html` | `academy_profile_posting_screen.dart` | Update |
| `academy/my-trials.html` | `my_trials_management_screen.dart` | Update |
| `academy/registrant-list.html` | `registrant_list_screen.dart` | Update |
| `academy/registrant-detail.html` | `registrant_detail_screen.dart` | Update |
| `academy/trial-posting-form.html` | `trial_posting_screen.dart` | Update |
| `coach-directory.html` | `coach_directory_screen.dart` | Update |
| `coach-detail.html` | `coach_detail_screen.dart` | Update |
| `coach/coach-dashboard.html` | `coach_dashboard_screen.dart` | Update |
| `coach/coach-onboarding.html` | `coach_onboarding_screen.dart` | Update |
| `coach/coach-profile-edit.html` | `coach_profile_posting_screen.dart` | Update |
| `coach/enquiry-inbox.html` | `enquiry_inbox_screen.dart` | Update |
| `coach/enquiry-detail.html` | `enquiry_detail_screen.dart` | Update |
| `trial-listings.html` | `trial_directory_screen.dart` | Update |
| `trial-detail.html` | `trial_detail_screen.dart` | Update |
| `trial-registration.html` | `trial_registration_screen.dart` | Update |
| `registration-confirmation.html` | `registration_confirmation_screen.dart` | Update |
| `tournament-calendar.html` | `tournament_directory_screen.dart` | Update |
| `athlete/apply-sponsor.html` | `sponsor_pitch_screen.dart` | Update |
| `athlete/enquire-coach.html` | `enquire_screen.dart` | Update |
| `athlete/media-gallery.html` | Media upload in profile | Update |
| `athlete/scholarship-feed.html` | `scholarship_list_screen.dart` | Update |
| `athlete/scholarship-detail.html` | Scholarship detail | Update |
| `athlete/sponsorship-list.html` | Sponsorship list | Update |
| `athlete/sponsorship-detail.html` | Sponsorship detail | Update |
| `athlete/settings.html` | `settings_screen.dart` | Update |
| `athlete/tournament-detail.html` | `tournament_detail_screen.dart` | Update |
| `athlete/tournament-registration.html` | `tournament_registration_screen.dart` | Update |
| `organizer/organizer-dashboard.html` | Organizer dashboard | Create/Update |
| `organizer/organizer-onboarding.html` | Organizer onboarding | Create/Update |
| `organizer/my-tournaments.html` | `my_tournaments_management_screen.dart` | Update |
| `organizer/tournament-create.html` | `tournament_posting_screen.dart` | Update |
| `organizer/registration-management.html` | Registration management | Update |
| `organizer/capacity-management.html` | Capacity management | Update |
| `organizer/results-publishing.html` | Results publishing | Update |
| `sponsor/sponsor-dashboard.html` | `sponsor_dashboard_screen.dart` | Update |
| `sponsor/sponsor-onboarding.html` | `sponsor_onboarding_screen.dart` | Update |
| `sponsor/sponsorship-create.html` | `sponsorship_posting_screen.dart` | Update |
| `sponsor/athlete-discovery.html` | `athlete_discovery_screen.dart` | Update |
| `sponsor/applications-inbox.html` | `applications_inbox_screen.dart` | Update |
| `sponsor/application-detail.html` | `application_detail_screen.dart` | Update |
| `sponsor/athlete-profile-view.html` | `athlete_profile_view_screen.dart` | Update |
| `profile-view.html` | `profile_screen.dart` | Update |
| `profile-edit.html` | `edit_profile_screen.dart` | Update |
| `settings.html` | `settings_screen.dart` | Update |
| `help-support.html` | Help/Support | Create |
| `notifications.html` | `notifications_screen.dart` | Update |
| `activity-hub.html` | `activity_hub_screen.dart` | Update |
| `saved-items.html` | `saved_screen.dart` | Update |
| `report-listing.html` | Report modal | Update |

### 3.3 Admin Panel Mapping

| Design File | Admin Blade | Action |
|-------------|-------------|--------|
| `admin/admin-dashboard.html` | `admin/dashboard.blade.php` | **Full redesign** |
| `admin/admin-analytics.html` | New or integrate into dashboard | Create |
| `admin/admin-user-management.html` | `admin/users.blade.php` | Update |
| `admin/admin-listing-moderation.html` | `admin/moderation.blade.php` | Update |
| `admin/admin-content-flagging.html` | (part of moderation) | Merge |
| `admin/admin-sponsor-verification.html` | New page | Create |
| `admin/admin-sport-category-management.html` | `admin/categories.blade.php` | Update |
| `admin/admin-report-center.html` | `admin/reports.blade.php` | Update |
| `admin/admin-notification-templates.html` | `admin/notifications.blade.php` | Update |
| `admin/admin-system-settings.html` | New page | Create |

---

## 4. Implementation Phases

### Phase 1: Design System Update
**Duration:** 1-2 days

- [ ] Update `lib/theme/colors.dart` with new design tokens
- [ ] Update `lib/theme/app_text_styles.dart` if font changes to Inter
- [ ] Create `DesignTokens` class extracting all CSS variables from designs
- [ ] Update `pubspec.yaml` if adding Inter font
- [ ] Update shared widgets to use new tokens

### Phase 2: Auth & Onboarding Screens
**Duration:** 2-3 days

- [ ] Splash screen update
- [ ] Role selection update
- [ ] Login/Sign up/OTP updates
- [ ] Onboarding screens (sport, location) updates

### Phase 3: Home & Discovery
**Duration:** 3-4 days

- [ ] Home dashboard **full redesign**
- [ ] Universal search update
- [ ] Filter panel integration
- [ ] Search results update

### Phase 4: Directory & Listings
**Duration:** 4-5 days

- [ ] Academy directory/detail update
- [ ] Coach directory/detail update
- [ ] Trial listings/detail/registration update
- [ ] Tournament calendar update
- [ ] Registration confirmation update

### Phase 5: Role-Specific Dashboards
**Duration:** 5-7 days

- [ ] Coach dashboard + enquiries
- [ ] Academy dashboard + trials + registrants
- [ ] Organizer dashboard + tournaments + capacity
- [ ] Sponsor dashboard + applications

### Phase 6: Athlete Features
**Duration:** 2-3 days

- [ ] Profile view/edit update
- [ ] Media gallery update
- [ ] Scholarship/sponsorship screens update
- [ ] Apply sponsor form update

### Phase 7: Cross-Cutting Features
**Duration:** 2-3 days

- [ ] Settings screen update
- [ ] Help/Support center implementation
- [ ] Notifications center update
- [ ] Activity hub update
- [ ] Saved items update

### Phase 8: Admin Panel Redesign
**Duration:** 4-5 days

- [ ] Admin dashboard redesign
- [ ] Analytics page creation
- [ ] User management update
- [ ] Moderation queue update
- [ ] Sponsor verification page
- [ ] Category management update
- [ ] Report center update
- [ ] Notification templates update
- [ ] System settings page

---

## 5. Files to Delete (Old References)

The following old reference files should be removed if they exist:

```bash
# Old design references (if any)
sportsx/src/  # Old TypeScript React source (if replaced by Flutter)
*.psd         # Photoshop files (archive only)
*.sketch      # Sketch files (archive only)

# Temporary/reference HTML files
**/reference*.html
**/*_old.html
**/backup/**/*.html
```

**Note:** Based on current glob search, no old reference files were found in the workspace. The `sportsx-design-v1/` folder IS the current design source.

---

## 6. Architecture Preservation

### Keep Intact:
1. **Feature-first folder structure** — `lib/features/{feature}/`
2. **Riverpod state management** — All providers in `presentation/providers/`
3. **go_router navigation** — Routes defined in `core/router.dart`
4. **Reusable templates** — `directory_list_template.dart`, `detail_page_template.dart`
5. **API client** — `api_client.dart` with auth interceptor
6. **Models** — All in `shared/models/`

### Update Only UI:
1. Screens in `presentation/screens/` — Update Widget build methods
2. Theme tokens — Update color/spacing values only
3. Shared widgets — Update to match new design tokens

### Do Not Modify:
1. Business logic in providers
2. API integration patterns
3. Navigation route structure
4. Data models

---

## 7. Validation Checklist

After implementation:

- [ ] All 63 mobile screens match design fidelity
- [ ] All 11 admin screens match design fidelity
- [ ] No horizontal overflow on 360px, 390px, 430px viewports
- [ ] Design tokens consistent across all screens
- [ ] Interactive states (hover, focus, disabled, loading) match design
- [ ] Admin panel sidebar navigation works correctly
- [ ] Mobile bottom navigation works correctly
- [ ] No regression in existing functionality

---

## 8. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Font change (Poppins → Inter) | Use Google Fonts package, fallback to system Inter |
| Color token changes | Extract all tokens first, update systematically |
| New admin screens | Create new Blade files, don't modify existing routes |
| Missing designs for some screens | Reuse existing Flutter screens if design identical |
| Breaking existing functionality | Test each feature module independently |

---

## 9. Dependencies

```yaml
# pubspec.yaml additions
dependencies:
  google_fonts: ^6.1.0  # For Inter font
  flutter_svg: ^2.0.9   # If SVG icons needed
  lucide_flutter: ^0.0.1  # Lucide icons from design
```

---

## 10. File Structure After Implementation

```
sportx_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   ├── core/
│   │   ├── router.dart
│   │   └── theme/
│   │       ├── colors.dart          # Updated with new tokens
│   │       ├── app_text_styles.dart # Updated font
│   │       └── design_tokens.dart   # NEW: Extracted from HTML
│   ├── shared/
│   │   ├── models/
│   │   └── presentation/
│   │       └── widgets/             # Updated shared widgets
│   └── features/
│       ├── auth/                    # Phase 2
│       ├── onboarding/              # Phase 2
│       ├── home/                    # Phase 3
│       ├── search/                  # Phase 3
│       ├── academy/                  # Phase 4
│       ├── coach/                    # Phase 4
│       ├── trial/                    # Phase 4
│       ├── tournament/               # Phase 4
│       ├── scholarship/              # Phase 6
│       ├── sponsorship/              # Phase 6
│       ├── organizer/                # Phase 5
│       ├── sponsor/                  # Phase 5
│       ├── admin/                    # Phase 8
│       ├── saved/                    # Phase 7
│       ├── activity/                 # Phase 7
│       ├── notifications/            # Phase 7
│       └── settings/                 # Phase 7

sportx-api/
├── resources/views/admin/
│   ├── layouts/
│   │   └── main.blade.php           # Updated sidebar
│   ├── dashboard.blade.php          # Phase 8
│   ├── analytics.blade.php          # Phase 8 (new)
│   ├── users.blade.php              # Phase 8
│   ├── moderation.blade.php         # Phase 8
│   ├── sponsor-verification.blade.php # Phase 8 (new)
│   ├── categories.blade.php         # Phase 8
│   ├── reports.blade.php            # Phase 8
│   ├── notifications.blade.php      # Phase 8
│   └── system-settings.blade.php    # Phase 8 (new)
└── public/admin/
    ├── css/
    │   └── admin.css                # Updated styles
    └── js/
        └── admin.js                 # Updated interactions
```

---

## Appendix: Design Token Extraction Reference

### From `sportsx-design-v1/*/style` blocks:

```css
:root {
  --bg: #ffffff;           /* Background */
  --surface: #f7f8fa;      /* Card/Surface */
  --fg: #111111;           /* Primary text */
  --muted: #6b7280;        /* Secondary text */
  --border: #d9dee7;       /* Borders */
  --accent: #1677ff;       /* Primary accent/CTA */
  --radius: 8px;          /* Border radius */
}
```

### Font
- **Family:** Inter (Google Fonts)
- **Weights:** 400 (regular), 500 (medium), 600 (semibold), 700 (bold)

### Spacing (8px base)
- `4px` — xs
- `8px` — sm
- `12px` — md
- `16px` — lg
- `20px` — xl
- `24px` — 2xl
- `32px` — 3xl

### Icon Library
- **Lucide Icons** (via CDN: `https://unpkg.com/lucide@latest`)
