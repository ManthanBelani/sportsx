# Jira Tickets — SportX India

Ticket backlog broken down by **Phase → Epic → Story/Task**. Each ticket includes description and acceptance criteria, formatted CSV-friendly for bulk import into Jira.

> **CSV format:** The tables below are structured as Jira-compatible columns: `Phase`, `Epic`, `Issue Type`, `Summary`, `Description`, `Acceptance Criteria`, `Priority`, `Story Points`. Copy any table and save as `.csv` for bulk import.

---

## Phase 0 — Foundation

### Epic P0-E1: Project Setup & Scaffolding

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P0,P0-E1: Project Setup,Story,"Set up Laravel API project","Scaffold Laravel 11 project with Sanctum, CORS config, sportx config file, MySQL connection, and API route prefix /api/v1.","Laravel project runs `php artisan serve`; `/api/v1/meta/sports` returns seed data; Sanctum token issued via `php artisan sanctum:token`; CORS allows Flutter origin.",Must,3
P0,P0-E1: Project Setup,Story,"Set up Flutter project with folder structure","Create Flutter project with feature-first folder structure per Mobile-Architecture.md. Configure Dio, go_router, Riverpod ProviderScope.","Flutter project runs on Android emulator; main.dart renders MaterialApp.router; folder structure matches spec.",Must,3
P0,P0-E1: Project Setup,Story,"Create all database migrations","Write Laravel migrations for all tables per Database-Design.md migration order (Steps 1-10).","`php artisan migrate` runs without error; all 25+ tables created; foreign keys validated.",Must,5
P0,P0-E1: Project Setup,Story,"Write master data seeders","Create seeders for sports (5+), cities (10+ across 3+ states), age_groups (6), and default expiry rules (AD8 wireframe values).","`php artisan db:seed` populates all master tables; academies/trials have test data for browsing.",Must,3
P0,P0-E1: Project Setup,Task,"Set up CI/CD pipeline","GitHub Actions: lint + test on push, staging deploy on merge to develop.","Pipeline passes on PR; staging URL auto-deploys.",Should,2
```

### Epic P0-E2: Auth API

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P0,P0-E2: Auth API,Story,"Implement email OTP registration","POST /auth/register creates user (unverified) + POST /auth/verify-otp validates code + issues token. OTP stored hashed, 5-min expiry, resend rate-limited.","Register with email → 202; verify valid OTP → 200 with token; wrong OTP → 422; expired OTP → 422; resend within 60s → 429.",Must,5
P0,P0-E2: Auth API,Story,"Implement login (password + OTP)","POST /auth/login with password OR OTP code. Token issued. Logout revokes token.","Password login works; OTP login sends code then verifies; invalid credentials → 401; logout deletes token → 401 on next request.",Must,5
P0,P0-E2: Auth API,Story,"Implement role onboarding for all 5 roles","POST /auth/register sets role; POST /onboarding/{role} creates the role profile. Athlete: sports + age group + skill + city. Coach: sports + certs + experience. Academy: name + sports + city. Organizer: org name + type + docs. Sponsor: brand + logo + category + docs.","Each role onboarding creates correct profile; athlete profile links sports; academy profile created with listing_status=draft; verification docs stored as media_items.",Must,5
P0,P0-E2: Auth API,Task,"Implement auth middleware and role middleware","auth:sanctum on all authenticated routes; role:xxx middleware checking user->role.","Unauthenticated request → 401; wrong-role request → 403.",Must,2
```

---

## Phase 1 — Discovery

### Epic P1-E1: Auth UI (Flutter)

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P1,P1-E1: Auth UI,Story,"Build splash + role selection screens","S1 Splash with logo/loading + S2 Role Selection with 5 cards (Athlete/Parent, Coach, Academy, Organizer, Sponsor).","Splash renders 2s then transitions; role selection shows all 5 cards; tapping a card navigates to sign-up with role pre-selected.",Must,2
P1,P1-E1: Auth UI,Story,"Build sign-up screen","S3: phone/email toggle (+91 input), terms checkbox, Continue button, Google sign-in button.","User can type email, accept terms, tap Continue → OTP screen. Google button present (non-functional at P1).",Must,2
P1,P1-E1: Auth UI,Story,"Build OTP verification screen","S4: masked destination, 6-digit code input fields, resend timer, Verify button.","Code entered → Verify calls API; success → onboarding; resend timer counts down from 60s; resend re-calls API.",Must,2
P1,P1-E1: Auth UI,Story,"Build login screen","S5: email/phone input, password/OTP toggle, login button, forgot password link, sign-up link.","Login with valid credentials → home. Forgot password visible (non-functional at P1). Toggle switches between password and OTP fields.",Must,2
```

### Epic P1-E2: Onboarding & Profile

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P1,P1-E2: Onboarding & Profile,Story,"Build athlete onboarding (2-step)","A1: multi-select sport chips + age group radio. A2: skill level radio + city autocomplete. Mandatory fields per PDF: full_name, date_of_birth, gender, sport(s), city. Photo upload required.","Step 1 → Next → step 2 → Finish → API call → Home dashboard. At least one sport selected; city chosen from autocomplete; name, DOB, gender, and photo validated as required.",Must,3
P1,P1-E2: Onboarding & Profile,Story,"Build athlete profile screens","A4: View profile (photo, name, sport, city, achievements, media gallery preview). A5: Edit profile (all fields, achievements add/remove). A6: Media gallery manager (upload, delete, drag-to-reorder).","Profile view matches wireframe; edit saves via API; media gallery: upload photo/video, delete with ✕, drag to reorder persisted.",Must,5
P1,P1-E2: Onboarding & Profile,Story,"Build coach onboarding + profile creation","C1: sports coached, certs, experience. C2: Edit listing (photo, name, certs, experience, fee, location, bio).","Coach profile created on onboarding; edit form matches wireframe; listing_status persisted.",Must,3
P1,P1-E2: Onboarding & Profile,Story,"Build academy onboarding + listing creation","AC1: name, sports, city. AC2: Edit listing (cover photo, name, sports, facilities, fee range, age groups, timings, coaches, photos).","Academy listing created; all fields editable; cover photo uploaded.",Must,3
```

### Epic P1-E3: Search, Directories & Filters

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P1,P1-E3: Search & Directories,Story,"Build universal search","S6: search bar + recent searches + trending sport chips. S7: tabbed results across 7 categories (incl. Sports Venues) with pagination.","Type query → results appear under category tabs; tabs scrollable; Load more pagination works; trending chips from meta API.",Must,5
P1,P1-E3: Search & Directories,Story,"Build shared filter panel","S8: sport multi-select, city/state dropdown, age group select, price range slider, date range, Apply/Clear buttons.","Filter panel opens as modal; apply refreshes list; clear resets; filters persist per tab.",Must,3
P1,P1-E3: Search & Directories,Story,"Build reusable directory list template","T1: generic card list with thumbnail, title, subtitle (sport·city), meta (fee/date), search bar, filter icon, bottom nav.","Template renders any listing type with field substitutions per T1 table. Scroll is smooth at 60fps.",Must,5
P1,P1-E3: Search & Directories,Story,"Build reusable detail page template","T2: hero image/banner, title, sport·city, info sections, coach cards (academy), location/map preview, report action, save button, CTA button.","Template renders any detail with field substitutions per T2 table. Save ♡ toggles. Report opens modal.",Must,5
P1,P1-E3: Search & Directories,Story,"Implement academy directory & detail","A7 list + A8 detail using T1/T2 templates. Fields: facilities, coaches, age groups, timings, fees, description, Google Maps, verification badge (mandatory per PDF).","Academy list shows correct cards; detail shows all sections; coach cards link to coach detail; description field visible.",Must,2
P1,P1-E3: Search & Directories,Story,"Implement coach directory & detail","A9 list + A10 detail using T1/T2 templates. Fields: full_name, sport, city, contact_number, experience, qualification, certifications, academy, languages, email, personal_coaching, fees (mandatory fields per PDF).","Coach list shows correct cards; detail shows all sections; Enquire CTA visible.",Must,2
P1,P1-E3: Search & Directories,Story,"Implement trial listings & detail","A12 list + A13 detail. Fields: organization_name, google_maps_url, registration_deadline, vacancies, benefits (mandatory per PDF).","Trial list sorted by event_datetime; detail shows all fields including org name, map, registration deadline; Register CTA visible but non-functional at P1.",Must,2
P1,P1-E3: Search & Directories,Story,"Implement tournament calendar & detail","A16: calendar/list toggle + A17 detail. Fields: registration_deadline, google_maps_url, contact_number, registration_link (mandatory per PDF), rules, gender, banner.","Calendar shows dates with dots for events; list view shows cards; detail shows all fields including external registration link.",Must,3
P1,P1-E3: Search & Directories,Story,"Implement scholarship feed & detail","A19 list + A20 detail. Fields: organization_name, name, eligibility, deadline, application_link, contact_email, contact_phone (mandatory per PDF).","Scholarship list shows correct cards; detail shows Apply button that opens external URL.",Must,2
P1,P1-E3: Search & Directories,Story,"Implement sponsorship listings & detail","A21 list + A22 detail. Fields: eligibility, benefits, deadline, application_link, contact (mandatory per PDF).","List and detail render correctly; Apply/Pitch CTA visible but non-functional at P1.",Must,2
P1,P1-E3: Search & Directories,Story,"Implement sports venue directory & detail (new)","Sports venue list + detail using T1/T2 templates. Fields: name, sport, address, google_maps_url, contact_number, booking_available, pricing, facilities, working_hours (all from Mandatory Fields PDF).","Venue list shows correct cards filtered by sport/city; detail shows map, contact, facilities; report/save work.",Must,2
```

### Epic P1-E4: Save, Report & Shell

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P1,P1-E4: Save & Report,Story,"Implement saved/bookmarked items","Save from detail page (♡), saved items list (A25) grouped by type with tabs (All/Academies/Coaches/Trials/Tournaments/Scholarships/Sponsorships/Venues).","Save toggles; unsave removes; saved list shows correct items; tabs filter by type; empty state shown.",Must,3
P1,P1-E4: Save & Report,Story,"Implement report-a-listing modal","S10: reason radio (Fake/Scam, Outdated, Inappropriate, Other) + optional comment + Cancel/Submit.","Modal opens from detail page; submit calls API; success shows confirmation.",Must,2
P1,P1-E4: Save & Report,Task,"Implement bottom navigation bar","Persistent bottom nav: Home, Search, Saved, Profile — renders on all primary athlete screens per T1.","Bar visible on all 4 primary tabs; active tab highlighted; tapping switches screen.",Must,1
```

---

## Phase 2 — Actions & Supply Side

### Epic P2-E1: Enquiries

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E1: Enquiries,Story,"Build enquiry form for coaches","A11/T3: modal with message box + preferred date/time picker. Posts to /enquiries.","Form renders on coach detail; message required; date optional; submit → success → enquiry created.",Must,3
P2,P2-E1: Enquiries,Story,"Build coach enquiry inbox + reply","C4: inbox list with All/New/Replied tabs. C5: thread view with message bubbles + reply box.","Inbox shows enquiries sorted by latest; New tab filters unread; opening thread marks incoming as read; reply sends message.",Must,5
P2,P2-E1: Enquiries,Story,"Build academy enquiry inbox","AC8/AC9: reuse T4/T4b templates for academy inbox.","Academy owner sees enquiries addressed to their academy; reply works identically to coach inbox.",Must,2
```

### Epic P2-E2: Registrations

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E2: Registrations,Story,"Build trial registration form + confirmation","A14: form with auto-filled profile, document upload, payment note (info only). A15: confirmation screen with reg ID, add-to-calendar, reminder toggle.","Form validates required docs; upload works; submit creates registration; confirmation shows ref ID; reminder toggle persists.",Must,5
P2,P2-E2: Registrations,Story,"Build tournament registration form","A18: category selection, team/individual toggle, team name input, personal details.","Category selector shows available categories with capacity info; submit creates registration; capacity enforced.",Must,5
P2,P2-E2: Registrations,Story,"Build My Activity Hub","A24: tabs (Trials/Tournaments/Sponsorships) with status per item (Confirmed/Pending Review/Waitlisted).","Activity hub shows all registrations + applications; status badges correct; tapping item opens detail.",Must,3
```

### Epic P2-E3: Sponsorship Applications

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E3: Sponsorship,Story,"Build apply/pitch to sponsor form","A23/T3: pitch note text box + profile auto-attach confirmation.","Pitch form on sponsorship detail; note required; submit creates application; visible in My Activity.",Must,3
```

### Epic P2-E4: Academy Trial Management

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E4: Academy Trials,Story,"Build academy trial posting form","AC4: create/edit trial (name, sport, datetime, venue, eligibility, fee, docs, contact) + draft/publish.","Form validates all fields; save creates trial (draft or published); My Trials list shows trial.",Must,5
P2,P2-E4: Academy Trials,Story,"Build academy trial management list","AC5: My Trials with status (Draft/Published/Closed) + edit/close actions.","List shows all academy trials; status badge correct; edit/close actions work.",Must,2
P2,P2-E4: Academy Trials,Story,"Build trial registrant list + detail","AC6: registrant list with document status badges. AC7: registrant detail with document viewer + verify/reject actions.","List shows count + spots left; document status icons; detail shows documents; verify/reject updates status.",Must,5
```

### Epic P2-E5: Organizer Management

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E5: Organizer,Story,"Build organizer onboarding + dashboard","O1: org name, type, verification docs. O2: dashboard with active counts, post actions, deadlines.","Onboarding stores org profile; dashboard shows trial/tournament counts; post buttons visible.",Must,3
P2,P2-E5: Organizer,Story,"Build organizer trial management","O3/O4: trial create/edit/publish/close (same form as AC4).","Trial CRUD works for organizer; trials appear in list with correct status.",Must,3
P2,P2-E5: Organizer,Story,"Build organizer tournament CRUD + calendar","O5: tournament create (format, dates, venue, fee, prize pool, categories). O6: management list.","Tournament created with categories; list shows all tournaments; categories have capacity from creation.",Must,5
P2,P2-E5: Organizer,Story,"Build registration management + payment status","O7: per-category registration list with payment status flag (Pending/Paid).","List shows registrations per category with capacity meters; organizer can flip payment_status manually.",Must,5
P2,P2-E5: Organizer,Story,"Build capacity/spot management","O8: per-category capacity adjustment + waitlist toggle.","Slider/input changes capacity; waitlist toggle saved; capacity enforced on new registrations.",Must,3
P2,P2-E5: Organizer,Story,"Build results publishing + public view","O9: per-category winner/runner-up/3rd + bracket image upload. O10: public bracket/results view.","Results published; public view shows bracket image and podium list; results grouped by category.",Must,5
```

### Epic P2-E6: Sponsor Management

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E6: Sponsor,Story,"Build sponsor onboarding + dashboard","SP1: brand name, logo, category, verification docs. SP2: dashboard with listings count, new apps, post action.","Profile created; dashboard shows counts and recent applications.",Must,3
P2,P2-E6: Sponsor,Story,"Build sponsorship listing CRUD + management list","SP3: create sponsorship listing. SP4: management list with status + applications count.","CRUD works; list shows all sponsorships; status badges correct.",Must,5
P2,P2-E6: Sponsor,Story,"Build athlete discovery search + profile view","SP5: search athletes by sport, age, city, level. SP6: athlete profile view with achievements, media, shortlist/message actions.","Search returns matching athletes; profile view shows all info; Shortlist and Message buttons visible.",Must,5
P2,P2-E6: Sponsor,Story,"Build sponsor applications inbox + detail","SP7: inbox list. SP8: application detail with pitch note, view full profile, shortlist/reject/reply actions.","Inbox shows applications; detail shows pitch; shortlist/reject updates status; reply opens thread.",Must,5
P2,P2-E6: Sponsor,Story,"Build sponsor shortlist","SP9: shortlisted athletes with editable notes per entry.","Shortlist shows all shortlisted athletes; note can be added/edited; athletes can be removed.",Must,3
```

---

## Phase 3 — Admin & Reminders

### Epic P3-E1: Admin Console

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P3,P3-E1: Admin Console,Story,"Build admin login with 2FA","AD1: email + password + 2FA code. Session requires 2FA verification.","Login fails without valid 2FA code; session flag set after verification; admin middleware checks flag.",Must,5
P3,P3-E1: Admin Console,Story,"Build admin dashboard","AD2: counters for active listings, flagged items, pending expirations, new signups.","Dashboard shows correct counts from DB; counts update in real-time on refresh.",Must,2
P3,P3-E1: Admin Console,Story,"Build content management (category picker + list + CRUD)","AD3: category picker with counts. AD4: content list with search/sort/filter. AD5: dynamic create/edit/delete form matching owner schema.","Picker shows 6 categories with counts; list paginates and filters; form changes all applicable fields; delete soft-removes.",Must,8
P3,P3-E1: Admin Console,Story,"Build moderation queue + actions","AD6: reported listings queue (listing, reason, report count, time). AD7: moderation detail with approve/edit/remove/warn actions.","Queue shows pending reports; detail shows report info + listing; each action updates report + listing appropriately; owner notified on remove/warn.",Must,8
P3,P3-E1: Admin Console,Story,"Build expiry rules configuration","AD8: per-content-type auto-expiry timing (trials after event date, tournaments after final date, sponsorships on deadline).","Rules saved; applied to listings on publish.",Must,3
P3,P3-E1: Admin Console,Story,"Build expiry monitor","AD9: Pending/Expired/Overridden tabs; Override and Restore actions per event.","Monitor shows correct events per tab; Override keeps listing published; Restore re-activates expired listing.",Must,5
P3,P3-E1: Admin Console,Story,"Build category management (sports/cities/age groups)","AD10/AD11/AD12: editable lists with add/edit/remove per master data type.","CRUD works for all 3 types; is_active toggle for soft removal; additions appear in filters.",Must,3
```

### Epic P3-E2: Reminders & Notifications

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P3,P3-E2: Reminders,Story,"Implement reminder subscription engine","On trial/tournament confirm + scholarship save: create reminder_subscription rows. Default offsets: T-2d and T-1d.","Subscriptions created on save/confirm; correct offsets; no duplicate subscriptions.",Must,3
P3,P3-E2: Reminders,Story,"Implement reminder sweep job","Scheduled job: find due subscriptions, create notification rows, call push provider (interface).","Job runs on schedule; notifications created; no double-sends; sent_at updated.",Must,3
P3,P3-E2: Reminders,Story,"Implement notifications center UI","S9: notifications list with icon, title, body, time. Mark read. Mark all read.","Notifications list shows unread-first; tapping marks read; mark-all-read works; badge count on bell icon.",Must,3
P3,P3-E2: Reminders,Story,"Implement auto-expiry engine","Scheduled job: evaluate published listings vs expiry_rules + expires_at; create/execute expiry_events.","Published trial past expiry → status=expired; event created in monitor; owner notified (event only).",Must,5
```

---

## Phase 4 — Polish

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P4,P4-E1: Polish,Story,"Implement Google sign-in","S3 'Continue with Google' using google_sign_in + Laravel Socialite.","Google sign-in flow completes; account linked/created; email verified from Google; onboarding if needed.",Should,3
P4,P4-E1: Polish,Story,"Implement forgot password flow","S5 forgot password → email reset link → reset password.","Reset email sent; link expires in configurable time; password changed successfully.",Must,2
P4,P4-E1: Polish,Task,"Security hardening — rate limiting","Apply rate limits per Security-and-NonFunctional.md §3. Verify 429 responses with Retry-After headers.","All auth endpoints rate-limited; 429 returned when exceeded; headers present.",Must,2
P4,P4-E1: Polish,Task,"Performance optimization — index review","Review all query hotspots; add missing indexes; optimize N+1 queries with eager loading.","All list/detail queries under P95 targets from performance doc.",Should,3
P4,P4-E1: Polish,Task,"Set up monitoring and error tracking","Deploy Sentry (or equivalent) for error tracking; configure APM for Laravel.","Exceptions captured; dashboard shows error trends; alerts configured.",Should,2
P4,P4-E1: Polish,Task,"Load testing","Simulate 1000+ concurrent users on key endpoints (search, registration, login).","P95 latency within targets; no 5xx errors under load.",Should,3
```

---

## Ticket Count Summary

| Phase | Stories | Tasks | Total |
|---|---|---|---|
| P0 Foundation | 7 | 1 | 8 |
| P1 Discovery | 18 | 2 | 20 |
| P2 Actions | 18 | 0 | 18 |
| P3 Admin + Reminders | 11 | 0 | 11 |
| P4 Polish | 3 | 4 | 7 |
| **Total** | **57** | **7** | **64** |

> Story points are directional estimates (1=trivial, 2=small, 3=medium, 5=large, 8=complex). Adjust based on team velocity.
