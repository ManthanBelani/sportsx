# SportX India — Complete User App Build Plan

This document lists every step needed to build the complete SportX India Flutter app for all user roles. The app already has **scaffold screens** for ~110 dart files — the work is about refining, wiring to the real backend API, and making each screen fully functional.

---

## Current State Summary

| Metric | Value |
|---|---|
| Total dart files in `lib/` | ~115 |
| Routes registered in `router.dart` | ~85 routes |
| Feature modules | 18 (auth, onboarding, home, athlete, coach, academy, organizer, sponsor, admin, search, saved, shared, notifications, settings, connections, chat, social, scholarship, sports_venue) |
| Status | All screens exist as UI shells; need API wiring, state management completion, form validation, edge cases, and production polish |
| Backend | Laravel API exists at `sportx-api/` |

---

## Phase 1 — Foundation & API Wiring (Weeks 1-3)

### Step 1.1: Core Infrastructure Hardening

| # | Task | File(s) | Details |
|---|---|---|---|
| 1 | **API Client — add interceptors** | `core/utils/api_client.dart` | Add Dio auth token interceptor (auto-attach Bearer), 401 refresh/logout handler, retry on 503, request/response logging toggle, timeout config (connect: 10s, receive: 30s) |
| 2 | **Storage Service — token persistence** | `core/utils/storage_service.dart` | Store JWT access/refresh tokens, user role, onboarding completion flag using `flutter_secure_storage` |
| 3 | **Environment config** | `.env`, `core/config/api_config.dart` | Ensure `API_BASE_URL`, `ENV` (dev/staging/prod) loaded from `.env`; add staging/prod endpoint support |
| 4 | **Error handling utilities** | `core/utils/` (new `error_handler.dart`) | Centralize API error parsing — map HTTP status codes to user-friendly messages, create `AppException` hierarchy (Network, Auth, Server, Validation) |
| 5 | **Loading state widget** | `shared/presentation/widgets/async_state_view.dart` | Enhance to handle loading, error (with retry), empty, and success states per screen |

### Step 1.2: Auth System — Full E2E Wiring

| # | Task | File(s) | Details |
|---|---|---|---|
| 6 | **Auth provider — full implementation** | `features/auth/presentation/providers/auth_provider.dart` | Wire `register()`, `verifyOtp()`, `login()`, `logout()`, `forgotPassword()`, `resetPassword()` to backend endpoints. Add token persistence and auto-login on app restart |
| 7 | **Splash screen — auto-redirect logic** | `features/auth/presentation/screens/splash_screen.dart` | Check stored token → validate → redirect to `/home` or `/role-selection` based on auth state |
| 8 | **Role selection — pass role to sign-up** | `features/auth/presentation/screens/role_selection_screen.dart` | Ensure role is correctly passed as `extra` to sign-up screen for all 5 roles |
| 9 | **Sign up screen — phone/email toggle, validation** | `features/auth/presentation/screens/sign_up_screen.dart` | Add form validation (phone: 10 digits, email: valid format), terms checkbox enforcement, Google sign-in placeholder, loading states |
| 10 | **OTP screen — countdown timer, resend** | `features/auth/presentation/screens/otp_screen.dart` | Implement 30s countdown, resend OTP button enable/disable, auto-verify on complete, error state for wrong OTP |
| 11 | **Login screen — validation, error display** | `features/auth/presentation/screens/login_screen.dart` | Add password/OTP toggle, input validation, "forgot password" link, error snackbar on failed login |
| 12 | **Forgot password screen** | New file or extend login_screen | "Enter email → receive reset link → redirect to reset password" flow |
| 13 | **Reset password screen** | New file or extend login_screen | New password + confirm password fields, strength indicator, success redirect |

### Step 1.3: Models — Ensure All Models Match API Response

| # | Task | File(s) | Details |
|---|---|---|---|
| 14 | **User model** | `shared/models/user.dart` | Ensure matches backend JSON — id, name, email, phone, role, profilePhoto, sport, city, ageGroup, skillLevel, dateOfBirth, gender, academy, coach, position, experience, achievements, videos, certificates, ranking, verification, createdAt |
| 15 | **Academy model** | `shared/models/academy.dart` | All fields per Mandatory Fields doc: name, sportsOffered, address, city, contactNumber, googleMapsLocation, description, logo, coverPhoto, email, website, headCoach, yearEstablished, ageGroups, trainingTimings, fees, facilities, achievements, photos, verificationBadge |
| 16 | **Coach model** | `shared/models/coach.dart` | All fields: fullName, sport, city, contactNumber, experience, profilePhoto, qualification, certifications, academy, languages, email, personalCoaching, fees, achievements, rating, verification |
| 17 | **Trial model** | `shared/models/trial.dart` | All fields: trialName, organization, sport, date, venue, googleMaps, contactNumber, registrationDeadline, eligibility, requiredDocuments, vacancies, benefits, registrationFee, status, verification |
| 18 | **Tournament model** | `shared/models/tournament.dart` | All fields: tournamentName, sport, organizer, tournamentDates, registrationDeadline, venue, googleMaps, entryFee, contactNumber, registrationLink, banner, ageCategory, gender, prizePool, rules, fixtures, results, photos, status, verification |
| 19 | **Scholarship model** | `shared/models/scholarship.dart` | All fields: organizationName, name, sport, eligibility, lastDate, applicationLink, contactEmail, logo, benefits, amount, documentsRequired, description, verification |
| 20 | **Sponsorship model** | `shared/models/sponsorship.dart` | All fields: organizationName, name, sport, eligibility, lastDate, applicationLink, contactEmail, logo, benefits, amount, documentsRequired, description, verification |
| 21 | **SportsVenue model** | `shared/models/sports_venue.dart` | All fields: venueName, sport, address, googleMaps, contactNumber, photos, bookingAvailable, pricing, facilities, workingHours, rating, verification |
| 22 | **Sport, City, AgeGroup meta models** | `shared/models/sport.dart`, `city.dart`, `age_group.dart` | Ensure fromJSON/toJSON match master data API response |
| 23 | **Missing models — create** | New files as needed | Add: `Enquiry`, `Registration`, `Notification`, `Report`, `SavedItem`, `Connection`, `ChatThread`, `ChatMessage`, `Post`, `Application` models with full serialization |

### Step 1.4: Meta Data Provider

| # | Task | File(s) | Details |
|---|---|---|---|
| 24 | **Meta provider — sports, cities, age groups** | `shared/providers/meta_provider.dart` | Fetch from `/api/meta/sports`, `/api/meta/cities`, `/api/meta/age-groups`. Cache locally. Provide dropdown-ready lists. Add `refetch()` capability for admin changes |

---

## Phase 2 — Athlete / Parent App (Weeks 3-5)

### Step 2.1: Onboarding Flow

| # | Task | File(s) | Details |
|---|---|---|---|
| 25 | **Onboarding Step 1 — Sport & Age Group** | `features/onboarding/presentation/screens/onboarding_sport_age_screen.dart` | Wire to meta provider for sport chips. Multi-select sports. Age group radio buttons. Validate at least 1 sport selected. Pass data to step 2 |
| 26 | **Onboarding Step 2 — Skill & Location** | `features/onboarding/presentation/screens/onboarding_skill_location_screen.dart` | Skill level selector (Beginner/Intermediate/Advanced/Competitive). City autocomplete from meta provider. Submit to `POST /api/onboarding/athlete`. Mark `needsOnboarding = false` on success. Navigate to `/home` |
| 27 | **Onboarding provider** | `features/onboarding/presentation/providers/onboarding_provider.dart` | Store onboarding state (sports, ageGroup, skillLevel, city). Submit to API. Handle errors |

### Step 2.2: Home Dashboard

| # | Task | File(s) | Details |
|---|---|---|---|
| 28 | **Home screen — personalized content** | `features/home/presentation/screens/home_screen.dart` | Fetch recommended academies, trials closing soon, upcoming saved tournaments, new scholarships from API. Display in horizontal scroll cards. Pull-to-refresh. Empty state when no data |
| 29 | **Home screen — quick search bar** | Same file | Tappable search bar → navigates to `/universal-search`. Show recent search queries (stored locally) |
| 30 | **Home screen — sport category chips** | Same file | Horizontal scrollable sport chips from meta provider. Tapping a chip filters home content by that sport |

### Step 2.3: Athlete Profile

| # | Task | File(s) | Details |
|---|---|---|---|
| 31 | **Profile screen (view)** | `features/athlete/presentation/screens/profile_screen.dart` | Display: photo, name, sport(s), age group, city, skill level, achievements list, media gallery preview (3 items + "See all"). Edit profile button. Share profile button |
| 32 | **Edit profile screen** | `features/athlete/presentation/screens/edit_profile_screen.dart` | Editable fields: name, sport(s), age group, skill level, city, DOB, gender, position, experience. Photo change (camera/gallery). Save to `PUT /api/athlete/profile`. Show success feedback |
| 33 | **Add achievement screen** | `features/athlete/presentation/screens/add_achievement_screen.dart` | Form: title, date, description, certificate upload. `POST /api/athlete/achievements`. Return to edit profile |
| 34 | **Media gallery manager** | `features/athlete/presentation/screens/media_gallery_screen.dart` | Grid of photos/videos. Upload button (camera/gallery). Delete with confirmation. Drag-to-reorder. `POST/DELETE /api/athlete/media` |

### Step 2.4: Search & Discovery

| # | Task | File(s) | Details |
|---|---|---|---|
| 35 | **Universal search screen** | `features/search/presentation/screens/universal_search_screen.dart` | Search bar with debounce. Recent searches (local storage). Trending sport chips. Results page with category tabs (Academies/Coaches/Trials/Tournaments/Scholarships/Sponsorships/Venues). Each tab fetches from `GET /api/search?q=...&type=...` |
| 36 | **Search filter screen** | `features/search/presentation/screens/search_filter_screen.dart` | Filter by sport, city/state, age group, price range (slider), date range. Apply filters → pass back to search results. Persist last-used filters |
| 37 | **Search provider** | `features/search/presentation/providers/search_provider.dart` | Manage query state, active filters, results per category, pagination (load more), recent searches |

### Step 2.5: Directory Screens (All use T1/T2 Templates)

| # | Task | File(s) | Details |
|---|---|---|---|
| 38 | **Directory list template** | `shared/presentation/widgets/directory_list_template.dart` | Generic: accepts `ListingType`, fetches paginated list, renders cards. Pull-to-refresh, search within list, load-more pagination, empty state, shimmer loading skeleton |
| 39 | **Detail page template** | `shared/presentation/widgets/detail_page_template.dart` | Generic: hero image, title, subtitle, detail sections (dynamic), save/bookmark button, report button, primary CTA button. Map preview for location |
| 40 | **Academy directory** | `features/academy/presentation/screens/academy_directory_screen.dart` | Wire to `GET /api/academies`. Card: photo, name, sport, city, fee range. Tap → detail |
| 41 | **Academy detail** | `features/academy/presentation/screens/academy_detail_screen.dart` | Full info: facilities, coaches list, age groups, timings, fees, photos, location map. CTA: "Enquire". Save button |
| 42 | **Coach directory** | `features/coach/presentation/screens/coach_directory_screen.dart` | Wire to `GET /api/coaches`. Card: photo, name, sport, experience, fee |
| 43 | **Coach detail** | `features/coach/presentation/screens/coach_detail_screen.dart` | Full info: qualifications, certifications, experience, sport, fee structure, location. CTA: "Enquire / Book Session" |
| 44 | **Trial directory** | `features/trial/presentation/screens/trial_directory_screen.dart` | Wire to `GET /api/trials`. Card: sport, date, venue, organizer, entry fee |
| 45 | **Trial detail** | `features/trial/presentation/screens/trial_detail_screen.dart` | Full info: eligibility, required docs, entry fee, contact. CTA: "Register for Trial" |
| 46 | **Tournament directory** | `features/tournament/presentation/screens/tournament_directory_screen.dart` | Wire to `GET /api/tournaments`. Calendar/list toggle view. Card: banner, name, format, dates, venue, prize pool |
| 47 | **Tournament detail** | `features/tournament/presentation/screens/tournament_detail_screen.dart` | Full info: format, dates, venue, prize pool, categories, rules. CTA: "Register" |
| 48 | **Scholarship list** | `features/scholarship/presentation/screens/scholarship_list_screen.dart` | Wire to `GET /api/scholarships`. Card: provider, sport, amount, deadline |
| 49 | **Sports venue directory** | `features/sports_venue/presentation/screens/sports_venue_list_screen.dart` | Wire to `GET /api/sports-venues`. Card: photo, name, sport, city, rating |
| 50 | **Sponsorship directory** | Via search or home | Wire to `GET /api/sponsorships`. Card: sponsor, sport, eligibility, benefits, deadline |

### Step 2.6: Actions (Athlete)

| # | Task | File(s) | Details |
|---|---|---|---|
| 51 | **Enquire form (coach/academy)** | `shared/presentation/screens/enquire_screen.dart` | Pre-fill athlete name/sport. Message box, preferred date/time picker. `POST /api/enquiries`. Show confirmation |
| 52 | **Trial registration form** | `features/trial/presentation/screens/trial_registration_screen.dart` | Pre-fill profile data. Upload required documents (ID, photo). Payment note (if applicable). `POST /api/trials/:id/register`. Navigate to confirmation |
| 53 | **Registration confirmation** | `shared/presentation/screens/registration_confirmation_screen.dart` | Display: event name, date, venue, registration ID. "Add to calendar" (.ics export). "Remind me" toggle → subscribe to notification |
| 54 | **Tournament registration form** | `features/tournament/presentation/screens/tournament_registration_screen.dart` | Category selection, team/individual toggle, personal details pre-fill. `POST /api/tournaments/:id/register` |
| 55 | **Sponsor pitch form** | `shared/presentation/screens/sponsor_pitch_screen.dart` | Auto-attach athlete profile. Pitch note text box. `POST /api/sponsorships/:id/apply`. Show confirmation |
| 56 | **Activity hub** | `shared/presentation/screens/activity_hub_screen.dart` | Tabs: Trials, Tournaments, Sponsorships. Each item shows name, date, status (Pending/Confirmed/Rejected). Pull-to-refresh. Empty state per tab |

### Step 2.7: Saved & Notifications

| # | Task | File(s) | Details |
|---|---|---|---|
| 57 | **Saved items screen** | `features/saved/presentation/screens/saved_screen.dart` | Tabs: All, Academies, Trials, Tournaments, Scholarships. Delete/unsave. Empty state. Wire to `GET /api/saved` |
| 58 | **Save provider** | `features/saved/presentation/providers/saved_provider.dart` | Optimistic save/unsave toggle. Sync with API. Handle conflict resolution |
| 59 | **Notifications screen** | `features/notifications/presentation/screens/notifications_screen.dart` | List: reminder (trial date approaching), enquiry reply, registration status change, scholarship deadline. Tap → navigate to relevant screen. Mark as read. `GET /api/notifications` |
| 60 | **Notifications provider** | `features/notifications/presentation/providers/notifications_provider.dart` | Fetch notifications, unread count badge, mark-read, subscribe to push notification topics |

### Step 2.8: Report & Settings

| # | Task | File(s) | Details |
|---|---|---|---|
| 61 | **Report modal** | Shared widget on all detail pages | Reason dropdown (Fake/Scam, Outdated, Inappropriate, Other). Optional comment. `POST /api/reports`. Success feedback |
| 62 | **Settings screen** | `features/settings/presentation/screens/settings_screen.dart` | Edit profile link, change password, notification preferences toggle, language selector (English), logout, delete account with confirmation dialog |
| 63 | **Help/Support screen** | `features/settings/presentation/screens/help_support_screen.dart` | FAQ list (searchable), "Contact Support" button → email or in-app form |

---

## Phase 3 — Coach App (Weeks 5-6)

### Step 3.1: Coach Onboarding & Profile

| # | Task | File(s) | Details |
|---|---|---|---|
| 64 | **Coach onboarding** | `features/coach/presentation/screens/coach_onboarding_screen.dart` | Multi-step: sport(s) coached, certifications, years of experience. `POST /api/onboarding/coach` |
| 65 | **Coach profile posting** | `features/coach/presentation/screens/coach_profile_posting_screen.dart` | Create/edit listing: photo, name, sport(s), certifications, experience, fee structure, location, bio. `POST/PUT /api/coach/profile` |
| 66 | **Coach dashboard** | `features/coach/presentation/screens/coach_dashboard_screen.dart` | Profile completeness meter, new enquiries count card, quick action buttons (Edit Listing, Browse App) |
| 67 | **Coach provider** | `features/coach/presentation/providers/coach_provider.dart` | Manage coach profile state, enquiry list, CRUD operations |

### Step 3.2: Coach Enquiry Management

| # | Task | File(s) | Details |
|---|---|---|---|
| 68 | **Enquiry inbox** | `shared/presentation/screens/enquiry_inbox_screen.dart` | Tabs: All, New, Replied. List: athlete name, sport, enquiry preview, timestamp, status dot (blue=new). `GET /api/coach/enquiries` |
| 69 | **Enquiry detail + reply** | `shared/presentation/screens/enquiry_detail_screen.dart` | Message thread view. Reply box. Send reply → `POST /api/coach/enquiries/:id/reply`. Update status to "Replied" |
| 70 | **Enquiry provider** | `shared/providers/enquiry_provider.dart` | Fetch enquiries, filter by status, reply to enquiry, mark as read |

### Step 3.3: Coach Extra Features

| # | Task | File(s) | Details |
|---|---|---|---|
| 71 | **Add credential screen** | `features/coach/presentation/screens/add_credential_screen.dart` | Upload certification images, add title, issuing body, year. `POST /api/coach/credentials` |
| 72 | **Edit facilities screen** | `features/coach/presentation/screens/edit_facilities_screen.dart` | Toggle facilities on/off (turf, nets, gym, video analysis). `PUT /api/coach/facilities` |
| 73 | **Showcase athletes screen** | `features/coach/presentation/screens/showcase_athletes_screen.dart` | List of athletes coached. Add/remove. `GET/POST/DELETE /api/coach/athletes` |
| 74 | **Coach profile detail (public view)** | `features/coach/presentation/screens/coach_profile_detail_screen.dart` | Read-only view of coach profile for other users. Different from own profile editing |

---

## Phase 4 — Academy App (Weeks 6-7)

### Step 4.1: Academy Onboarding & Profile

| # | Task | File(s) | Details |
|---|---|---|---|
| 75 | **Academy onboarding** | `features/academy/presentation/screens/academy_onboarding_screen.dart` | Multi-step: academy name, sport(s), city. `POST /api/onboarding/academy` |
| 76 | **Academy profile posting** | `features/academy/presentation/screens/academy_profile_posting_screen.dart` | Create/edit: cover photo, name, sport(s), facilities, fee range, age groups, timings, coaches, photos. `POST/PUT /api/academy/profile` |
| 77 | **Academy dashboard** | `features/academy/presentation/screens/academy_dashboard_screen.dart` | Active trials count, pending enquiries count, recent registrants list. Quick action: "Post New Trial" |
| 78 | **Academy provider** | `features/academy/presentation/providers/academy_provider.dart` | Manage academy profile, trials list, enquiry list, registrant lists |

### Step 4.2: Academy Trial Management

| # | Task | File(s) | Details |
|---|---|---|---|
| 79 | **Trial posting form** | `features/academy/presentation/screens/trial_posting_screen.dart` | Create/edit: trial name, sport, date/time, venue, eligibility, entry fee, required docs, contact. Draft/Published status. `POST/PUT /api/academy/trials` |
| 80 | **My trials management** | `shared/presentation/screens/my_trials_management_screen.dart` | List of posted trials. Status (Draft/Published/Closed). Actions: Edit, Publish, Close. `GET /api/academy/trials` |
| 81 | **Registrant list** | `shared/presentation/screens/registrant_list_screen.dart` | Per trial: list of registered athletes. Name, contact, documents status (submitted/pending). Capacity indicator. `GET /api/academy/trials/:id/registrants` |
| 82 | **Registrant detail** | `shared/presentation/screens/registrant_detail_screen.dart` | Athlete profile snapshot. Document viewer (tap to open). Actions: Mark Verified, Reject. `PUT /api/academy/trials/:id/registrants/:id` |
| 83 | **Academy enquiry inbox** | Reuses `enquiry_inbox_screen.dart` + `enquiry_detail_screen.dart` | Same pattern as coach. `GET /api/academy/enquiries` |

---

## Phase 5 — Organizer App (Weeks 7-8)

### Step 5.1: Organizer Onboarding & Dashboard

| # | Task | File(s) | Details |
|---|---|---|---|
| 84 | **Organizer onboarding** | `features/organizer/presentation/screens/organizer_onboarding_screen.dart` | Organization name, type (Federation/Club/Other), verification docs upload. `POST /api/onboarding/organizer` |
| 85 | **Organizer dashboard** | `features/organizer/presentation/screens/organizer_dashboard_screen.dart` | Active trials/tournaments count, upcoming registration deadlines, quick action buttons (Post Trial, Post Tournament) |
| 86 | **Organizer provider** | `features/organizer/presentation/providers/organizer_provider.dart` | Manage organizer profile, trials, tournaments, registrations |

### Step 5.2: Organizer Trial Management

| # | Task | File(s) | Details |
|---|---|---|---|
| 87 | **Trial create/edit** | Reuses `trial_posting_screen.dart` or organizer-specific | Same form fields. `POST/PUT /api/organizer/trials` |
| 88 | **My trials management** | `shared/presentation/screens/my_trials_management_screen.dart` | Same pattern as academy. `GET /api/organizer/trials` |

### Step 5.3: Organizer Tournament Management

| # | Task | File(s) | Details |
|---|---|---|---|
| 89 | **Tournament posting form** | `features/organizer/presentation/screens/tournament_posting_screen.dart` | Create/edit: name, format (Knockout/League/Groups), dates, venue, entry fee, prize pool, categories, rules. Draft/Published. `POST/PUT /api/organizer/tournaments` |
| 90 | **My tournaments management** | `shared/presentation/screens/my_tournaments_management_screen.dart` | List of posted tournaments. Status, edit/publish/close. `GET /api/organizer/tournaments` |
| 91 | **Registration management** | `features/organizer/presentation/screens/registration_management_screen.dart` | Per tournament: tabs per category. List: team/player name, category, payment status. Capacity meter. `GET /api/organizer/tournaments/:id/registrations` |
| 92 | **Capacity/spot management** | `features/organizer/presentation/screens/capacity_management_screen.dart` | Per category: spots slider/input, filled count, waitlist toggle. `PUT /api/organizer/tournaments/:id/capacity` |
| 93 | **Results publishing** | `features/organizer/presentation/screens/results_publishing_screen.dart` | Category selector. Winner/Runner-up/3rd place inputs. Bracket image upload. `POST /api/organizer/tournaments/:id/results` |
| 94 | **Results view (public)** | `features/organizer/presentation/screens/results_view_screen.dart` | Bracket visualization or ranked results list. `GET /api/tournaments/:id/results` |

---

## Phase 6 — Sponsor / Brand App (Weeks 8-9)

### Step 6.1: Sponsor Onboarding & Dashboard

| # | Task | File(s) | Details |
|---|---|---|---|
| 95 | **Sponsor onboarding** | `features/sponsor/presentation/screens/sponsor_onboarding_screen.dart` | Brand name, logo upload, category, verification docs. `POST /api/onboarding/sponsor` |
| 96 | **Sponsor dashboard** | `features/sponsor/presentation/screens/sponsor_dashboard_screen.dart` | Active listings count, new applications count. Recent applications preview. Quick action: "Post Sponsorship" |
| 97 | **Sponsor provider** | `features/sponsor/presentation/providers/sponsor_provider.dart` | Manage sponsor profile, listings, applications, shortlist |

### Step 6.2: Sponsorship Management

| # | Task | File(s) | Details |
|---|---|---|---|
| 98 | **Sponsorship posting form** | `features/sponsor/presentation/screens/sponsorship_posting_screen.dart` | Create/edit: title, sport, eligibility criteria, benefits offered, deadline, amount, documents required. `POST/PUT /api/sponsor/sponsorships` |
| 99 | **My sponsorships management** | `features/sponsor/presentation/screens/my_sponsorships_management_screen.dart` | List of posted opportunities. Status, applications count, edit/close. `GET /api/sponsor/sponsorships` |

### Step 6.3: Athlete Discovery & Applications

| # | Task | File(s) | Details |
|---|---|---|---|
| 100 | **Athlete discovery search** | `features/sponsor/presentation/screens/athlete_discovery_screen.dart` | Search/filter athletes by sport, age, city, achievements. Card list. `GET /api/sponsor/athletes` |
| 101 | **Athlete profile view (sponsor)** | `features/sponsor/presentation/screens/athlete_profile_view_screen.dart` | Full athlete profile: achievements, media gallery, stats. Buttons: Shortlist, Contact |
| 102 | **Applications inbox** | `features/sponsor/presentation/screens/applications_inbox_screen.dart` | List: athlete name, sport, pitch preview, date applied, status. Tabs: All, New, Shortlisted, Rejected. `GET /api/sponsor/applications` |
| 103 | **Application detail** | `features/sponsor/presentation/screens/application_detail_screen.dart` | Full pitch note, athlete profile summary. Actions: Shortlist, Reject, Accept. `PUT /api/sponsor/applications/:id` |
| 104 | **Shortlist screen** | `features/sponsor/presentation/screens/shortlist_screen.dart` | Grouped list of shortlisted athletes. Notes field per athlete. Remove from shortlist. `GET/PUT /api/sponsor/shortlist` |

---

## Phase 7 — Social & Connections Features (Weeks 9-10)

### Step 7.1: Social Feed

| # | Task | File(s) | Details |
|---|---|---|---|
| 105 | **Create post screen** | `features/social/presentation/screens/create_post_screen.dart` | Text input, photo/video upload, sport tag, mention. `POST /api/posts` |
| 106 | **Post detail screen** | `features/social/presentation/screens/post_detail_screen.dart` | Full post view, likes, comments, share. `GET /api/posts/:id` |
| 107 | **Posts provider** | `features/social/presentation/providers/posts_provider.dart` | Feed list, create post, like/unlike, comment |

### Step 7.2: Connections

| # | Task | File(s) | Details |
|---|---|---|---|
| 108 | **My connections** | `features/connections/presentation/screens/my_connections_screen.dart` | List of connected athletes/coaches. Search, filter by role. Remove connection. `GET /api/connections` |
| 109 | **Connection requests** | `features/connections/presentation/screens/connection_requests_screen.dart` | Incoming requests: accept/reject. Badge count. `GET/PUT /api/connections/requests` |
| 110 | **Connections provider** | `features/connections/presentation/providers/connections_provider.dart` | Manage connections, requests, accept/reject logic |

### Step 7.3: Chat / Messaging

| # | Task | File(s) | Details |
|---|---|---|---|
| 111 | **Chat list screen** | `features/chat/presentation/screens/chat_list_screen.dart` | List of chat threads: avatar, name, last message, timestamp, unread count. `GET /api/chats` |
| 112 | **Chat screen** | `features/chat/presentation/screens/chat_screen.dart` | Message thread (text + images). Real-time via WebSocket or polling. Send message, image upload. `GET /api/chats/:id/messages`, `POST /api/chats/:id/messages` |
| 113 | **Chat provider** | `features/chat/presentation/providers/chat_provider.dart` | Message list, send message, mark as read, typing indicator |

---

## Phase 8 — Admin Panel (Weeks 10-11)

### Step 8.1: Admin Auth & Dashboard

| # | Task | File(s) | Details |
|---|---|---|---|
| 114 | **Admin login** | `features/admin/presentation/screens/admin_login_screen.dart` | Email/password + 2FA code. `POST /api/admin/login` |
| 115 | **Admin dashboard** | `features/admin/presentation/screens/admin_dashboard_screen.dart` | Counters: total listings, flagged items, pending approvals, recent registrations. Charts optional |
| 116 | **Admin provider** | `features/admin/presentation/providers/admin_provider.dart` | Admin auth, dashboard stats, content management |

### Step 8.2: Content Management

| # | Task | File(s) | Details |
|---|---|---|---|
| 117 | **Content picker** | `features/admin/presentation/screens/admin_content_picker_screen.dart` | Category tabs (Academies, Coaches, Trials, Tournaments, Scholarships, Sponsorships, Venues) with count badges |
| 118 | **Content list (per category)** | `features/admin/presentation/screens/admin_content_list_screen.dart` | Table/card list with search, sort, status filters. Actions: Edit, Delete, View |
| 119 | **CRUD operations** | Shared form templates | Dynamic form per category schema. Create, edit, delete any record. `GET/POST/PUT/DELETE /api/admin/:type` |

### Step 8.3: Moderation & Approvals

| # | Task | File(s) | Details |
|---|---|---|---|
| 120 | **Platform reports** | `features/admin/presentation/screens/platform_reports_screen.dart` | Overview stats of reports |
| 121 | **Moderation queue** | `features/admin/presentation/screens/moderation_queue_screen.dart` | List of flagged/reported listings. Reason, reporter, date. `GET /api/admin/reports` |
| 122 | **Report detail** | `features/admin/presentation/screens/report_detail_screen.dart` | View reported content, reporter reason. Actions: Dismiss, Remove listing, Warn user. `PUT /api/admin/reports/:id` |
| 123 | **Manage users** | `features/admin/presentation/screens/manage_users_screen.dart` | Search, filter by role, status. `GET /api/admin/users` |
| 124 | **User detail / verify** | `features/admin/presentation/screens/user_detail_verify_screen.dart` | User profile, verification status. Actions: Verify, Suspend, Delete. `GET/PUT /api/admin/users/:id` |
| 125 | **Pending approvals** | `features/admin/presentation/screens/pending_approvals_screen.dart` | New listings requiring approval before going live. Approve/Reject. `GET /api/admin/approvals` |
| 126 | **Opportunity approval queue** | `features/admin/presentation/screens/opp_approval_queue_screen.dart` | Sponsorships/opportunities pending approval. `GET /api/admin/opportunities` |
| 127 | **Opportunity review detail** | `features/admin/presentation/screens/opp_review_detail_screen.dart` | Full details, approve/reject/edit. `PUT /api/admin/opportunities/:id` |

### Step 8.4: Notifications & Category Management

| # | Task | File(s) | Details |
|---|---|---|
| 128 | **Compose notification** | `features/admin/presentation/screens/compose_notification_screen.dart` | Title, message, target audience (all/role-specific/city-specific). `POST /api/admin/notifications` |
| 129 | **Notification targeting** | `features/admin/presentation/screens/notification_targeting_screen.dart` | Set up notification rules (deadline reminders, event reminders) |
| 130 | **Category management** | Via content list or dedicated screen | Add/edit/remove sports, cities, age groups. `GET/POST/PUT/DELETE /api/admin/meta/:type` |

---

## Phase 9 — Cross-Cutting Refinements (Weeks 11-12)

### Step 9.1: UI Polish

| # | Task | Scope | Details |
|---|---|---|---|
| 131 | **Consistent design system** | All screens | Verify: Poppins font, colors per `AppColors`, spacing 8px grid, border radius per spec, shadows |
| 132 | **Shimmer loading skeletons** | All list/detail screens | Replace `CircularProgressIndicator` with content-matched shimmer placeholders |
| 133 | **Empty states** | All list screens | Illustration + message + CTA button when no data |
| 134 | **Error states with retry** | All data-fetching screens | Error message + retry button on API failures |
| 135 | **Pull-to-refresh** | All list screens | `pull_to_refresh` package on every scrollable list |
| 136 | **Bottom sheet patterns** | Filter panels, quick actions | Use `BottomSheet` instead of full-screen navigation for filters and quick actions |
| 137 | **Confirmation dialogs** | Delete, logout, submit actions | Styled dialogs matching design system |

### Step 9.2: Navigation & UX

| # | Task | Scope | Details |
|---|---|---|---|
| 138 | **Deep linking** | Router | Configure `go_router` for URI deep links (e.g., `sportx://academies/123`) |
| 139 | **Back navigation** | All screens | Ensure proper `WillPopScope` / `PopScope` handling, unsaved changes warning |
| 140 | **Role-based navigation** | Bottom nav, dashboards | Athlete sees Home/Search/Saved/Activity/Profile. Coach sees Coach Dashboard. Academy sees Academy Dashboard. etc. |
| 141 | **Form validation** | All forms | Required field indicators (*), real-time validation, scroll to first error on submit |
| 142 | **Image caching & optimization** | All image displays | Use `CachedNetworkImage` everywhere. Add placeholder/error images |

### Step 9.3: Performance & Security

| # | Task | Scope | Details |
|---|---|---|---|
| 143 | **Pagination everywhere** | All list screens | Cursor-based or page-based pagination. No more loading all records at once |
| 144 | **Offline caching** | Meta data, saved items | Cache sports/cities/age groups locally using shared_preferences. Show cached data when offline |
| 145 | **Rate limiting handling** | API client | Show user-friendly "Too many requests, try again later" message on 429 |
| 146 | **Token refresh** | Auth flow | Auto-refresh token before expiry. Handle 401 with re-login redirect |
| 147 | **Input sanitization** | All text inputs | Prevent XSS in text fields, trim whitespace, max length enforcement |

### Step 9.4: Testing

| # | Task | Scope | Details |
|---|---|---|---|
| 148 | **Widget tests** | Critical screens | Test: auth flow, onboarding, home, directory list, detail page, enquiry form |
| 149 | **Integration tests** | Key flows | Test: sign up → onboarding → browse → enquire → registration |
| 150 | **Provider unit tests** | All providers | Test: auth state transitions, search filtering, saved toggle, pagination |

---

## Phase 10 — Production Readiness (Weeks 12-13)

| # | Task | Details |
|---|---|---|
| 151 | **Google sign-in** | Firebase Auth or OAuth2 integration on sign-up screen |
| 152 | **Push notifications** | Firebase Cloud Messaging — configure topics per sport, role, city |
| 153 | **Analytics** | Firebase Analytics — screen views, button taps, search queries |
| 154 | **Crash reporting** | Firebase Crashlytics — automatic crash reporting |
| 155 | **App icons & splash** | Generate app icons for all densities, launch screen per platform |
| 156 | **ProGuard / code shrinking** | Android release config, tree-shake unused code |
| 157 | **iOS App Store prep** | App ID, provisioning profiles, privacy manifests, Info.plist |
| 158 | **Android Play Store prep** | Signing config, privacy policy, content rating, screenshots |
| 159 | **Accessibility** | Screen reader labels, contrast checks, minimum touch target 48x48dp |
| 160 | **Performance profiling** | Flutter DevTools — identify jank, reduce rebuilds, optimize images |

---

## Screen Completion Checklist

| Role | Total Screens | Scaffold Exists | API Wired | Fully Done |
|---|---|---|---|---|
| **Shared (Auth, Search, Settings, Notifications)** | 12 | 12 | — | 0 |
| **Athlete / Parent** | 25 | 25 | — | 0 |
| **Coach** | 10 | 10 | — | 0 |
| **Academy** | 9 | 9 | — | 0 |
| **Organizer** | 10 | 10 | — | 0 |
| **Sponsor / Brand** | 13 | 13 | — | 0 |
| **Admin** | 14 | 14 | — | 0 |
| **Social/Chat/Connections** | 7 | 7 | — | 0 |
| **Total** | **100** | **100** | **0** | **0** |

> All 100 screens exist as UI scaffolds. The plan above walks through making every single one production-ready.

---

## Recommended Build Order

1. **Weeks 1-3:** Phase 1 (Infrastructure + Auth) + Phase 2 (Athlete browse/search/profile) → Demo: Athlete can sign up, browse, search, view profiles
2. **Weeks 3-5:** Phase 2 continued (Athlete actions) + Phase 3 (Coach) → Demo: Athlete registers for trial, Coach manages enquiries
3. **Weeks 5-7:** Phase 4 (Academy) + Phase 5 (Organizer) → Demo: Full trial/tournament lifecycle
4. **Weeks 7-9:** Phase 6 (Sponsor) + Phase 7 (Social/Connections/Chat) → Demo: Sponsorship pitch flow, social feed
5. **Weeks 9-11:** Phase 8 (Admin) → Demo: Admin moderates content
6. **Weeks 11-13:** Phase 9 (Polish) + Phase 10 (Production) → Demo: Production-ready APK
