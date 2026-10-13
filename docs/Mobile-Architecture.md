# Mobile Architecture — SportX India (Flutter)

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

Flutter app architecture: folder structure, state management, navigation, key packages.

> **⚠️ [SUPERSEDED screen reference — see Backend-Feature-Delta.md].** The v1.1 inventory (**63 screens**) referenced below is replaced by `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md` (**129 screens, 6 roles: Athlete/Parent, Coach, Academy, Organizer, Talent Scout, Admin**; sponsor removed). New modules — social feed, network/messaging, opportunities, programs, leaderboard — are added in §6.

> **Platform integrations (2026-10):** §4A (Google sign-in), §4B (FCM services + known bugs) and §4C (notification preferences) added. See `Google-Authentication.md`, `FCM-Notification-System.md`.

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
│       ├── auth_provider.dart           # AuthNotifier (send-otp/verify-otp/login/logout)
│       ├── meta_provider.dart           # Sports, cities, age groups, positions, facilities
│       └── directory_provider.dart       # Generic paginated directory notifier
│
├── shared/
│   ├── models/                          # Sport, City, AgeGroup, Position, Academy, Coach,
│   │   └── models.dart                  # Trial, Tournament, Opportunity, Program, Post,
│   │                                   # SportsVenue, User + barrel export
│   └── providers/
│       ├── meta_provider.dart
│       └── directory_provider.dart
│
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── splash_screen.dart   # A.1
│   │       │   ├── role_selection_screen.dart  # A.2
│   │       │   ├── sign_up_screen.dart  # A.3
│   │       │   ├── otp_screen.dart      # A.4
│   │       │   ├── login_screen.dart    # A.5
│   │       │   └── forgot_password_screen.dart  # A.6
│   │       └── providers/
│   │           └── auth_provider.dart   # AuthNotifier (Riverpod)
│   │
│   ├── guardian/                        # [v3] A.9 guardian consent + AT.10 controls
│   │
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── screens/                 # AthleteOnboarding (AT.2), CoachOnboarding (CO.1),
│   │       │                           # AcademyOnboarding (AC.1), OrganizerOnboarding (OR.1),
│   │       │                           # ScoutOnboarding (SC.1)
│   │       └── widgets/                # SportChipSelector, AgeGroupPicker
│   │
│   ├── home/
│   │   └── presentation/
│   │       └── screens/
│   │           └── home_screen.dart     # S.1 / role Home (AT.1/CO.2/AC.2/OR.2/SC.2): GET /me/home
│   │
│   ├── profile/                         # D.1/D.2/D.3/D.4/D.5 own+public
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── search/                          # S.5 Universal Search + S.4 filter
│   │   └── presentation/
│   │       └── screens/
│   │
│   ├── directory/                       # S.2/S.3 list + detail
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── directory_list_screen.dart   # S.3 generic
│   │       │   └── directory_detail_screen.dart # detail generic
│   │       └── widgets/
│   │           ├── listing_card.dart    # card (athlete/coach/academy/organizer/scout)
│   │           ├── detail_hero.dart
│   │           ├── save_button.dart     # ♡ toggle
│   │           └── report_modal.dart    # S.26
│   │
│   ├── academy/                        # AC.1–AC.12
│   ├── coach/                           # CO.1–CO.8
│   ├── trials/                          # D.6–D.8 (event/trial detail+register)
│   ├── tournaments/                     # OR/detail (unified events)
│   ├── sports_venues/                    # D.13 venue directory + detail
│   ├── saved/                           # S.20 Saved/Bookmarked
│   ├── reports/                         # S.26 Report (user/post/listing)
│   │
│   ├── notifications/                   # S.16 Notifications Center
│   ├── settings/                        # S.22 Settings, S.23 Safety, S.24 Help, S.25 About
│   ├── enquiries/                       # D.12 Enquire + inbox/thread (S.18)
│   ├── activity/                        # S.21 My Activity Hub
│   │
│   ├── academy_management/              # AC.5–AC.12
│   ├── organizer/                       # OR.1–OR.17
│   ├── admin/                           # AD.1–AD.12
│   │
│   ├── feed/                            # [v3] S.8/S.9/S.27/S.28 social feed + posts
│   ├── network/                         # [v3] S.12/S.19 follow/connect; S.13/S.14 groups (P2)
│   ├── messaging/                       # [v3] S.17/S.18 conversations + chat
│   ├── opportunities/                   # [v3] D.9/D.10/AT.8/AC.9/SC.11/SC.12
│   ├── programs/                        # [v3] CO.4/CO.5/AC.4/D.11/D.12
│   ├── facilities/                      # [v3] AC.7/AC.8/D.13/OR.13
│   ├── leaderboard/                     # [v3] S.6/S.7 + home strip (AT.1)
│   ├── verification/                    # [v3] A.10 request + status + badge
│   ├── guardian/                        # [v3] A.9 consent + AT.10 parent controls
│   ├── scout/                           # [v3] SC.1–SC.13 (was `talent_scout`)
│   └── share/                           # [v3] S.30 deep-link/share resolver
│
│   # [REMOVED] `sponsor/` and `sponsor_management/` (SP1–SP9) — sponsor role dropped;
│   #           sponsorship is an opportunity type (see Backend-Feature-Delta.md §4)
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
| **Home / Explore** | `AsyncNotifierProvider<HomeNotifier, HomeState>` | `[v3]` `GET /me/home` role-aware dashboard + `GET /explore` grouped sections |
| **Feed / posts** | `AsyncNotifierProvider<FeedNotifier, FeedState>` | `[v3]` `feedProvider` — tabs For You/Following/…; optimistic like/comment |
| **Network** | `StateNotifierProvider<NetworkNotifier, NetworkState>` | `[v3]` `networkProvider` — followers/following/connections/requests |
| **Messaging** | `StreamNotifierProvider<ChatNotifier, ChatState>` | `[v3]` `conversationsProvider` — inbox + thread, unread badges |
| **Opportunities** | `AsyncNotifierProvider<OpportunitiesNotifier, …>` | `[v3]` `opportunitiesProvider` — browse/apply/my (Applied/Saved/Created) |
| **Programs** | `AsyncNotifierProvider<ProgramsNotifier, …>` | `[v3]` `programsProvider` — Active/Drafts/Past + public detail |
| **Leaderboard** | `AsyncNotifierProvider<LeaderboardNotifier, …>` | `[v3]` `leaderboardProvider` — tabs/filters + home strip |
| **Guardian (minors)** | `AsyncNotifierProvider<GuardianNotifier, …>` | `[v3]` consent status + parent controls (AT.10) |

---

## 3. Navigation — go_router

Auth redirect logic: authenticated → redirect to `/home`, unauthenticated → redirect to `/role-selection`. **[v3]** Signup/login pass through OTP (`/sign-up` → `/otp`), and a minor (DOB < 18) is forced to `/guardian-consent` before onboarding.

### Key Routes

| Path | Screen | Auth | Notes |
|---|---|---|---|
| `/splash` | A.1 Splash | — | Auto-redirect |
| `/role-selection` | A.2 Role Selection | — | **5** selectable role cards (sponsor removed) |
| `/sign-up` | A.3 Sign Up | — | Role passed via extra; phone/email |
| `/otp` | A.4 OTP Verification | — | phone/email+role via extra; resend timer |
| `/login` | A.5 Login | — | password **or** OTP; Google deferred |
| `/forgot-password` | A.6 Forgot/Reset | — | OTP-based (P1) |
| `/guardian-consent` | A.9 Guardian Consent | — | Required when DOB < 18 |
| `/home` | AT.1/CO.2/AC.2/OR.2/SC.2 Home Dashboard | Auth | Shell tab 1; `GET /me/home` |
| `/explore` | S.2 Explore | Auth | Shell tab 2; `GET /explore` |
| `/create` | S.8 Create Launcher | Auth | Shell tab 3 |
| `/community` | S.12 Network (P1) | Auth | Shell tab 4 |
| `/more` | S.15 More / account hub | Auth | Shell tab 5 |
| `/search` | S.5 Universal Search | Auth | |
| `/academies`, `/academies/:id` | D.3 Academy | Auth | + Programs/Facilities/Events/Reviews tabs |
| `/coaches`, `/coaches/:id` | D.2 Coach | Auth | + Programs tab |
| `/athletes/:id` | D.1 Athlete Profile | Auth | open to all roles; minors restricted |
| `/organizers/:id`, `/scouts/:id` | D.4/D.5 | Auth | public views |
| `/events`, `/events/:id` | D.6 Event/Trial Detail | Auth | Register (`D.7`) |
| `/opportunities`, `/opportunities/:id` | D.9/D.10 | Auth | browse/apply; `AT.8` My Opportunities |
| `/programs/:id` | D.11 Program Detail | Auth | Enquire (`D.12`) |
| `/facilities/:id` | D.13 Facility Detail | Auth | |
| `/leaderboard` | S.6 Leaderboard | Auth | + `/leaderboard/info` (`S.7`) |
| `/feed`, `/posts/:id` | S.9/S.27 | Auth | community feed + post detail |
| `/notifications` | S.16 Notifications | Auth | tabs + read-all |
| `/messages`, `/messages/:id` | S.17/S.18 | Auth | inbox + chat thread |
| `/connections` | S.19 Connections | Auth | followers/following/requests |
| `/saved` | S.20 Saved | Auth | + post/opportunity/event morphs |
| `/settings` | S.22 Settings & Privacy | Auth | + `/settings/safety` (`S.23`) |
| `/settings/help`, `/settings/about` | S.24/S.25 | Auth | |
| `/coach/dashboard`, `/coach/enquiries` | CO.2 / D.12+S.18 | Coach | |
| `/academy/dashboard`, `/academy/facilities`, `/academy/programs` | AC.2 / AC.7 / AC.4 | Academy | |
| `/scout/dashboard`, `/scout/discovery`, `/scout/shortlist` | SC.2 / SC.4 / SC.5 | Scout | |
| `/organizer/dashboard`, `/organizer/events` | OR.2 / OR.4 | Organizer | |
| ~~`/sponsor/*`~~ | — | — | **[REMOVED]** sponsor role dropped |
| `/admin/*` | AD.1–AD.12 | Admin | separate portal (web) |

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
| `url_launcher` | External links (registration links, provider sites) |
| `share_plus` | Share listing |
| `shimmer` | Loading skeleton placeholders |
| `intl` | Date formatting |
| **`firebase_core`** | Firebase bootstrap (already present) |
| **`firebase_messaging`** | FCM push — token registration, foreground/background handlers, deep-link routing |
| **`google_sign_in`** ␂ | "Continue with Google" — native account picker → ID token (`Google-Authentication.md`) |
| **`flutter_local_notifications`** ␂ | System-tray display for background push — **without it, background delivery is invisible** (AS-72) |

> **Platform-integration packages.** ␂ = add. `firebase_core` and `firebase_messaging` are already in `pubspec.yaml`; `google_sign_in` and `flutter_local_notifications` are not.

---

## 4A. Auth Services (Google sign-in) — **[NEW]**

> Full contract: `Google-Authentication.md`. This section covers the Flutter side only.

```dart
// auth/.../providers/auth_provider.dart — alongside login() and register()
class AuthNotifier {
  Future<void> signInWithGoogle({String? role}) async {
    // 1. Native account picker
    final account = await GoogleSignIn(
      clientId: Platform.isIOS
          ? DefaultFirebaseOptions.currentPlatform.iosClientId
          : null,
      scopes: ['email', 'profile'],
    ).signIn();

    final idToken = account.authentication.idToken;
    if (idToken == null) throw ApiException('Google sign-in returned no token');

    // 2. Exchange with the backend — the backend verifies, never the client
    final res = await dio.post('/auth/google', data: {
      'id_token': idToken,
      if (role != null) 'role': role,
    });

    // 3. SAME post-login sequence as password login — persist the token,
    //    call checkAuth(), and register the FCM token so push attaches
    //    to the new session.
    await storage.saveToken(res.data['token']);
    await checkAuth();
    await _registerFcmToken();
  }
}
```

| Platform | Requirement |
|---|---|
| Android | `serverClientId` in `build.gradle.kts`. **Requires a populated `oauth_client` in `google-services.json`** — it is currently empty, so Android sign-in fails with `DEVELOPER_ERROR` even though the app otherwise works |
| iOS | `REVERSED_CLIENT_ID` in `Info.plist` + the URL scheme from `CFBundleURLSchemes` |
| Both | Package name / bundle ID must match the OAuth client's authorised application exactly |

> **Pin `google_sign_in` explicitly.** `^7+` changes the API surface; do not rely on a caret range spanning the major bump.
>
> **Web caveat.** The plugin does not support the Firebase Auth path on web; Flutter web falls back to the password flow. The API is provider-agnostic, so enabling Google on web later needs no backend change.

---

## 4B. Notification Services (FCM) — **[NEW]**

> Full contract: `FCM-Notification-System.md`. `PushNotificationService` already exists and registers tokens; this section lists what is still missing.

| Scenario | Behaviour |
|---|---|
| Cold start | `getInitialMessage()` → deep link to the referenced screen |
| Foreground | `onMessage` → `flutter_local_notifications` + provider refresh + SnackBar |
| Background | `@pragma('vm:entry-point')` handler → `LocalNotifications` in the system tray |
| Tap (background) | `getInitialMessage()` → deep link |
| Tap (foreground) | `onMessageOpenedApp` → deep link |
| Token refresh | `onTokenRefresh` → `POST /me/device-tokens` (idempotent upsert) |

**Registration** runs post-frame from `main.dart`: `requestPermission(alert: true, badge: true, sound: true)` then register the token. `AuthNotifier` re-registers after login and unregisters on logout, so a token always belongs to the current session.

### Known bugs to fix

| # | Bug | Impact |
|---|---|---|
| 1 | `main.dart` calls `Firebase.initializeApp()` with **no `options:`** | `DefaultFirebaseOptions` is never used; web and tests fail |
| 2 | Foreground handler shows a SnackBar but **no system notification** | A backgrounded-but-not-terminated app produces nothing visible |
| 3 | `POST_NOTIFICATIONS` not declared in `AndroidManifest.xml` | `requestPermission()` is a **silent no-op on Android 13+** — the single most common cause of "works on 12, not 13" |
| 4 | Android channel IDs not aligned with the backend | A mismatch means the notification is silently dropped |

Android channel IDs **must match** the backend exactly: `sportx_default`, `sportx_enquiries`, `sportx_reminders`, `sportx_updates`, `sportx_announcements`.

### Deep links

The push payload carries `action_url` and `category`. A tap routes through `go_router` using the app's `navigatorKey`.

> **A push payload is routing metadata, never an authorization grant.** The tapped screen must re-fetch the resource and let the API re-check ownership — never assume the payload proved access.

---

## 4C. Notification Preferences UI

Backed by `GET/PUT /me/notification-preferences`. Toggles map to `users.notification_prefs`:

| Toggle | Effect |
|---|---|
| Push notifications (master) | All FCM |
| Enquiries | `category=enquiry` |
| Reminders | `category=reminder` |
| Updates & approvals | `category=status_update`, `registrations` |
| Announcements | `category=broadcast` |
| Email fallback | `email.default` — **off by default** |

Account actions and registration decisions are **hard overrides**: they always deliver in-app and cannot be switched off. The UI should mark those rows as non-disableable rather than showing a toggle that silently does nothing.

---

## 5. Screen → Feature Mapping (63 Screens per v1.1)

> **[SUPERSEDED — see Backend-Feature-Delta.md].** This v1.1 mapping (63 screens, includes Sponsor) is replaced by the v3 inventory (`sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md`, 129 screens). Use `Design-to-Flutter-Mapping.md` for the current screen→Flutter mapping. Retained for history.

### [v3] New modules → feature folders (summary)

| New area | New screens | Feature folder |
|---|---|---|
| Social feed & posts | S.8, S.9, S.27, S.28 | `features/feed/` |
| Network (follow/connect) | S.12, S.19 (S.13/S.14 P2) | `features/network/` |
| Messaging | S.17, S.18 | `features/messaging/` |
| Opportunities | D.9, D.10, AT.8, AC.9, SC.11, SC.12 | `features/opportunities/` |
| Programs | CO.4, CO.5, AC.4, D.11, D.12 | `features/programs/` |
| Facilities / venues | AC.7, AC.8, D.13, OR.13 | `features/facilities/` |
| Leaderboard | S.6, S.7, AT.1 strip | `features/leaderboard/` |
| Verification | A.10, AD.4 | `features/verification/` |
| Guardian (minors) | A.9, AT.10 | `features/guardian/` |
| Scout | SC.1–SC.13 | `features/scout/` |
| Share / deep links | S.30 | `features/share/` |

### [SUPERSEDED] v1.1 detail

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

*Design system: `SportX_India_Design_System.md` (see §Design System above)*  
*Screen inventory (v3, canonical): `sportsx-design-v3/new_design_docs/SCREEN_INVENTORY.md`*  
*Wireframes (v3): `sportsx-design-v3/new_design_docs/01_athlete_wireframes.md`–`06_admin_wireframes.md`*  

---

## 6. [v3] New module notes

- **Feed/social:** a `features/feed/` module exposing `GET /feed` with tabs (For You / Following / Athletes / Coaches / Academies / Events) and full post CRUD, likes and comments. Denormalized `likes_count`/`comments_count` on post resources (delta §11.9).
- **Network/messaging:** one-way `follows` and mutual `connection_requests` plus `conversations`/`messages` for 1-to-1 chat. Chat unlocks only after an accepted connection or an enquiry thread; minors restricted to guardian-allowed connections (delta §11.10/§11.11, rules §7).
- **Opportunities:** unified `opportunities` (types scholarship/sponsorship/tryout/camp) with in-app applications (`pitch` + profile snapshot) and My Opportunities tabs Applied/Saved/Created (delta §11.7).
- **Programs:** `programs` owned by coach/academy with Active/Drafts/Past tabs and public detail + enquiry→thread (delta §11.8).
- **Leaderboard:** `GET /leaderboard` + `GET /leaderboard/strip` for the home dashboard; athletes P0, coaches/academies/teams/events P1; minors anonymized (delta §11.5, M8.1).
- **Unified dashboard:** all role homes now call `GET /me/home` (greeting, completion %, leaderboard strip, shortcut counts, feed preview); Explore calls `GET /explore` (delta §11.5).
- **Profile fields:** every role captures its **30 fields** (`SportX_Mandatory_Fields.md`); completion is itemized per-role (`GET /me/completion-checklist`, `AT.6`).
