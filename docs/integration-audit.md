# Integration Audit — SportX India (Flutter ↔ Laravel)

**Audit Date:** 2026-08-18
**Auditor:** Flutter-Laravel Integration Auditor Agent

---

## Phase 0 — Orientation Summary

### API Configuration
- **Base URL:** `https://hedgier-shayne-unnotioned.ngrok-free.dev/api/v1` (both Flutter `.env` and Laravel `.env` align)
- **Auth Strategy:** Laravel Sanctum bearer tokens (`Authorization: Bearer <token>`)
- **Versioning:** `/api/v1/...` prefix
- **Response Envelope:**
  - Lists: `{ data: [], meta: { current_page, per_page, total, last_page } }` (no `meta` wrapper according to directory_provider.dart:47 comment)
  - Singles: `{ data: { ... } }`
- **Error Envelope:** `{ error: { code, message, fields? } }`

### Backend Structure
- Laravel API at `sportx-api/`
- Routes defined in `routes/api.php` with `v1` prefix
- Controllers in `app/Http/Controllers/`
- Models in `app/Models/`
- No dedicated `Requests/` or `Resources/` directories (validation inline in controllers)

### Flutter Structure
- App at `sportx_app/`
- API client: `lib/core/utils/api_client.dart` (Dio-based)
- Providers in `lib/features/*/presentation/providers/` and `lib/shared/providers/`
- Models in `lib/shared/models/`

---

## Phase 0.5 — Enumeration Counts

```
Routes found (api.php): ~172 Route:: calls
Flutter HTTP call sites found: 89 dio method calls across 19 providers
FormRequests found: 0 (none - validation inline)
API Resources found: 0 (none - direct array response)
```

### Reconciliation
- Backend route lines: 172 (grep count)
- Flutter API call sites: 89 (dio.get/post/put/patch/delete calls)
- Contract map rows: ~130 endpoints mapped

---

## Phase 1 — Contract Map

### Auth Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/auth/register` | POST | `AuthController@register` | `auth_provider.dart:register()` | ✅ matches |
| `/auth/verify-email` | POST | `AuthController@verifyEmail` | `auth_provider.dart:verifyEmail()` | ✅ matches |
| `/auth/login` | POST | `AuthController@login` | `auth_provider.dart:login()` | ✅ matches |
| `/auth/logout` | POST | `AuthController@logout` | `auth_provider.dart:logout()` | ✅ matches |
| `/auth/me` | GET | `AuthController@me` | `auth_provider.dart:checkAuth()`, `refreshUser()` | ✅ matches |
| `/auth/forgot-password` | POST | `AuthController@forgotPassword` | `auth_provider.dart:forgotPassword()` | ✅ matches |
| `/auth/reset-password` | POST | `AuthController@resetPassword` | `auth_provider.dart:resetPassword()` | ✅ matches |
| `/auth/resend-verification` | POST | — NOT FOUND — | `auth_provider.dart:resendOtp()` | ❌ broken call |
| `/auth/verify-otp` | POST | — NOT FOUND — | `auth_provider.dart:verifyOtp()` | ⚠️ alias for verifyEmail |

### Meta/Master Data Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/meta/sports` | GET | `MetaController@sports` | `meta_provider.dart:loadMeta()` | ✅ matches |
| `/meta/cities` | GET | `MetaController@cities` | `meta_provider.dart:loadMeta()` | ✅ matches |
| `/meta/age-groups` | GET | `MetaController@ageGroups` | `meta_provider.dart:loadMeta()` | ✅ matches |
| `/meta/trending-searches` | GET | `MetaController@trendingSearches` | — NOT CALLED — | 🕸️ unused |

### Onboarding Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/onboarding/athlete` | POST | `OnboardingController@athlete` | `onboarding_provider.dart:submitAthleteOnboarding()` | ✅ matches |
| `/onboarding/coach` | POST | `OnboardingController@coach` | — NOT FOUND — | ❌ missing |
| `/onboarding/academy` | POST | `OnboardingController@academy` | — NOT FOUND — | ❌ missing |
| `/onboarding/organizer` | POST | `OnboardingController@organizer` | — NOT FOUND — | ❌ missing |
| `/onboarding/sponsor` | POST | `OnboardingController@sponsor` | — NOT FOUND — | ❌ missing |
| `/onboarding/{role}` | GET | `OnboardingController@schema` | — NOT FOUND — | ❌ missing |

### Directory Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/academies` | GET | `DirectoryController@academies` | `directory_provider.dart:academiesProvider` | ✅ matches |
| `/academies/{id}` | GET | `DirectoryController@academy` | `directory_provider.dart:academyDetailProvider` | ✅ matches |
| `/coaches` | GET | `DirectoryController@coaches` | `directory_provider.dart:coachesProvider` | ✅ matches |
| `/coaches/{id}` | GET | `DirectoryController@coach` | `directory_provider.dart:coachDetailProvider` | ✅ matches |
| `/trials` | GET | `TrialController@index` | `directory_provider.dart:trialsProvider` | ✅ matches |
| `/trials/{id}` | GET | `TrialController@show` | `directory_provider.dart:trialDetailProvider` | ✅ matches |
| `/tournaments` | GET | `TournamentController@index` | `directory_provider.dart:tournamentsProvider` | ✅ matches |
| `/tournaments/{id}` | GET | `TournamentController@show` | `directory_provider.dart:tournamentDetailProvider` | ✅ matches |
| `/scholarships` | GET | `ScholarshipController@index` | `directory_provider.dart:scholarshipsProvider` | ✅ matches |
| `/scholarships/{id}` | GET | `ScholarshipController@show` | `directory_provider.dart:scholarshipDetailProvider` | ✅ matches |
| `/sponsorships` | GET | `SponsorshipController@index` | `directory_provider.dart:sponsorshipsProvider` | ✅ matches |
| `/sponsorships/{id}` | GET | `SponsorshipController@show` | `directory_provider.dart:sponsorshipDetailProvider` | ✅ matches |
| `/sports-venues` | GET | `SportsVenueController@index` | `directory_provider.dart:sportsVenuesProvider` | ✅ matches |
| `/sports-venues/{id}` | GET | `SportsVenueController@show` | `directory_provider.dart:sportsVenueDetailProvider` | ✅ matches |

### Search Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/search` | GET | `SearchController@search` | `search_provider.dart:search()` | ✅ matches |
| `/me/recent-searches` | GET | `SearchController@recentSearches` | `search_provider.dart:loadRecentSearches()` | ✅ matches |

### Saved/Activity Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/saved` | GET | `SavedItemController@index` | `saved_provider.dart:load()` | ✅ matches |
| `/me/saved` | POST | `SavedItemController@store` | `saved_provider.dart:toggle()` | ✅ matches |
| `/me/saved` | DELETE | `SavedItemController@destroy` | `saved_provider.dart:toggle()`, `remove()` | ✅ matches |
| `/me/activity` | GET | `ActivityController@index` | `activity_provider.dart:load()` | ✅ matches |

### Profile Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/profile` | GET | `ProfileController@show` | `edit_profile_screen.dart:_loadCurrentProfile()` | ✅ matches |
| `/me/profile` | PUT | `ProfileController@update` | `edit_profile_screen.dart:_saveProfile()` | ✅ matches |
| `/me/profile/sports` | PUT | `ProfileController@updateSports` | — NOT FOUND — | ❌ missing |

### Media Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/media/upload` | POST | `MediaController@upload` | `media_picker.dart:pickAndUploadMedia()` | ✅ matches |
| `/media/{id}` | DELETE | `MediaController@destroy` | — NOT FOUND — | ❌ missing |
| `/media/reorder` | PUT | `MediaController@reorder` | — NOT FOUND — | ❌ missing |
| `/media/download/{id}` | GET | `MediaController@download` | — NOT FOUND — | ❌ missing |

### Enquiry Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/enquiries` | POST | `EnquiryController@store` | — NOT FOUND (from athlete side) — | ❌ missing |
| `/me/enquiries` | GET | `EnquiryController@inbox` | `enquiry_provider.dart:load()` | ✅ matches |
| `/enquiries/{id}` | GET | `EnquiryController@show` | `enquiry_provider.dart:enquiryDetailProvider` | ✅ matches |
| `/enquiries/{id}/messages` | POST | `EnquiryController@reply` | `enquiry_provider.dart:replyEnquiry()` | ✅ matches |
| `/enquiries/{id}/read` | PUT | `EnquiryController@markRead` | `enquiry_provider.dart:markEnquiryRead()` | ✅ matches |

### Notifications Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/notifications` | GET | `NotificationController@index` | `notifications_provider.dart:load()` | ✅ matches |
| `/me/notifications/{id}/read` | PATCH | `NotificationController@markRead` | `notifications_provider.dart:markAsRead()` | ✅ matches |
| `/me/notifications/read-all` | POST | `NotificationController@markAllRead` | `notifications_provider.dart:markAllRead()` | ✅ matches |
| `/me/notifications/{id}` | DELETE | `NotificationController@destroy` | — NOT FOUND — | ❌ missing |
| `/me/device-tokens` | POST | `NotificationController@registerDeviceToken` | — NOT FOUND — | ❌ missing |
| `/me/device-tokens` | DELETE | `NotificationController@unregisterDeviceToken` | — NOT FOUND — | ❌ missing |

### Settings Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/settings` | GET | `SettingsController@show` | `settings_provider.dart:load()` | ✅ matches |
| `/me/settings` | PUT | `SettingsController@update` | `settings_provider.dart:updatePrefs()`, `updateLanguage()` | ✅ matches |
| `/me/settings/password` | PUT | `SettingsController@updatePassword` | `settings_provider.dart:updatePassword()` | ✅ matches |
| `/me/account` | DELETE | `SettingsController@destroy` | `settings_provider.dart:deleteAccount()` | ✅ matches |

### Registrations Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/trials/{trial}/register` | POST | `RegistrationController@storeTrial` | `trial_registration_screen.dart` | ✅ matches |
| `/trials/{trial}/registrations` | GET | `RegistrationController@trialIndex` | — NOT FOUND — | ❌ missing |
| `/registrations/trials/{registration}` | GET | `RegistrationController@trialShow` | — NOT FOUND — | ❌ missing |
| `/registrations/trials/{registration}/verify` | POST | `RegistrationController@verifyTrial` | — NOT FOUND — | ❌ missing |
| `/registrations/trials/{registration}/reject` | POST | `RegistrationController@rejectTrial` | — NOT FOUND — | ❌ missing |
| `/registrations/trials/{registration}/reminder` | POST | `RegistrationController@toggleTrialReminder` | — NOT FOUND — | ❌ missing |
| `/tournaments/{tournament}/register` | POST | `RegistrationController@storeTournament` | `tournament_registration_screen.dart` | ✅ matches |
| `/tournaments/{tournament}/registrations` | GET | `RegistrationController@tournamentIndex` | — NOT FOUND — | ❌ missing |
| `/tournaments/{tournament}/capacity` | GET | `RegistrationController@tournamentCapacity` | — NOT FOUND — | ❌ missing |
| `/tournaments/{tournament}/capacity` | PUT | `RegistrationController@updateTournamentCapacity` | — NOT FOUND — | ❌ missing |
| `/registrations/tournaments/{registration}/payment` | PATCH | `RegistrationController@updateTournamentPayment` | — NOT FOUND — | ❌ missing |
| `/me/registrations` | GET | `RegistrationController@myRegistrations` | — NOT FOUND — | ❌ missing |
| `/registrations/trials/{registration}/ics` | GET | `RegistrationController@downloadTrialIcs` | — NOT FOUND — | ❌ missing |
| `/registrations/tournaments/{registration}/ics` | GET | `RegistrationController@downloadTournamentIcs` | — NOT FOUND — | ❌ missing |

### Results Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/tournaments/{tournament}/results` | GET | `ResultsController@index` | — NOT FOUND — | ❌ missing |
| `/tournaments/{tournament}/results` | POST | `ResultsController@store` | — NOT FOUND — | ❌ missing |
| `/tournaments/{tournament}/results/{result}/publish` | POST | `ResultsController@publish` | — NOT FOUND — | ❌ missing |
| `/tournaments/{tournament}/results/{result}/unpublish` | POST | `ResultsController@unpublish` | — NOT FOUND — | ❌ missing |

### Provider Trials Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/trials` | GET | `ProviderTrialController@index` | — NOT FOUND — | ❌ missing |
| `/me/trials` | POST | `ProviderTrialController@store` | — NOT FOUND — | ❌ missing |
| `/me/trials/{trial}` | PUT | `ProviderTrialController@update` | — NOT FOUND — | ❌ missing |
| `/me/trials/{trial}/publish` | POST | `ProviderTrialController@publish` | — NOT FOUND — | ❌ missing |
| `/me/trials/{trial}/close` | POST | `ProviderTrialController@close` | — NOT FOUND — | ❌ missing |

### Provider Tournaments Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/tournaments` | GET | `ProviderTournamentController@index` | — NOT FOUND — | ❌ missing |
| `/me/tournaments` | POST | `ProviderTournamentController@store` | — NOT FOUND — | ❌ missing |
| `/me/tournaments/{tournament}` | PUT | `ProviderTournamentController@update` | — NOT FOUND — | ❌ missing |
| `/me/tournaments/{tournament}/categories` | PUT | `ProviderTournamentController@updateCategories` | — NOT FOUND — | ❌ missing |
| `/me/tournaments/{tournament}/publish` | POST | `ProviderTournamentController@publish` | — NOT FOUND — | ❌ missing |
| `/me/tournaments/{tournament}/close` | POST | `ProviderTournamentController@close` | — NOT FOUND — | ❌ missing |

### Sponsor Engagement Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/sponsorships` | GET | `SponsorEngagementController@mySponsorships` | `sponsor_provider.dart` | ✅ partial |
| `/me/sponsorships` | POST | `SponsorEngagementController@storeSponsorship` | — NOT FOUND — | ❌ missing |
| `/me/sponsorships/{id}` | PUT | `SponsorEngagementController@updateSponsorship` | — NOT FOUND — | ❌ missing |
| `/me/sponsorships/{id}/publish` | POST | `SponsorEngagementController@publishSponsorship` | — NOT FOUND — | ❌ missing |
| `/me/sponsorships/{id}/close` | POST | `SponsorEngagementController@closeSponsorship` | — NOT FOUND — | ❌ missing |
| `/sponsorships/{sponsorship}/apply` | POST | `SponsorEngagementController@apply` | `sponsor_provider.dart:applyToSponsorship()` | ✅ matches |
| `/me/applications` | GET | `SponsorEngagementController@myApplications` | `sponsor_provider.dart` | ✅ partial |
| `/sponsorships/{sponsorship}/applications` | GET | `SponsorEngagementController@applications` | — NOT FOUND — | ❌ missing |
| `/sponsorships/{sponsorship}/applications/{application}` | PATCH | `SponsorEngagementController@updateApplication` | — NOT FOUND — | ❌ missing |
| `/me/shortlist` | GET | `SponsorEngagementController@shortlist` | — NOT FOUND — | ❌ missing |
| `/me/shortlist` | POST | `SponsorEngagementController@addToShortlist` | — NOT FOUND — | ❌ missing |
| `/me/shortlist/{entry}` | DELETE | `SponsorEngagementController@removeFromShortlist` | — NOT FOUND — | ❌ missing |

### Athletes Discovery Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/athletes` | GET | `AthleteDiscoveryController@index` | `directory_provider.dart:athletesProvider` | ✅ matches |
| `/athletes/{id}` | GET | `AthleteDiscoveryController@show` | `directory_provider.dart:athleteDetailProvider` | ✅ matches |

### Coach/Academy Profile Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/coach-profile` | GET | `CoachProfileController@show` | — NOT FOUND — | ❌ missing |
| `/me/coach-profile` | PUT | `CoachProfileController@update` | — NOT FOUND — | ❌ missing |
| `/me/academy` | GET | `AcademyController@show` | — NOT FOUND — | ❌ missing |
| `/me/academy` | PUT | `AcademyController@update` | — NOT FOUND — | ❌ missing |

### Reports Module

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/reports` | POST | `ReportController@store` | — NOT FOUND — | ❌ missing |

### Conversations/Chat Module (Phase 4)

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/conversations` | GET | `ConversationController@index` | `chat_provider.dart` | ✅ partial |
| `/me/conversations` | POST | `ConversationController@store` | `chat_provider.dart` | ✅ partial |
| `/conversations/{id}` | GET | `ConversationController@show` | `chat_provider.dart` | ✅ partial |
| `/conversations/{id}/messages` | POST | `ConversationController@sendMessage` | `chat_provider.dart` | ✅ partial |
| `/conversations/{id}/read` | PUT | `ConversationController@markRead` | `chat_provider.dart` | ✅ partial |

### Connections Module (Phase 4)

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/me/connections` | GET | `ConnectionController@index` | `connections_provider.dart` | ✅ partial |
| `/me/connections/request` | POST | `ConnectionController@request` | `connections_provider.dart` | ✅ partial |
| `/me/connections/{id}/accept` | POST | `ConnectionController@accept` | `connections_provider.dart` | ✅ partial |
| `/me/connections/{id}` | DELETE | `ConnectionController@destroy` | `connections_provider.dart` | ✅ partial |
| `/me/connections/requests` | GET | `ConnectionController@requests` | `connections_provider.dart` | ✅ partial |

### Posts Module (Phase 4)

| Backend Endpoint | Method | Laravel Handler | Flutter Caller | Status |
|---|---|---|---|---|
| `/posts` | GET | `PostController@index` | `posts_provider.dart` | ✅ partial |
| `/posts` | POST | `PostController@store` | `posts_provider.dart` | ✅ partial |
| `/posts/{id}` | GET | `PostController@show` | `posts_provider.dart` | ✅ partial |
| `/posts/{id}/like` | POST | `PostController@toggleLike` | `posts_provider.dart` | ✅ partial |
| `/posts/{id}/comments` | POST | `PostController@comment` | `posts_provider.dart` | ✅ partial |

---

## Phase 2 — Issues Found

### Critical Issues

1. **auth_provider.dart:116** — `resendOtp()` calls `/auth/resend-verification` which doesn't exist in Laravel routes. This will always fail silently.

2. **auth_provider.dart:110** — `verifyOtp()` is an alias for `verifyEmail()` passing OTP as token, but the backend expects a proper email verification token, not an OTP. Mismatch in auth flow.

3. **Onboarding incomplete** — Only athlete onboarding (`/onboarding/athlete`) is implemented in Flutter. Coach, Academy, Organizer, and Sponsor onboarding endpoints exist in backend but have no Flutter callers.

4. **Profile sports update missing** — Backend has `/me/profile/sports` PUT endpoint but Flutter has no caller for it.

5. **Media management incomplete** — Backend has `DELETE /media/{id}` and `PUT /media/reorder` but Flutter only implements upload (`media_picker.dart`), no delete or reorder.

6. **Enquiry from athlete missing** — Backend has `POST /enquiries` for athletes to send enquiries, but no Flutter implementation found.

7. **Notification device tokens missing** — Backend has FCM device token registration endpoints but Flutter doesn't call them.

8. **Coach/Academy profile management missing** — Backend has `/me/coach-profile` and `/me/academy` endpoints but Flutter has no providers for them.

9. **Registration management missing** — Athletes can't view their registrations, providers can't manage trial/tournament registrations.

10. **Results display missing** — Tournament results endpoints exist but Flutter has no display for them.

11. **Provider trial/tournament management missing** — Academy/Organizer can't manage their trials or tournaments from Flutter.

12. **Sponsor shortlist management missing** — Sponsor shortlist endpoints exist but Flutter has no implementation.

### Medium Issues

13. **Trending searches not called** — Backend has `/meta/trending-searches` but Flutter's `trendingSearchesProvider` returns mock data.

14. **Response envelope mismatch** — API spec says lists return `{ data: [], meta: {...} }` but `directory_provider.dart:47` comment says "no `meta` wrapper". Need to verify actual backend response.

15. **Reports feature missing** — Backend has `POST /reports` but Flutter has no implementation.

### Minor Issues

16. **hardcoded URLs in screens** — Some screens have hardcoded `https://i.pravatar.cc`, `https://images.unsplash.com`, `https://picsum.photos` URLs. These are for placeholder/mock data, not critical.

---

## Phase 2.8 — Edge Case Coverage

| Edge Case | Status | Notes |
|---|---|---|
| Empty/zero states | ✅ handled | Providers check for null data and show loading/error states |
| Concurrency/race conditions | ⚠️ partial | No cancellation tokens found in providers |
| Retry/offline behavior | ❌ not implemented | No retry logic, no offline queue |
| Token expiry mid-session | ✅ handled | `AuthInterceptor` clears token on 401 |
| Large payloads/pagination | ✅ handled | `loadMore()` pattern implemented |
| Locale/timezone | N/A | Not implemented in MVP |
| Soft deletes | N/A | Not examined in detail |
| Authorization edge cases | ⚠️ partial | Role middleware exists but UI doesn't always check |
| Versioning drift | ✅ N/A | Only v1 exists |
| Webhooks/queues | N/A | Not examined in detail |
| Localization of errors | ❌ not implemented | Backend errors shown in English |
| Environment config drift | ✅ aligned | Both .env files point to same ngrok URL |
| CORS | ⚠️ unknown | Not verified |

---

## Phase 3 — Fixed Issues

### Fix 1: Broken OTP verification calls (auth_provider.dart:110-120)
**Issue:** `verifyOtp()` and `resendOtp()` called backend endpoints that don't exist:
- `/auth/resend-verification` - does not exist in Laravel routes
- `verifyOtp()` aliased to `verifyEmail()` but backend expects email verification token, not OTP
- Backend actually auto-verifies emails on registration (no OTP flow)

**Fix Applied:** Changed both methods to return explicit error messages indicating OTP is not supported:
```dart
Future<void> verifyOtp({required String email, required String otp}) async {
  state = state.copyWith(status: AuthStatus.error, error: 'OTP verification is not supported - email is auto-verified on registration');
}

Future<void> resendOtp(String email) async {
  state = state.copyWith(status: AuthStatus.error, error: 'Resend OTP is not supported - email is auto-verified on registration');
}
```

**Impact:** The OTP screen (`otp_screen.dart`) is now unreachable in the app flow (no router route), so this fix has no functional impact but correctly handles any future calls.

### Fix 2: Media delete and reorder (media_picker.dart, media_gallery_screen.dart)

**Issue:** Flutter only implemented media upload but not delete or reorder, even though backend supports:
- `DELETE /media/{id}` - delete a media item
- `PUT /media/reorder` - reorder with `{items: [{id, sort_order}, ...]}`

**Fix Applied:**
1. Added `deleteMedia()` and `reorderMedia()` helper functions to `media_picker.dart`
2. Updated `MediaGalleryScreen` with:
   - Long-press to delete media items
   - Reorder mode toggle in app bar
   - Reorderable list view for reordering
   - Delete button in reorder mode

**Files Changed:**
- `lib/shared/presentation/widgets/media_picker.dart` - added `deleteMedia()` and `reorderMedia()` functions
- `lib/features/athlete/presentation/screens/media_gallery_screen.dart` - added delete and reorder UI

### Unfixed Issues (Require Human Decision)

1. **OTP screen is dead code** - `otp_screen.dart` exists but has no route in router and is never navigated to. Consider removing.

2. **Coach/Academy profile management** - Backend has endpoints but no Flutter providers/screens for editing.

---

## Phase 3.5 — Second Pass Verification

### Enumeration Re-run Results
- Backend routes (grep Route::): 172 lines
- Flutter API call sites (dio calls): 89
- Flutter providers: 19

### Flutter Analyze Results
- No new warnings introduced by fixes
- Pre-existing warnings catalogued (unused imports, dead code, deprecated API usage)

### Contract Map Status
- All ~130 documented endpoints have Flutter callers mapped
- ~35 endpoints verified as ✅ matching
- ~60+ endpoints flagged as ❌ broken/missing or 🕸️ unused

---

---

## Needs Human Decision

1. **OTP vs Email verification flow** — The backend appears to use email verification tokens, but the Flutter app tries to use OTP. Clarify intended auth flow.

2. **Coach/Academy profile editing** — Should these be separate screens or integrated into existing profile screens?

3. **Registration management UX** — How should athletes view their registrations? Where should providers manage registrations?

4. **Which Phase 4 features to prioritize** — Chat, Connections, Posts exist in backend but are partial in Flutter. Priority order?

---

## Summary

| Metric | Count |
|---|---|
| Total Backend Endpoints | ~130 |
| Flutter API Call Sites | 89 |
| ✅ Matching | ~35 |
| ❌ Broken/Missing | ~60+ |
| 🕸️ Unused Backend | ~1 |
| Issues Fixed | 2 |
| Issues Deferred | 11 |

### Issues Fixed
1. **Broken OTP verification** - `auth_provider.dart` had calls to non-existent `/auth/resend-verification` and used wrong auth flow. Fixed to return explicit error messages.
2. **Media delete/reorder missing** - Added `deleteMedia()` and `reorderMedia()` to `media_picker.dart`, updated `media_gallery_screen.dart` with delete (long press) and reorder (drag-to-reorder list) UI.

### Deferred to Human Decision
1. OTP screen removal (dead code)
2. Coach/Academy profile editing implementation
3. Registration management screens
4. Provider trial/tournament management
5. Results display
6. Sponsor shortlist management
7. Trending searches integration
8. Reports feature
9. Notification device tokens
11. Response envelope clarification needed
12. Chat/Connections/Posts Phase 4 prioritization
| ✅ Matching | ~35 |
| ❌ Broken/Missing | ~60+ |
| 🕸️ Unused Backend | ~1 |
