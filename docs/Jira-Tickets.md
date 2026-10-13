# Jira Tickets — SportX India

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

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
P0,P0-E2: Auth API,Story,"Implement role onboarding for all roles","POST /auth/register sets role; POST /onboarding/{role} creates the role profile. Athlete: sports + age group + skill + city. Coach: sports + certs + experience. Academy: name + sports + city. Organizer: org name + type + docs. Scout: organization, sports specialization, experience, location. (v3: Sponsor role removed; scout replaces talent_scout.)","Each role onboarding creates correct profile; athlete profile links sports; academy profile created with listing_status=draft; verification docs stored as media_items.",Must,5
P0,P0-E2: Auth API,Story,"Implement phone-or-email OTP + guardian consent","v3 P0: OTP for signup/login via SMS or email; otp_codes table, issue/verify/resend, 5-min expiry, rate limits. Guardian consent flow (guardian_consents) for minors.","Register via phone or email → OTP; verify → token; resend rate-limited; minor signup requires guardian consent record.",Must,5
P0,P0-E2: Auth API,Task,"Implement auth middleware and role middleware","auth:sanctum on all authenticated routes; role:xxx middleware checking user->role.","Unauthenticated request → 401; wrong-role request → 403.",Must,2
```

---

## Phase 1 — Discovery

### Epic P1-E1: Auth UI (Flutter)

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P1,P1-E1: Auth UI,Story,"Build splash + role selection screens","S1 Splash with logo/loading + S2 Role Selection with 6 cards (Athlete/Parent, Coach, Academy, Organizer, Scout, Admin).","Splash renders 2s then transitions; role selection shows all 6 cards; tapping a card navigates to sign-up with role pre-selected.",Must,2
P1,P1-E1: Auth UI,Story,"Build sign-up screen","S3: phone/email toggle (+91 input), terms checkbox, Continue button, Google sign-in button (FUNCTIONAL — see P3E-E2).","User can type email, accept terms, tap Continue → OTP screen. Google button completes sign-in and returns a token; role captured before the button is tapped.",Must,2
P1,P1-E1: Auth UI,Story,"Build OTP verification screen","S4: masked destination, 6-digit code input fields, resend timer, Verify button.","Code entered → Verify calls API; success → onboarding; resend timer counts down from 60s; resend re-calls API.",Must,2
P1,P1-E1: Auth UI,Story,"Build login screen","S5: email/phone input, password/OTP toggle, login button, forgot password link (must navigate — onPressed is currently an empty closure), sign-up link.","Login with valid credentials → home. Tapping forgot password navigates to the reset screen. Toggle switches between password and OTP fields. Google button functional.",Must,2
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
P1,P1-E3: Search & Directories,Story,"Implement opportunities feed & detail (scholarship type)","A19 list + A20 detail for unified `opportunities` (type=scholarship). v3: provider-posted, in-app apply. Fields: organization_name, name, eligibility, deadline, benefits, contact.","Opportunity list shows correct cards; detail shows Apply button (in-app application at P2).",Must,2
P1,P1-E3: Search & Directories,Story,"Implement opportunities feed & detail (sponsorship type)","A21 list + A22 detail for `opportunities` (type=sponsorship). Unified with scholarships in v3. Fields: eligibility, benefits, deadline, contact.","List and detail render correctly; Apply/Pitch CTA visible but non-functional at P1.",Must,2
P1,P1-E3: Search & Directories,Story,"Implement sports venue directory & detail (new)","Sports venue list + detail using T1/T2 templates. Fields: name, sport, address, google_maps_url, contact_number, booking_available, pricing, facilities, working_hours (all from Mandatory Fields PDF).","Venue list shows correct cards filtered by sport/city; detail shows map, contact, facilities; report/save work.",Must,2
```

### Epic P1-E4: Save, Report & Shell

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P1,P1-E4: Save & Report,Story,"Implement saved/bookmarked items","Save from detail page (♡), saved items list (A25) grouped by type with tabs (All/Academies/Coaches/Trials/Tournaments/Opportunities/Programs/Facilities/Venues).","Save toggles; unsave removes; saved list shows correct items; tabs filter by type; empty state shown.",Must,3
P1,P1-E4: Save & Report,Story,"Implement report-a-listing modal","S10: reason radio (Fake/Scam, Outdated, Inappropriate, Other) + optional comment + Cancel/Submit.","Modal opens from detail page; submit calls API; success shows confirmation.",Must,2
P1,P1-E4: Save & Report,Task,"Implement bottom navigation bar","Persistent bottom nav: Home, Search, Saved, Profile — renders on all primary athlete screens per T1.","Bar visible on all 4 primary tabs; active tab highlighted; tapping switches screen.",Must,1
```

### Epic P1-E5: Talent Scout Onboarding & Profile

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P1,P1-E5: Talent Scout,Story,"Build talent scout onboarding","TS1: organization/affiliation, sports specialization, experience, location. Multi-step form.","Form validates all fields; submit creates scout profile; routes to Scout Dashboard.",Must,3
P1,P1-E5: Talent Scout,Story,"Build talent scout profile view/edit","TS2: scout profile with organization, sports, experience, location. Edit capability.","Profile shows all scout info; edit form pre-populated; save persists.",Must,2
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
P2,P2-E2: Registrations,Story,"Build My Activity Hub","A24: tabs (Trials/Tournaments/Opportunities) with status per item (Confirmed/Pending Review/Waitlisted).","Activity hub shows all registrations + applications; status badges correct; tapping item opens detail.",Must,3
```

### Epic P2-E3: Opportunity Applications

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E3: Opportunities,Story,"Build apply/pitch to opportunity form","A23/T3: pitch note text box + profile auto-attach confirmation. Posts to /opportunities/{id}/applications.","Pitch form on opportunity detail; note required; submit creates opportunity_application; visible in My Activity.",Must,3
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

### Epic P2-E6: Opportunity & Provider Management (was Sponsor Management)

> **[REMOVED in v3]** Sponsor onboarding/dashboard (SP1/SP2) retired — `sponsor` is no longer a role. The SP3–SP9 screens are reused by academy/organizer/coach/scout for unified `opportunities`.

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E6: Provider Ops,Story,"Build opportunity CRUD + management list","SP3/SP4 reused: provider (academy/organizer/coach/scout) creates/edits/publishes unified `opportunities`; management list with status + applications count.","CRUD works for each provider role; list shows all opportunities; status badges correct.",Must,5
P2,P2-E6: Provider Ops,Story,"Build athlete discovery search + profile view","SP5/SP6 reused: search athletes by sport, age, city, level; profile view with achievements, media, shortlist/connect actions.","Search returns matching athletes; profile view shows all info; Shortlist and Connect buttons visible.",Must,5
P2,P2-E6: Provider Ops,Story,"Build opportunity applications inbox + detail","SP7/SP8 reused: inbox list; application detail with pitch, full profile, shortlist/decline/reply.","Inbox shows applications; shortlist/decline updates status; reply opens thread.",Must,5
P2,P2-E6: Provider Ops,Story,"Build shortlist with notes","SP9 reused: shortlisted athletes with editable notes; scout/owner-keyed shortlist.","Shortlist shows all entries; note editable; entries removable.",Must,3
```

### Epic P2-E7: Talent Scout — Discovery & Connections

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E7: Talent Scout,Story,"Build talent scout dashboard","TS2: search shortcut, saved athletes count, activity summary tiles.","Dashboard shows quick actions and summary stats; search shortcut navigates to discovery.",Must,2
P2,P2-E7: Talent Scout,Story,"Build athlete discovery with advanced filters","TS3: filterable athlete cards by sport, age group, location, skill level, achievements. Uses global filter panel.","Filters return relevant athletes; cards show key info; load more pagination works.",Must,5
P2,P2-E7: Talent Scout,Story,"Build athlete profile view for scouts","TS4: public athlete profile showing sports history, achievements, media gallery, shortlist and connect CTAs.","Profile renders all sections; Shortlist and Connect buttons functional.",Must,3
P2,P2-E7: Talent Scout,Story,"Build talent scout shortlist","TS5: shortlisted athlete cards with remove option.","Shortlist shows saved athletes; remove removes from list; empty state shown when empty.",Must,2
P2,P2-E7: Talent Scout,Story,"Build talent scout connection/enquiry","TS6: connection/enquiry form to contact athlete/parent through platform.","Form validates; submit sends enquiry; confirmation shown.",Must,3
```

---

## Phase 2b — New v3 P0 Modules

> New modules introduced by the v3 design delta. Sequence per `Backend-Feature-Delta.md` §9.

### Epic P2-E8: Opportunities (unified)

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E8: Opportunities,Story,"Build unified opportunities backend + migration","New `opportunities` table (provider morph, type enum scholarship/sponsorship/tryout/camp, eligibility, benefits/amount, deadline, docs, status) + CRUD per role + public list/detail. Migrate `scholarships`/`sponsorships` rows.","Endpoints work for all providers; old rows migrated with legacy_type; `/me/opportunities` returns Applied/Saved/Created.",Must,8
P2,P2-E8: Opportunities,Story,"Build opportunity applications + review","`opportunity_applications` (pitch, docs, profile snapshot, status machine). `GET /opportunities/{id}/applications`, `PATCH .../applications/{app}` (shortlist/decline + note).","Apply creates application with status; provider can shortlist/decline; athlete sees status in My Activity.",Must,5
```

### Epic P2-E9: Programs & Facilities

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E9: Programs & Facilities,Story,"Build programs (backend + screens)","Provider program CRUD + public listing + program enquiry (thread).","Program created/edited; listed publicly; enquiry opens chat thread.",Must,5
P2,P2-E9: Programs & Facilities,Story,"Build facilities (backend + screens)","Academy facility CRUD + public listing.","Facility created/edited; listed on academy detail.",Must,3
```

### Epic P2-E10: Social, Network & Messaging

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E10: Social,Story,"Verify/build social core (posts/feed/likes/comments)","v3 P0. Verify existing posts/post_likes/post_comments tables first (see UI-Completion-And-Backend-Wiring-Plan.md). Feed, create post, like, comment.","Feed loads; post create works; like/comment persist; author resolved via user role.",Must,5
P2,P2-E10: Social,Story,"Build follow / connect (network)","`follows` + `connection_requests`. Follow any profile; send/accept/decline connection.","Follow toggles; connection request/accept/decline works; counts update.",Must,5
P2,P2-E10: Social,Story,"Build 1:1 chat (conversations + messages)","`conversations`, `conversation_participants`, `messages` (text P0; media P1). Inbox + thread + read receipts; 90-day purge default.","Conversation created from profile/opportunity; messages send/receive; unread counts; thread marks read.",Must,5
P2,P2-E10: Social,Story,"Build blocks & reports","`blocks` + extended reports for posts/comments/users.","User can block another; blocked users cannot message/follow; report creates moderation entry.",Must,3
```

### Epic P2-E11: Leaderboard

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P2,P2-E11: Leaderboard,Story,"Build leaderboard points engine + API","`leaderboard_scores` (athlete, sport, points, season) + `leaderboard_seasons` + recalculation job on verified achievement / completion milestones / participation. `GET /leaderboard` with sport/location/age filters, podium + ranks 4-10.","Scores recalc on triggers; API returns podium + ranks; minors anonymized (first name + initial); season reset job works.",Must,8
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
P3,P3-E1: Admin Console,Story,"Build expiry rules configuration","AD8: per-content-type auto-expiry timing (trials after event date, tournaments after final date, opportunities on deadline).","Rules saved; applied to listings on publish.",Must,3
P3,P3-E1: Admin Console,Story,"Build expiry monitor","AD9: Pending/Expired/Overridden tabs; Override and Restore actions per event.","Monitor shows correct events per tab; Override keeps listing published; Restore re-activates expired listing.",Must,5
P3,P3-E1: Admin Console,Story,"Build category management (sports/cities/age groups)","AD10/AD11/AD12: editable lists with add/edit/remove per master data type.","CRUD works for all 3 types; is_active toggle for soft removal; additions appear in filters.",Must,3
P3,P3-E1: Admin Console,Story,"Build verification queue (AD.4)","v3 P0: list pending verification submissions by content type; approve grants verified badge, reject records reason.","Queue filters by type/status; approve sets badge; reject stores reason; applicant notified.",Must,5
P3,P3-E1: Admin Console,Story,"Build user management (AD.3)","v3 P0: GET /admin/users (search + role/status filters), detail, suspend/ban (uses users.status), audit columns.","Search/filters work; suspend and ban update status; audit trail recorded.",Must,5
P3,P3-E1: Admin Console,Story,"Extend admin content types + positions master + opportunity expiry","Add opportunities/programs/facilities/posts to content types; positions master (sport→position) CRUD; opportunity content type in expiry_rules + sweep.","New content types manageable; positions CRUD; opportunity expiry rules apply and appear in monitor.",Must,5
```

### Epic P3-E2: Reminders & Notifications

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P3,P3-E2: Reminders,Story,"Implement reminder subscription engine","On trial/tournament confirm + scholarship save: create reminder_subscription rows. Default offsets: T-2d and T-1d.","Subscriptions created on save/confirm; correct offsets; no duplicate subscriptions.",Must,3
P3,P3-E2: Reminders,Story,"Implement reminder sweep job","Scheduled job: find due subscriptions, create notification rows, dispatch via NotificationService (FCM transport built in P3E-E3).","Job runs on schedule; notifications created; no double-sends; sent_at updated.",Must,3
P3,P3-E2: Reminders,Story,"Implement notifications center UI","S9: notifications list with icon, title, body, time. Mark read. Mark all read.","Notifications list shows unread-first; tapping marks read; mark-all-read works; badge count on bell icon.",Must,3
P3,P3-E2: Reminders,Story,"Implement auto-expiry engine","Scheduled job: evaluate published listings vs expiry_rules + expires_at; create/execute expiry_events.","Published trial past expiry → status=expired; event created in monitor; owner notified (event only).",Must,5
```

---

## Phase 3E — Platform Integrations (2026-10)

> Three vendor decisions closed: **email = SMTP or Gmail** (runtime switchable), **Google sign-in = P0** (moved from P4-E1), **push = FCM HTTP v1**.
> Specs: `Email-Provider-Architecture.md` · `Google-Authentication.md` · `FCM-Notification-System.md`. Plan: `PHASE_WISE_IMPLEMENTATION_PLAN.md` Phase 3E.
>
> ⚠️ Tickets marked **[launch gate]** are not build work — they are credential/config steps that **block a production release**. AS-60 (SMS vendor) is tracked separately in the plan.

### Epic P3E-E1: Email Providers (dual SMTP + Gmail)

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P3E,P3E-E1: Email Providers,Task,"Reconcile composer.lock with composer.json","google/auth is required by the Gmail transport, the FCM client and Google ID-token verification but is missing from the lock file, so composer install fails outright.","composer install completes from the lock file; google/auth is present; no version drift warnings.",Must,1
P3E,P3E-E1: Email Providers,Story,"Add dual-provider email configuration","Add the gmail mailer to config/mail.php (auth_mode, client creds, service-account fields, token cache key, timeout) and a mail block to config/sportx.php (provider, failover chain, retry_after, test_recipient). Add FRONTEND_URL to config/app.php.","`php artisan config:show mail` lists both smtp and gmail; sportx.mail.provider resolves from MAIL_PROVIDER; app.frontend_url resolves from FRONTEND_URL.",Must,2
P3E,P3E-E1: Email Providers,Story,"Implement GmailApiTransport (Gmail REST v1)","Custom Symfony AbstractTransport sending via gmail.googleapis.com messages:send with a base64 raw RFC822 payload. Auth modes: user (refresh token) and service_account (domain-wide delegation). Access token cached with a 60s expiry margin. Normalise literal backslash-n in the private key.","Http::fake() shows a base64 raw payload with correct headers; a 4xx raises TransportException; an incomplete config fails closed with an explicit message rather than throwing a generic error; the cached token is reused until within 60s of expiry.",Must,5
P3E,P3E-E1: Email Providers,Story,"Implement MailProviderService","Provider resolution (platform_settings.json override → MAIL_PROVIDER → smtp); activeMailer(); configuredChain() filtered to providers that have credentials; isConfigured() per mode; status(); diagnostics(); testConnection(); setActiveProvider(); clearTokenCache().","Admin override beats env; an unconfigured provider is filtered out of the chain; testConnection returns a structured {ok, detail} and never throws; no secret appears in any returned payload.",Must,5
P3E,P3E-E1: Email Providers,Task,"Register gmail-api transport and resolve mailer per request","Register via Mail::extend in AppServiceProvider; set config mail.default from MailProviderService on every request; build the sportx_failover mailer from configuredChain(). Short-circuit to the configured default under runningUnitTests so Mail::fake and Mail::assertSent work.","Switching the active provider in the admin panel affects a message still sitting in the mail queue without a redeploy or config-cache rebuild; feature tests using the array mailer are unaffected.",Must,3
P3E,P3E-E1: Email Providers,Story,"Implement SportXMail base mailable and email templates","Abstract Mailable implementing ShouldQueue with onQueue(mail), tries=3, backoff=[10,30,90], timeout=60, deepLink() helper and failed() logging. Table-based emails/layout.blade.php (inline styles only — Gmail and Outlook strip style blocks) plus 7 templates: otp, verify-email, password-reset, account-approved, account-rejected, welcome, notification-fallback.","Every template renders under Mail::render(); OTP and password-reset mails each carry an explicit never-asked-for-this line; brand colours follow neutral/blue, success/green, warning/red.",Must,5
P3E,P3E-E1: Email Providers,Story,"Wire mailables into all auth and approval flows","Send EmailOtpMail on OTP issue; send VerifyEmail (this mailable existed but was never instantiated anywhere); send AccountApprovedMail and AccountRejectedMail from admin approve/reject/suspend; send WelcomeMail post-registration. Admin approve/reject previously flipped a DB column and notified nobody.","OTP round-trips end to end; approving a coach registration produces an email; rejecting records the reason; the only outbound email in the app is no longer just password reset.",Must,5
P3E,P3E-E1: Email Providers,Story,"Implement admin email-settings API","GET status · GET diagnostics (Gmail auth probe + SMTP socket probe + resolved chain) · POST provider (runtime switch persisted to platform_settings.json) · POST test (send a real message) · POST clear-token-cache. Guarded by role:admin + admin.2fa.","Switching the provider takes effect immediately; test returns ok:true per provider; no password, token or private key is reachable through any endpoint.",Must,3
P3E,P3E-E1: Email Providers,Task,"Configure both providers and domain authentication [launch gate]","Set SMTP and Gmail credentials so failover has somewhere to fail over to. Publish SPF, DKIM and DMARC for the sending domain. Verify Google Workspace 'Publish → Gmail API → Send mail as your users' for the Gmail sender, and grant domain-wide delegation if using service_account mode.","A test message is delivered through each provider independently; DMARC passes alignment; Gmail does not return 403 sender-not-authorised.",Must,3
P3E,P3E-E1: Email Providers,Story,"Tests — email provider layer","MailProviderServiceTest (resolution order, admin override precedence, chain filtering, isConfigured per mode) · GmailApiTransportTest (Http::fake, payload shape, exception on 4xx) · EmailOtpMailTest (cooldown throttle, clearThrottle on consumption) · AuthEmailTest (verify-email, forgot/reset password, OTP send and verify).","All four suites pass; Mail::fake and Mail::assertSent work without overriding the test mailer.",Must,5
```

### Epic P3E-E2: Google Sign-In (P0 — moved from P4-E1)

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P3E,P3E-E2: Google Sign-In,Story,"Create social_accounts migration and drop users.google_id","New join table with unique (provider, provider_user_id), encrypted access/refresh tokens, and a snapshot of email/name/avatar. Drops the prototype users.google_id column in the same migration. Back-fill existing Google links in production before dropping.","php artisan migrate runs clean; social_accounts exists; users.google_id is gone; a duplicate (provider, sub) insert is rejected by the DB; production rows are back-filled before the drop.",Must,5
P3E,P3E-E2: Google Sign-In,Story,"Create SocialAccount model","Fillable, encrypted casts on access_token and refresh_token, both in $hidden, user() relation, isGoogle() helper, google()/forProvider() scopes, registered in the morph map as social_account.","A round-trip read/write encrypts at rest; toArray() excludes both tokens; the model appears in the morph map.",Must,2
P3E,P3E-E2: Google Sign-In,Story,"Implement GoogleAuthService ID-token verification","verifyIdToken performs six checks: JWT structure · alg pinned to RS256 (never trusted from the header) · signature against Google JWKS (24h cache, refetch on unknown kid, fails closed) · aud matches GOOGLE_CLIENT_ID · exp honoured with 60s clock skew · email_verified is true. Optional GOOGLE_WORKSPACE_HD check for single-tenant deployments.","Each of the six checks rejects with its own distinct reason; an alg of none or HS256 is rejected; a token minted for another client id is rejected; a JWKS fetch failure fails closed rather than skipping verification.",Must,5
P3E,P3E-E2: Google Sign-In,Story,"Implement account resolution and linking rules","Known sub → sign in and refresh the snapshot. Unknown sub + verified email matching an existing SportX account → link and sign in. Otherwise create. pending accounts are linked but refused login with 403 PENDING_APPROVAL; suspended/deleted return 403 ACCOUNT_DISABLED; role on signup is validated against GOOGLE_ALLOWED_ROLES.","Linking only happens when the Google email is verified AND the SportX account has already verified that email; a pending coach cannot bypass the approval gate via Google; an invalid role returns 422.",Must,5
P3E,P3E-E2: Google Sign-In,Task,"Remove google_id from the User model","Drop google_id from User $fillable and $hidden now that social_accounts is authoritative.","No reference to google_id remains in app/Models/User.php; the morph map includes social_account.",Must,1
P3E,P3E-E2: Google Sign-In,Task,"Configure OAuth clients and consent screen [launch gate]","Enable the Google People API. Configure the OAuth consent screen (External, with test users for dev). Create three clients: Android (package name + SHA-1), iOS (bundle ID) and Web. Set GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_ALLOW_SIGNUP and GOOGLE_DEFAULT_ROLE; set GOOGLE_WORKSPACE_HD for single-tenant deployments.","Sign-in is attempted with each platform client; the consent screen shows the email and profile scopes only; no Drive, Gmail or Calendar scope is requested.",Must,3
P3E,P3E-E2: Google Sign-In,Story,"Flutter — add google_sign_in and platform configuration","Add google_sign_in pinned explicitly (the caret range spanning v7 changes the API surface). Populate the currently empty oauth_client array in google-services.json so Android receives a serverClientId. Configure serverClientId in build.gradle.kts and REVERSED_CLIENT_ID plus the URL scheme in Info.plist.","Android no longer fails with DEVELOPER_ERROR; iOS returns a credential on sign-in; the package name and bundle ID match the OAuth clients exactly.",Must,3
P3E,P3E-E2: Google Sign-In,Story,"Flutter — implement signInWithGoogle in AuthNotifier","Call the native account picker, obtain the ID token, POST it to /auth/google, then run the SAME post-login sequence as password login: persist the token, call checkAuth(), and register the FCM device token so push attaches to the new session.","Signing in with Google produces the same app state as password login, including a registered device token; a null credential surfaces a clear error.",Must,3
P3E,P3E-E2: Google Sign-In,Story,"Flutter — add the Continue with Google button","Shared widget on the Sign Up and Login screens, below the primary action, separated by an or rule. Sign Up must capture the role before the button is tapped because role drives approval routing.","The button completes sign-in on both Android and iOS; a returning user with an existing SportX account is linked rather than duplicated; the role is passed through on signup.",Must,2
P3E,P3E-E2: Google Sign-In,Story,"Tests — Google sign-in","Fake the verified-claims boundary rather than minting real RS256 JWTs: known identity, link to a verified account, pending → 403, suspended → 403, role outside the allow-list → 422, repeat login reuses social_accounts. Cover the RSA/JWKS path separately with a locally generated key pair against a stubbed JWKS endpoint.","All failure modes return their documented status code; no test requires network access.",Must,5
```

### Epic P3E-E3: FCM Push Notifications

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P3E,P3E-E3: FCM Notifications,Story,"Extend notifications table for push","Add channel, category, image_url, priority, metadata, pushed_at and push_status. Widen type from enum(3) to VARCHAR(40) so the full notification vocabulary fits without a migration per type. Add a (type, created_at) index for the reminder sweeper.","php artisan migrate runs clean; an existing enum row migrates without data loss; every type in the FCM doc can be written.",Must,3
P3E,P3E-E3: FCM Notifications,Story,"Harden user_device_tokens","Make token UNIQUE after collapsing existing duplicates (keep the most recent), and add last_seen_at plus failure_count. FCM tokens identify exactly one app installation, so duplicates let one user's device receive another user's notifications after a reinstall.","The unique constraint is added without error on the existing dataset; re-registering a token from a new user transfers the device rather than duplicating the row.",Must,3
P3E,P3E-E3: FCM Notifications,Story,"Rewrite FCMService for FCM HTTP v1","Replace the messages:sendMulticast call, which does not exist in HTTP v1 and 404'd while reporting success, with one messages:send per token. Add Android channel_id mapping per notification type, APNs headers (apns-priority, apns-push-type, apns-sound), topic sending and access-token caching.","A push reaches a real device on both platforms; requests are chunked at FCM_BATCH_SIZE (500); a genuine failure is surfaced through push_status instead of being swallowed.",Must,5
P3E,P3E-E3: FCM Notifications,Story,"Implement token lifecycle handling","UNREGISTERED, INVALID_ARGUMENT and SENDER_ID_MISMATCH retire the token immediately. Transient errors (QUOTA_EXHAUSTED, RESOURCE_EXHAUSTED) increment failure_count and retire only after FCM_MAX_RETRIES. Logout deactivates every token for the user.","A device in aeroplane mode keeps a valid registration; a token FCM reports as permanently dead is retired on the first failure; logout leaves no live channel.",Must,5
P3E,P3E-E3: FCM Notifications,Story,"Implement notification preference resolution","NotificationService writes the row first (source of truth), then evaluates preferences before dispatching: hard overrides for account_action and the registration types always deliver in-app; per-type channel defaults; user overrides for channels and categories. Send NotificationFallbackMail when push_status is no_devices or failed.","Disabling a category in Settings suppresses that push; a user with no device token receives the email fallback; account and registration decisions cannot be switched off.",Must,5
P3E,P3E-E3: FCM Notifications,Story,"Implement SendPushNotification job and pruning jobs","Chunked queued job with retries and backoff that records pushed_at and push_status. PruneStaleDeviceTokensJob retires tokens inactive for DEVICE_TOKEN_TTL_DAYS; PruneNotificationRowsJob deletes rows older than NOTIFICATION_RETENTION_DAYS. Both scheduled daily.","A 500-token fan-out completes off the request thread; stale tokens are retired at the TTL boundary; push_status reads sent in admin stats after a successful test push.",Must,3
P3E,P3E-E3: FCM Notifications,Story,"Notification preferences API and admin delivery stats","GET/PUT /me/notification-preferences returning the resolved preference set (hard overrides → type defaults → user overrides); POST /me/device-tokens/subscribe and /test; GET /admin/notifications/stats by type and push_status.","The resolved set matches the documented merge order; hard overrides are visible so the UI can mark those rows non-disableable.",Must,3
P3E,P3E-E3: FCM Notifications,Story,"Wire notification types to domain events","Emit registration_approved/rejected, trial and tournament moderation results, account_action and broadcast. Admin approve/reject previously produced no notification of any kind; account actions and registration decisions are hard overrides and always deliver.","Approving a registration reaches the applicant as in-app + push + email; a suspended account receives AccountRejectedMail.",Must,5
P3E,P3E-E3: FCM Notifications,Story,"Flutter — local notification display","Add flutter_local_notifications for system-tray display. Fix Firebase.initializeApp which is currently called with no options: so DefaultFirebaseOptions is unused and web and tests fail. Add Darwin settings with presentAlert for foreground. Wire getInitialMessage and onMessageOpenedApp to deep links via action_url and category.","A backgrounded app shows a visible system notification; tapping it deep-links to the right screen and re-authorizes server-side; web and tests initialise without error.",Must,5
P3E,P3E-E3: FCM Notifications,Task,"Flutter — Android permissions and channel alignment [launch gate]","Declare POST_NOTIFICATIONS in AndroidManifest.xml — requestPermission is a silent no-op on Android 13+ without it. Align the client channel IDs exactly with the backend: sportx_default, sportx_enquiries, sportx_reminders, sportx_updates, sportx_announcements.","Push arrives on Android 13+ (the most common cause of works-on-12-not-13 is this missing declaration); no notification is silently dropped due to a channel-ID mismatch.",Must,2
P3E,P3E-E3: FCM Notifications,Task,"Raise FCM quota [launch gate]","Default quota allows roughly 10000 messages.send per day. A broadcast larger than the allowance fails silently, which is unacceptable for an announcement to the whole user base.","Quota is above the expected peak broadcast volume; a full-base broadcast completes without partial failure.",Must,2
P3E,P3E-E3: FCM Notifications,Task,"Upload APNs auth key to Firebase [launch gate]","iOS dev builds receive push; release builds require an APNs auth key (p8) uploaded and associated with the app.","Push arrives on a physical iOS device on a release/TestFlight build.",Must,2
P3E,P3E-E3: FCM Notifications,Story,"Tests — notification system","FCMServiceTest (payload shape, Android channel mapping, APNs headers, UNREGISTERED retires, QUOTA_EXHAUSTED increments and does not retire) · NotificationServiceTest (row always written, preferences honoured, hard overrides, fallback only on no_devices/failed) · NotificationPreferenceTest (merge order) · NotificationControllerTest (inbox, unread_count, cross-user access → 403, idempotent mark-read) · DeviceTokenTest (upsert, transfer, logout) · PruneStaleDeviceTokensJobTest (TTL boundary).","No test touches the network; Queue::fake or the database queue driver is used throughout.",Must,5
```

---

## Phase 4 — Polish

> Google sign-in moved out of this phase — it is **P0** and tracked in **P3E-E2** (it was P1-E1 / P4-E1 before).

```csv
Phase,Epic,Issue Type,Summary,Description,Acceptance Criteria,Priority,Story Points
P4,P4-E1: Polish,Story,"Implement forgot password flow","S5 forgot password → email reset link → reset password.","Reset email sent; link expires in configurable time; password changed successfully.",Must,2
P4,P4-E1: Polish,Task,"Security hardening — rate limiting","Apply rate limits per Security-and-NonFunctional.md §3. Verify 429 responses with Retry-After headers.","All auth endpoints rate-limited; 429 returned when exceeded; headers present.",Must,2
P4,P4-E1: Polish,Task,"Performance optimization — index review","Review all query hotspots; add missing indexes; optimize N+1 queries with eager loading.","All list/detail queries under P95 targets from performance doc.",Should,3
P4,P4-E1: Polish,Task,"Set up monitoring and error tracking","Deploy Sentry (or equivalent) for error tracking; configure APM for Laravel.","Exceptions captured; dashboard shows error trends; alerts configured.",Should,2
P4,P4-E1: Polish,Task,"Load testing","Simulate 1000+ concurrent users on key endpoints (search, registration, login).","P95 latency within targets; no 5xx errors under load.",Should,3
```

---

## Ticket Count Summary

> Counts below are **computed from the CSV blocks in this file**, not hand-maintained — the previous summary had drifted (it understated P0, P1 and P2 by 1, 2 and 3 tickets respectively). Re-derive after any ticket change.

| Phase | Epics | Stories | Tasks | Total | Points |
|---|---|---|---|---|---|
| P0 Foundation | P0-E1, P0-E2 | 8 | 2 | 10 | 38 |
| P1 Discovery | P1-E1–E5 | 23 | 1 | 24 | 66 |
| P2 Actions + v3 modules | P2-E1–E11 | 34 | 0 | 34 | 142 |
| P3 Admin + Reminders | P3-E1, P3-E2 | 14 | 0 | 14 | 63 |
| **P3E Platform Integrations** | **P3E-E1, P3E-E2, P3E-E3** | **25** | **8** | **33** | **119** |
| P4 Polish | P4-E1 | 1 | 4 | 5 | 12 |
| **Total** | **24** | **105** | **15** | **120** | **440** |

> Story points are directional estimates (1=trivial, 2=small, 3=medium, 5=large, 8=complex). Adjust based on team velocity.
>
> **Note (v3):** `sponsor` role removed; `scout` added. Sponsor epic P2-E6 is repurposed to provider/opportunity management. New v3 P0 modules (opportunities, programs, facilities, social, follow/connect, chat, leaderboard, blocks/reports, verification queue, user management, positions) are tracked in P2-E8–E11 and P3-E1. See `Backend-Feature-Delta.md` §9 for build order.
>
> **Note (2026-10):** Phase 3E adds 33 tickets across three epics — email providers (SMTP + Gmail), Google sign-in (promoted P1 → P0, out of P4-E1) and FCM notifications. Five tickets are marked **[launch gate]**: they are credential or configuration steps, not build work, and each blocks a production release (FCM quota AS-67, APNs key AS-68, domain auth + Gmail send-as AS-59, Android notification permission AS-72, OAuth clients AS-64). **AS-60 (SMS vendor) is not a ticket** — it is a purchase decision that blocks `channel=phone` OTP entirely, and is tracked in `PHASE_WISE_IMPLEMENTATION_PLAN.md`.
