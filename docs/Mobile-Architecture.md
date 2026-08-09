# Mobile Architecture — SportX India (Flutter)

Flutter app architecture: folder structure, state management, navigation, key packages. Consistent with the screen inventory (63 screens per `SportX_India_Screen_Inventory_v1.1.md`) and wireframe templates (T1–T4b).

> **Design System Reference:** All UI must follow `SportX_India_Design_System.md` from the Figma HTML reference (`/sportsx/src/imports/SportX_Design_System.md`).
>
> **Key Design Rules:**
> - Colors: Primary Blue `#2563EB`, CTA Orange `#F97316`, Text `#111827`, Surface `#F8FAFC`, Border `#E5E7EB`
> - Font: Poppins (Google Fonts) — fallback Inter/sans-serif
> - Spacing: 8px base grid — `space-1`=4px, `space-2`=8px, `space-4`=16px, `space-6`=24px, `space-8`=32px
> - Border Radius: Cards=16px, Buttons=12px, Inputs=12px, Chips=20px, OTP boxes=10px
> - Shadows: `shadow-md` for cards, `shadow-lg` for modals/sheets, `shadow-orange` for CTA buttons

---

## Design System Implementation

### Colors (`lib/theme/colors.dart`)
```dart
class AppColors {
  // Primary
  static const Color primary = Color(0xFF2563EB);     // Royal Blue
  static const Color cta = Color(0xFFF97316);           // Orange CTA

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);       // Card backgrounds

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Borders
  static const Color border = Color(0xFFE5E7EB);

  // Semantic
  static const Color success = Color(0xFF22C55E);      // Verified, open
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);       // Pending, draft
  static const Color infoLight = Color(0xFFEFF6FF);    // Unread bg

  // Shades
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryDarker = Color(0xFF1E40AF);
  static const Color ctaDark = Color(0xFFEA6C0A);
  static const Color ctaLight = Color(0xFFFED7AA);
}
```

### Typography (`lib/theme/app_text_styles.dart`)
```dart
class AppTextStyles {
  static const TextStyle display = TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const TextStyle h1 = TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700);
  static const TextStyle h2 = TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600);
  static const TextStyle h3 = TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodySemiBold = TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle caption = TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.1);
  static const TextStyle captionSemiBold = TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600);
  static const TextStyle button = TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const TextStyle sectionLabel = TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.08, color: AppColors.textSecondary);
}
```

> **Poppins font:** Add to `pubspec.yaml`:
> ```yaml
> fonts:
>   - family: Poppins
>     fonts:
>       - asset: assets/fonts/Poppins-Regular.ttf
>         weight: 400
>       - asset: assets/fonts/Poppins-SemiBold.ttf
>         weight: 600
>       - asset: assets/fonts/Poppins-Bold.ttf
>         weight: 700
> ```

---

## 1. Folder Structure (Feature-First)

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── api_config.dart                  # API base URL, timeouts
│   └── app_config.dart                  # App name, pagination defaults
│
├── core/
│   ├── config/
│   │   └── api_config.dart
│   ├── router.dart                      # go_router with auth redirect
│   ├── theme/
│   │   ├── colors.dart                  # AppColors (per design system)
│   │   ├── app_text_styles.dart         # AppTextStyles (Poppins-based)
│   │   └── app_theme.dart               # ThemeData (Poppins font, design tokens)
│   ├── utils/
│   │   ├── api_client.dart             # Dio singleton with auth interceptor
│   │   └── storage_service.dart         # flutter_secure_storage
│   └── providers/
│       ├── auth_provider.dart           # AuthNotifier (register/verify-otp/login/logout)
│       ├── meta_provider.dart           # Sports, cities, age groups
│       └── directory_provider.dart       # Generic paginated directory notifier
│
├── shared/
│   ├── models/                          # Sport, City, AgeGroup, Academy, Coach,
│   │   └── models.dart                  # Trial, Tournament, Scholarship, Sponsorship,
│   │                                   # SportsVenue, User + barrel export
│   └── providers/
│       ├── meta_provider.dart
│       └── directory_provider.dart
│
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── splash_screen.dart   # S1
│   │       │   ├── role_selection_screen.dart  # S2
│   │       │   ├── sign_up_screen.dart  # S3
│   │       │   ├── otp_screen.dart      # S4
│   │       │   └── login_screen.dart    # S5
│   │       └── providers/
│   │           └── auth_provider.dart   # AuthNotifier (Riverpod)
│   │
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── screens/                 # AthleteOnboarding (2 steps), CoachOnboarding,
│   │       │                           # AcademyOnboarding, OrganizerOnboarding,
│   │       │                           # SponsorOnboarding
│   │       └── widgets/                # SportChipSelector, AgeGroupPicker
│   │
│   ├── home/
│   │   └── presentation/
│   │       └── screens/
│   │           └── home_screen.dart     # A3: search bar, sport chips, sections
│   │
│   ├── profile/                         # A4 My Profile, A5 Edit Profile, A6 Media
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── search/                          # S6 Universal Search, S7 Results, S8 Filter
│   │   └── presentation/
│   │       └── screens/
│   │
│   ├── directory/                       # T1 list + T2 detail templates
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── directory_list_screen.dart   # T1 generic
│   │       │   └── directory_detail_screen.dart # T2 generic
│   │       └── widgets/
│   │           ├── listing_card.dart    # T1 card (athlete/coach/academy/sponsor)
│   │           ├── detail_hero.dart
│   │           ├── save_button.dart     # ♡ toggle
│   │           └── report_modal.dart    # S10
│   │
│   ├── academy/                        # A7, A8
│   ├── coach/                           # A9, A10, C3
│   ├── trials/                          # A12, A13, A14, A15
│   ├── tournaments/                     # A16, A17, A18
│   ├── scholarships/                    # A19, A20
│   ├── sponsorships/                     # A21, A22, A23
│   ├── sports_venues/                    # AS-47: venue directory + detail
│   ├── saved/                           # A25 Saved/Bookmarked
│   ├── reports/                         # S10 Report a Listing
│   │
│   ├── notifications/                   # S9 Notifications Center
│   ├── settings/                        # S11 Settings, S12 Help/Support
│   ├── enquiries/                       # A11 Enquire + C4/C5/AC8/AC9 Inbox/Thread
│   ├── activity/                        # A24 My Activity Hub
│   │
│   ├── academy_management/              # AC2–AC9
│   ├── organizer/                       # O2–O10
│   ├── sponsor_management/              # SP1–SP9
│   └── admin/                           # AD1–AD12 (Phase 3)
```

---

## 2. State Management — Riverpod

| Concern | Provider type | Example |
|---|---|---|
| **Auth state** | `StateNotifierProvider<AuthNotifier, AuthState>` | `authProvider` — holds user, token, role |
| **Meta data** | `StateNotifierProvider<MetaNotifier, MetaState>` | `metaProvider` — sports, cities, age groups |
| **Directory lists** | `StateNotifierProvider<DirectoryNotifier<T>, DirectoryState<T>>` | Generic for Academy, Coach, Trial, etc. |
| **Search** | `StateNotifierProvider<SearchNotifier, SearchState>` | `searchProvider` — query, results, loading |
| **Filters** | `StateProvider<FilterState>` | `filterProvider` — sport, city, age, price, date |
| **Saved items** | `StateNotifierProvider<SavedNotifier, Set<SavedKey>>` | Optimistic ♡ toggle |
| **Notifications** | `AsyncNotifierProvider<NotificationsNotifier, List>` | `notificationsProvider` — unread count |

---

## 3. Navigation — go_router

Auth redirect logic: authenticated → redirect to `/home`, unauthenticated → redirect to `/role-selection`.

### Key Routes

| Path | Screen | Auth | Notes |
|---|---|---|---|
| `/splash` | S1 Splash | — | Auto-redirect |
| `/role-selection` | S2 Role Selection | — | 5 role cards |
| `/sign-up` | S3 Sign Up | — | Role passed via extra |
| `/otp` | S4 OTP Verification | — | email+role via extra |
| `/login` | S5 Login | — | Email/password + Google placeholder |
| `/home` | A3 Home Dashboard | Auth | Bottom nav tab 1 |
| `/search` | S6 Universal Search | Auth | Bottom nav tab 2 |
| `/saved` | A25 Saved Items | Auth | Bottom nav tab 3 |
| `/profile` | A4 My Profile | Auth | Bottom nav tab 4 |
| `/academies` | A7 Academy Directory | Auth | T1 template |
| `/academies/:id` | A8 Academy Detail | Auth | T2 template |
| `/coaches` | A9 Coach Directory | Auth | T1 template |
| `/coaches/:id` | A10 Coach Detail | Auth | T2 template |
| `/trials` | A12 Trial Listings | Auth | T1 template |
| `/trials/:id` | A13 Trial Detail | Auth | T2 template |
| `/tournaments` | A16 Tournament Calendar | Auth | Calendar/list toggle |
| `/tournaments/:id` | A17 Tournament Detail | Auth | T2 template |
| `/scholarships` | A19 Scholarship Feed | Auth | T1 template |
| `/scholarships/:id` | A20 Scholarship Detail | Auth | T2 template + external link |
| `/sponsorships` | A21 Sponsorship List | Auth | T1 template |
| `/sponsorships/:id` | A22 Sponsorship Detail | Auth | T2 template |
| `/sports-venues` | Sports Venue Directory | Auth | T1 template |
| `/sports-venues/:id` | Sports Venue Detail | Auth | T2 template |
| `/notifications` | S9 Notifications | Auth | |
| `/settings` | S11 Settings | Auth | |
| `/settings/help` | S12 Help/Support | Auth | |
| `/coach/dashboard` | C3 Coach Dashboard | Coach | |
| `/coach/enquiries` | C4/C5 Enquiry Inbox/Thread | Coach | |
| `/academy/dashboard` | AC3 Academy Dashboard | Academy | |
| `/academy/enquiries` | AC8/AC9 Enquiry Inbox/Thread | Academy | |
| `/organizer/dashboard` | O2 | Organizer | |
| `/sponsor/dashboard` | SP2 | Sponsor | |
| `/admin/*` | AD1–AD12 | Admin | Phase 3 |

---

## 4. Key Packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Declarative navigation + deep links |
| `dio` | HTTP client with auth interceptors |
| `flutter_secure_storage` | Auth token storage |
| `google_fonts` | Poppins font loading (or bundle TTF assets) |
| `table_calendar` | Tournament calendar (A16) |
| `image_picker` | Photo/video upload (A6, A14) |
| `cached_network_image` | Image caching |
| `url_launcher` | External links (scholarships, sponsor sites) |
| `share_plus` | Share listing |
| `shimmer` | Loading skeleton placeholders |
| `intl` | Date formatting |

---

## 5. Screen → Feature Mapping (63 Screens per v1.1)

Screen IDs below reference v1.1 inventory (`SportX_India_Screen_Inventory_v1.1.md`), grouped by section:
- **Auth-#** = Section 1 (Authentication & Onboarding)
- **Athlete-#** = Section 2 (Athlete Screens)
- **Coach-#** = Section 3 (Coach Screens)
- **Academy-#** = Section 3 (Academy Screens — same section as Coach)
- **Sponsor-#** = Section 4 (Sponsor Screens)
- **Shared-#** = Section 5 (Shared Screens)
- **Admin-#** = Section 6 (Admin Mobile Screens)

### Auth (7 screens — v1.1 Section 1)
| Screen | ID | Feature |
|---|---|---|
| Splash | Auth-1 | `features/auth/presentation/screens/splash_screen.dart` |
| Role Selection | Auth-2 | `features/auth/presentation/screens/role_selection_screen.dart` |
| Sign Up | Auth-3 | `features/auth/presentation/screens/sign_up_screen.dart` |
| OTP Verification | Auth-4 | `features/auth/presentation/screens/otp_screen.dart` |
| Login | Auth-5 | `features/auth/presentation/screens/login_screen.dart` |
| Forgot Password | Auth-6 | `features/auth/presentation/screens/forgot_password_screen.dart` |
| Reset Password | Auth-7 | `features/auth/presentation/screens/reset_password_screen.dart` |

### Athlete (17 screens — v1.1 Section 2)
| # | Screen | ID | Feature |
|---|---|---|---|
| 1 | Home / feed | Athlete-1 | `features/home/presentation/screens/home_screen.dart` |
| 2 | Create post | Athlete-2 | (future) |
| 3 | My profile | Athlete-3 | `features/athlete/presentation/screens/profile_screen.dart` |
| 4 | Edit profile | Athlete-4 | `features/athlete/presentation/screens/edit_profile_screen.dart` |
| 5 | Add achievement | Athlete-5 | `features/athlete/presentation/screens/add_achievement_screen.dart` |
| 6 | Add tournament entry | Athlete-6 | (future) |
| 7 | Tournament history | Athlete-7 | (future) |
| 8 | Edit stats | Athlete-8 | (future) |
| 9 | Media gallery | Athlete-9 | (future) |
| 10 | Upload media | Athlete-10 | (future) |
| 11 | Edit social links | Athlete-11 | (future) |
| 12 | Discover directory | Athlete-12 | (future) |
| 13 | My connections | Athlete-13 | (future) |
| 14 | Connection requests | Athlete-14 | (future) |
| 15 | Chat list | Athlete-15 | (future) |
| 16 | Chat screen | Athlete-16 | (future) |
| 17 | Academies & coaches directory | Athlete-17 | `features/academy/presentation/screens/academy_directory_screen.dart` + `features/coach/presentation/screens/coach_directory_screen.dart` |

### Coach / Academy (8 screens — v1.1 Section 3)
| # | Screen | ID | Feature |
|---|---|---|---|
| 1 | Coach home | Coach-1 | `features/coach/presentation/screens/coach_dashboard_screen.dart` |
| 2 | Coach profile (own) | Coach-2 | `features/coach/presentation/screens/coach_profile_posting_screen.dart` |
| 3 | Edit coach profile | Coach-3 | `features/coach/presentation/screens/coach_profile_posting_screen.dart` |
| 4 | Add credentials | Coach-4 | (future) |
| 5 | Edit facilities | Coach-5 | (future) |
| 6 | Associated athletes | Coach-6 | (future) |
| 7 | Athlete directory (coach) | Coach-7 | `features/sponsor/presentation/screens/athlete_discovery_screen.dart` |
| 8 | Sponsor directory (coach) | Coach-8 | (future) |

Academy screens share the same section (Coach-# IDs above, but via `features/academy/`):
| # | Screen | ID | Feature |
|---|---|---|---|
| 1 | Academy home | Academy-1 | `features/academy/presentation/screens/academy_dashboard_screen.dart` |
| 2 | Academy profile (own) | Academy-2 | `features/academy/presentation/screens/academy_profile_posting_screen.dart` |
| 3 | Edit academy profile | Academy-3 | `features/academy/presentation/screens/academy_profile_posting_screen.dart` |
| 4 | Add credentials | Academy-4 | (future) |
| 5 | Edit facilities | Academy-5 | (future) |
| 6 | Associated athletes | Academy-6 | (future) |
| 7 | Athlete directory (academy) | Academy-7 | (future) |
| 8 | Sponsor directory (academy) | Academy-8 | (future) |

### Sponsor (9 screens — v1.1 Section 4)
| # | Screen | ID | Feature |
|---|---|---|---|
| 1 | Sponsor home | Sponsor-1 | `features/sponsor/presentation/screens/sponsor_dashboard_screen.dart` |
| 2 | Sponsor profile (own) | Sponsor-2 | `features/sponsor/presentation/screens/sponsor_onboarding_screen.dart` |
| 3 | Edit sponsor profile | Sponsor-3 | `features/sponsor/presentation/screens/sponsor_onboarding_screen.dart` |
| 4 | My active opportunities | Sponsor-4 | `features/sponsor/presentation/screens/my_sponsorships_management_screen.dart` |
| 5 | Past associations | Sponsor-5 | (future) |
| 6 | Athlete directory (sponsor) | Sponsor-6 | `features/sponsor/presentation/screens/athlete_discovery_screen.dart` |
| 7 | Academy directory (sponsor) | Sponsor-7 | `features/academy/presentation/screens/academy_directory_screen.dart` |
| 8 | Post opportunity | Sponsor-8 | `features/sponsor/presentation/screens/sponsorship_posting_screen.dart` |
| 9 | Listing status | Sponsor-9 | `features/sponsor/presentation/screens/my_sponsorships_management_screen.dart` |

### Shared (11 screens — v1.1 Section 5)
| # | Screen | ID | Feature |
|---|---|---|---|
| 1 | View profile (read-only) | Shared-1 | `features/sponsor/presentation/screens/athlete_profile_view_screen.dart`, `features/academy/presentation/screens/academy_detail_screen.dart`, etc. |
| 2 | Post detail | Shared-2 | (future) |
| 3 | Opportunities list | Shared-3 | `features/trial/presentation/screens/trial_directory_screen.dart`, `features/scholarship/presentation/screens/scholarship_list_screen.dart`, `features/sports_venue/presentation/screens/sports_venue_list_screen.dart` |
| 4 | Opportunity detail | Shared-4 | `features/trial/presentation/screens/trial_detail_screen.dart` |
| 5 | Apply / express interest | Shared-5 | `features/shared/presentation/screens/sponsor_pitch_screen.dart`, `features/trial/presentation/screens/trial_registration_screen.dart` |
| 6 | Application confirmation | Shared-6 | `features/shared/presentation/screens/registration_confirmation_screen.dart` |
| 7 | Search & filter | Shared-7 | `features/home/presentation/screens/search_screen.dart` |
| 8 | Notifications list | Shared-8 | `features/notifications/presentation/screens/notifications_screen.dart` |
| 9 | Notification detail | Shared-9 | (future — notification item tap) |
| 10 | Settings | Shared-10 | `features/settings/presentation/screens/settings_screen.dart` |
| 11 | Media viewer | Shared-11 | (future) |

### Admin Mobile (11 screens — v1.1 Section 6)
| # | Screen | ID | Feature |
|---|---|---|---|
| 1 | Admin dashboard | Admin-1 | `features/admin/presentation/screens/admin_dashboard_screen.dart` |
| 2 | Platform reports | Admin-2 | `features/admin/presentation/screens/admin_content_list_screen.dart` |
| 3 | Manage users list | Admin-3 | (future) |
| 4 | User detail / verify | Admin-4 | (future) |
| 5 | Pending registrations | Admin-5 | `features/admin/presentation/screens/admin_content_picker_screen.dart` |
| 6 | Moderation queue | Admin-6 | (future) |
| 7 | Report detail | Admin-7 | (future) |
| 8 | Compose notification | Admin-8 | (future) |
| 9 | Notification targeting | Admin-9 | (future) |
| 10 | Opportunity approval | Admin-10 | (future) |
| 11 | Opportunity review detail | Admin-11 | (future) |

---

*Design system: `/sportsx/src/imports/SportX_Design_System.md`*  
*Screen inventory v1.1: `/sportsx/src/imports/SportX_India_Screen_Inventory_v1.1.md`*  
*Wireframe reference: `/sportsx/src/imports/SportX_India_Complete_Wireframe.md`*
