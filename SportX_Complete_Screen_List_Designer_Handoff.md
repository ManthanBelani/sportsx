# SportX — Complete Screen List for Designer (New App Design Handoff)

> **Purpose:** Single source-of-truth for a designer to redesign the whole SportX app from scratch.
> **Sources audited:** `sportx_app/lib/**` (Flutter, ~140 screens, `core/router.dart` = 100+ routes) + `sportsx-design-v1/**` (~90 HTML mockups) + `DESIGN_IMPLEMENTATION_STATUS.md`, `ROLE_BASED_IMPLEMENTATION.md`, `BACKEND_INTEGRATION_MISSING_SCREENS.md`.
> **Roles in app:** Athlete (primary consumer) · Coach · Academy · Organizer · Sponsor · Talent Scout · Admin (web-style panel inside app).
> **Bottom-tab shell (Athlete):** Home · Search (Universal Search) · Saved · Activity (Activity Hub) · Profile.
> **Other roles** land on their own Dashboard instead of the athlete shell (see Router redirect logic).

---

## Table of Contents

1. [App Map / Information Architecture](#1-app-map--information-architecture)
2. [Global Design System Notes (for designer)](#2-global-design-system-notes-for-designer)
3. [A — Launch, Auth & Onboarding (11 screens)](#a--launch-auth--onboarding-11-screens)
4. [B — Home, Search, Discovery (6 screens)](#b--home-search-discovery-6-screens)
5. [C — Directories & Detail Pages (16 screens)](#c--directories--detail-pages-16-screens)
6. [D — Registration, Enquiry & Application Flows (12 screens)](#d--registration-enquiry--application-flows-12-screens)
7. [E — Athlete Workspace (6 screens)](#e--athlete-workspace-6-screens)
8. [F — Coach Workspace (14 screens)](#f--coach-workspace-14-screens)
9. [G — Academy Workspace (7 screens)](#g--academy-workspace-7-screens)
10. [H — Organizer Workspace (10 screens)](#h--organizer-workspace-10-screens)
11. [I — Sponsor Workspace (Athlete side + Sponsor side, 12 screens)](#i--sponsor-workspace-12-screens)
12. [J — Talent Scout Workspace (8 screens)](#j--talent-scout-workspace-8-screens)
13. [K — Social, Chat & Connections (8 screens)](#k--social-chat--connections-8-screens)
14. [L — Personal Productivity: Saved, Activity, Notifications, Settings (6 screens)](#l--personal-productivity-6-screens)
15. [M — Admin Panel (15 screens)](#m--admin-panel-15-screens)
16. [N — Marketing / Web-only (reference, not in-app)](#n--marketing--web-only-reference-not-in-app)
17. [O — Full Screen Inventory Table (route → file → design ref)](#o--full-screen-inventory-table)
18. [P — Designer Checklist & Screen States to Design](#p--designer-checklist--screen-states-to-design)

**Total in-app screens to design: ~124** (plus marketing/web reference).

---

## 1. App Map / Information Architecture

```
Splash
└── Role Selection (Athlete/Coach/Academy/Organizer/Sponsor/Talent Scout)
    ├── Sign Up (role param) ──► OTP ──► Role Onboarding ──► Dashboard/Home
    └── Login ──► Dashboard/Home

Athlete shell (bottom nav):
Home ─┬─ Academy Directory ── Academy Detail ── Enquire
      ├─ Coach Directory ── Coach Detail ── Enquire / Enroll
      ├─ Trial Directory ── Trial Detail ── Trial Registration ── Confirmation
      ├─ Tournament Directory / Calendar ── Tournament Detail ── Tournament Registration ── Confirmation
      ├─ Sponsorship List ── Sponsorship Detail ── Apply
      ├─ Scholarship List ── Scholarship Detail (external apply)
      └─ Venue List ── Venue Detail
Search (Universal Search + Filter) · Saved · Activity Hub (My Registrations/Enquiries) · Profile

Coach: Dashboard(Home/Schedule/Enquiries/Profile) ─ Enquiry Inbox/Detail ─ Enrollment Requests ─ Profile Edit ─ Credentials/Facilities/Showcase ─ Sponsor Directory
Academy: Dashboard ─ Post Trial ─ My Trials ─ Registrant List/Detail ─ Profile Edit ─ Enquiry Inbox/Detail
Organizer: Dashboard ─ Post/Edit Tournament ─ My Tournaments ─ Registration Mgmt ─ Capacity Mgmt ─ Results Publish/View ─ Analytics ─ Profile
Sponsor: Dashboard ─ Post Sponsorship ─ My Sponsorships ─ Applications Inbox/Detail ─ Athlete Discovery ─ Athlete Profile View ─ Shortlist
Talent Scout (own shell): Dashboard ─ Discovery ─ Shortlist ─ Connections ─ Profile ─ Connect dialog ─ Athlete Profile View
Social (all): Create Post ─ Post Detail ─ Chat List ─ Chat ─ Connections/Requests/Scout Requests ─ View Profile
System: Notifications ─ Settings ─ Help & Support ─ Media Gallery ─ Add Achievement
Admin (/admin/*): Login ─ Dashboard ─ Users ─ User Verify ─ Approvals ─ Moderation ─ Report Detail ─ Reports/Analytics ─ Opp Queue/Review ─ Compose Notification ─ Targeting ─ Content Picker/List
```

---

## 2. Global Design System Notes (for designer)

Design a new visual language (do NOT copy old HTML pixel-for-pixel), but preserve this functional contract:

- **Shells:** (1) `MainShell` athlete bottom nav (5 tabs, active = blue `#1677FF`), (2) `ScoutShell` (Dashboard/Discovery/Shortlist/Connections/Profile), (3) Coach 4-tab `NavigationBar` (Home/Schedule/Enquiries/Profile), (4) `AdminWebLayout` (AppBar + stat cards + pills + admin cards).
- **Templates used in code (recreate as components):** `DirectoryListTemplate` (title + filter btn + infinite list rows), `DetailPageTemplate` (hero + tags + details map + about + address + save + bottom CTA + call), `FormPageTemplate` (labelled sections + bottom Save/Publish bar), `AsyncStateView` (skeleton → content / empty / error + retry).
- **Status pills (keep semantics + colors):** Pending/Under-review = amber/orange · Approved/Verified/Published/Connected = green · Rejected/Closed = red · Draft = grey · New/Unread dot = blue.
- **Cards carry:** avatar/logo → name/title → sport·city meta → fee/date meta → status chip → chevron/popup menu.
- **Every list needs:** search field, filter chips or filter button → filter sheet, pull-to-refresh, empty state (icon + text + CTA), error state + Retry, pagination ("load more").
- **Every form needs:** inline validation, upload tiles (photo/PDF, 10 MB hint), date/time pickers, consent checkbox where needed (trial registration), Save-as-Draft vs Publish dual CTA for posting screens.
- **Accessibility:** visible focus, 44pt targets, labeled icons, heading hierarchy.

Wireframe legend used below: `[ ]` button · `( )` input · `{ }` chip/pill · `▭` card · `≡` list · `◉` avatar · `★` rating/save · `⌕` search · `⚙` settings · `🔔` notifications.

---

## A — Launch, Auth & Onboarding (11 screens)

### A1. Splash Screen — `/splash` — `auth/splash_screen.dart` — ref: `splash-screen.html`
**Description:** Branded launch gate shown while session/auth initializes; auto-routes (no user action). All roles.
**Key sections:** Full-bleed gradient, trophy/logo mark, "SportX" + tagline, loading dots.
**States:** loading only.
```
┌──────────────┐
│              │
│    🏆 LOGO   │
│    SportX    │
│ tagline...   │
│   ● ● ●      │
└──────────────┘
```

### A2. Role Selection — `/role-selection` — `auth/role_selection_screen.dart` — ref: `role-selection.html`
**Description:** First-run choice that personalizes sign-up/onboarding. 6 role cards. Unauthenticated prospect.
**Sections:** Header ("Choose your role"), 6 cards (Athlete/Coach/Academy/Organizer/Sponsor/Talent Scout w/ icon + 1-line blurb), Log-in link, sticky Continue.
**Actions:** Continue → `/sign-up?role=`; Log in → `/login`.
```
┌──────────────┐
│Choose role   │
│▭ Athlete     │
│▭ Coach       │
│▭ Academy     │
│▭ Organizer   │
│▭ Sponsor     │
│▭ Talent Scout│
│[ Continue  ] │
│ Have account? Log in │
└──────────────┘
```

### A3. Sign Up — `/sign-up` — `auth/sign_up_screen.dart` — ref: `shared/sign-up.html`
**Description:** Email+password account creation for chosen role (role passed as param). Validates, creates session → onboarding.
**Sections:** Brand header, (Email), (Password + show/hide), Terms checkbox, [Create Account], footer "Log in".
```
┌──────────────┐
│< Sign Up     │
│ Logo SportX  │
│( Email )     │
│( Password 👁)│
│☑ Terms       │
│[ Create Acct ]│
└──────────────┘
```

### A4. Login — `/login` — `auth/login_screen.dart` — ref: `shared/login.html`
**Description:** Returning-user auth for all roles. Forgot-password link (placeholder), role-aware redirect to dashboard/home.
**Sections:** Same as Sign Up + "Forgot password?" + [Log In].
```
┌──────────────┐
│< Log In      │
│( Email )     │
│( Password 👁)│
│ Forgot pwd?  │
│[ Log In ]    │
│No acct? Sign up│
└──────────────┘
```

### A5. OTP Verification — `/otp` (route via auth flow) — `auth/otp_screen.dart` — ref: `shared/otp-verification.html`
**Description:** 6-box email OTP with 60-sec resend timer. Newly registered / pending-verification users.
**Sections:** Mail icon, "Code sent to {email}", 6 boxes `[ ][ ][ ][ ][ ][ ]`, countdown "Resend in 0:42", [Verify & Continue], help box.
```
┌──────────────┐
│< Verify      │
│ ✉ code sent  │
│[][][][][][]  │
│Resend in :42 │
│[Verify&Cont.]│
└──────────────┘
```

### A6. Athlete Onboarding Step 1 (Sport + Age) — `/onboarding-1` — `onboarding_sport_age_screen.dart` — ref: `onboarding-sport.html`
**Description:** Athlete identity capture. Step 1 of 2. Mandatory post-signup.
**Fields:** Full Name, DOB picker, Gender {M/F/Other}, Sports grid (multi, from master), Age-group chips. CTA Continue → Step 2.
```
┌──────────────┐
│< Step 1 of 2 │
│( Full name ) │
│( DOB 📅 )    │
│{M}{F}{Other} │
│Sports grid ▦ │
│Age {U12..Open}│
│[ Continue ]  │
└──────────────┘
```

### A7. Athlete Onboarding Step 2 (Skill + Location) — `/onboarding-2` — `onboarding_skill_location_screen.dart` — ref: `onboarding-location.html`
**Description:** Skill level + location. Submit completes onboarding → `/home`.
**Fields:** Skill chips, "Detect location" banner, State dropdown, City dropdown, Popular-city chips. CTA Finish.
```
┌──────────────┐
│< Step 2 of 2 │
│Skill {..}    │
│📍 Detect loc │
│( State ▾ )   │
│( City ▾ )    │
│Popular {..}  │
│[ Finish ]    │
└──────────────┘
```

### A8. Coach Onboarding — `/coach-onboarding` — `coach_onboarding_screen.dart` — ref: `coach/coach-onboarding.html`
**Description:** First-time coach profile + verification. → `/coach-dashboard`. Fields: progress bar, Full Name, Sport chips, City, Contact, Experience (yrs), Qualification, Certification chips, Languages chips, Fee, Bio, "Personal coaching available" switch. CTA [Complete Setup].

### A9. Academy Onboarding — `/academy-onboarding` — `academy_onboarding_screen.dart` — ref: `academy/academy-onboarding.html`
**Description:** Academy creation: Name, Description, Logo picker, Cover picker, Address, City dropdown, Contact, Sports chips, Fee range (optional). CTA [Save & Continue] → dashboard.

### A10. Organizer Onboarding — `/organizer-onboarding` — `organizer_onboarding_screen.dart` — ref: `organizer/organizer-onboarding.html`
**Description:** Organization verification: Org Name, Type dropdown (Federation/Club/School/Private/Other), Reg No, Website, Verification-doc upload (PDF/JPG ≤10 MB) + submitted badge. CTA [Continue].

### A11. Sponsor Onboarding — `/sponsor-onboarding` — `sponsor_onboarding_screen.dart` — ref: `sponsor/sponsor-onboarding.html`
**Description:** Brand setup: Brand Name, Category, Supported-sports chips, Website, Logo upload, Verification-doc upload. CTA [Submit]. (Talent Scout onboarding is in §J.)

---

## B — Home, Search, Discovery (6 screens)

### B1. Home (Athlete feed) — `/home` (tab 1) — `home/home_screen.dart` — ref: `home-dashboard.html`
**Description:** Personalized athlete landing: greeting + sport/age, search entry, recommendation rails. Entry point after onboarding.
**Sections:** SliverAppBar (Hi {name}, bell + saved icons), `⌕ Search` bar → universal search, Recommended carousel, "Trials closing soon" list, Tournaments list, Scholarships list, each with "See all".
```
┌──────────────┐
│Hi Aarav 🔔♡  │
│⌕ Search…     │
│Recommended › │
│▭▭▭ (carousel)│
│Trials closing›│
│≡ trial rows  │
│Tournaments › │
│≡ rows        │
│[Home][Search][Saved][Activity][Profile] (tab bar)│
└──────────────┘
```

### B2. Discover — `/discover` — `home/discover_screen.dart` — (no v1 ref; new)
**Description:** Cross-role discovery (athletes/coaches/sponsors) with quick filters. Used by scouts/organizers too.
**Sections:** `⌕` bar, pills {Athletes/Coaches/Sponsors}, Sport/State/Age filter chips + bottom sheets, 2-col card grid.

### B3. Universal Search — `/universal-search` (tab 2) — `search/universal_search_screen.dart` — refs: `universal-search.html`, `search-results.html`
**Description:** Global search across 7 categories with per-tab counts. All authenticated users.
**Sections:** Search header + filter icon → `/search-filter`, Category tabs w/ counts (All/Academies/Coaches/Trials/Tournaments/Scholarships/Sponsorships), Recent / Trending / Quick-links when empty, result cards → detail.
```
┌──────────────┐
│⌕ query…  [⧩] │
│All(12)|Acad|Coach|Trial|… (scroll tabs)│
│≡ result cards│
└──────────────┘
```

### B4. Search entry (lightweight) — (internal) — `home/search_screen.dart` — ref: `search-results.html` (partial)
**Description:** Thin pre-search screen: search field, Recent Searches + Clear, Trending chips. Submit → Universal Search.

### B5. Search Filter — `/search-filter` — `search/search_filter_screen.dart` — ref: `shared/filter-panel.html`
**Description:** Multi-facet refiner modal/full screen. Sections: Sport chips, City/State pickers, Fee range (switch + slider), Age group, Date From/To, Gender, Rating. CTAs [Apply Filters] (pop), [Clear All].

### B6. Tournament Calendar — `/tournament-calendar` — `tournament/tournament_calendar_screen.dart` — ref: `tournament-calendar.html`
**Description:** Date-based alternative to tournament list. Month navigator + 7-col grid (dots = events, selected/today states), Calendar/List toggle, event cards (icon/title/venue/prize/status). Tap day filters; tap card → detail; pull-to-refresh.
```
┌──────────────┐
│< Tournaments [📅|☰]│
│   < March >  │
│M T W T F S S │
│··●··●·· …    │
│▭ event card  │
│▭ event card  │
└──────────────┘
```

---

## C — Directories & Detail Pages (16 screens)

Pattern for all directories: `DirectoryListTemplate` — title + count, filter button, infinite-scroll rows (thumb, title, subtitle sport·city, meta fee/date, save icon). Detail pattern: `DetailPageTemplate` — hero image, title/sub/verified, tag chips, details grid, About, address, Save, Call (`tel:`), sticky bottom CTA.

| # | Screen (route → file → design ref) | Description (role + purpose + CTA) | Wireframe |
|---|-------------------------------------|-------------------------------------|-----------|
| C1 | Academy Directory `/academies` → `academy_directory_screen.dart` → `academy-directory.html` | Browse/paginate academies. Athlete/public. Filter → `/search-filter`; row → `/academy-detail/:id`. | `⌕? no — title + [⧩] / ≡ rows: ◉ Name / sport·city / ₹/mo` |
| C2 | Academy Detail `/academy-detail/:id` → `academy_detail_screen.dart` → `academy-detail.html` | Single academy: hero cover+logo, Fees/Hourly/Sport/Contact/Email/Website, About, address. CTA [Enquire Now] → `/enquire/academy/:id`. Secondary: Call, Save. | Hero ▓ / Title ✓ / {tags} / Details grid / About / [Enquire Now] |
| C3 | Coach Directory `/coaches` → `coach_directory_screen.dart` → `coach-directory.html` | Browse coaches (name, sport+exp, rate). Row → `/coach-profile-detail/:id`. | Same directory pattern |
| C4 | Coach Detail (legacy athlete view) `/coach-detail/:id` → `coach_detail_screen.dart` → `coach-detail.html` | Older athlete-facing detail + `CoachEnrollmentSection` (plans). CTAs: Enquire/Book, Connect, Call, Save. NOTE: also see richer C5. | Hero / Details / Plans ▭ / [Enquire] |
| C5 | Coach Public Profile (rich) `/coach-profile-detail/:id` → `coach_profile_detail_screen.dart` → `coach-detail.html` (same ref, richer impl) | Full public profile: SliverAppBar photo/verified, exp/rate stats, About, Credentials, Facilities & Programs, Showcase Athletes rail, enrollment plans, contact/share, bottom bar [Connect][Enquire/Book]. Designer: merge C4+C5 into ONE canonical coach profile. | Sliver hero / Stats / About / Credentials / Facilities / Athletes › / [Connect][Enquire] |
| C6 | Trial Directory `/trials` → `trial_directory_screen.dart` → `trial-listings.html` | Browse trials (title, venue·city, date·fee). Row → `/trial-detail/:id`. | Directory pattern |
| C7 | Trial Detail `/trial-detail/:id` → `trial_detail_screen.dart` → `trial-detail.html` | Single trial: tags (sport/age), Date/Deadline/Fee/Age/Spots-left/Contact, venue. CTA [Register for Trial] → `/trial-registration/:id`. | Detail pattern + spots-left bar |
| C8 | Tournament Directory `/tournaments` → `tournament_directory_screen.dart` → (impl; v1 `athlete/tournament-detail` covers detail) | Browse tournaments (title, venue·city, start–end). Row → detail. | Directory pattern |
| C9 | Tournament Detail `/tournament-detail/:id` → `tournament_detail_screen.dart` → `athlete/tournament-detail.html` | Single tournament: tags (sport/format/age), Dates/Format/Prize/Entry/Age, venue. CTA [Register] → registration. | Detail pattern + prize card |
| C10 | Sponsorship Discovery (athlete) `/sponsorships` → `sponsorship_list_screen.dart` → `athlete/sponsorship-list.html` | Athlete browses opportunities: search + sport chips, cards (logo/title/sponsor/sport/amount/benefits/deadline). → detail. | `⌕` + chips + ▭ cards |
| C11 | Sponsorship Detail (athlete) `/sponsorship-detail/:id` → `sponsorship_detail_screen.dart` → `athlete/sponsorship-detail.html` | Sliver header (sponsor/logo/amount), Details, Benefits Included, Eligibility, Required Docs. CTAs: Share, [Apply Now] → `/apply-sponsor/:id`. | Sliver / Benefits ✓ list / [Apply Now] |
| C12 | Scholarship Feed `/scholarships` → `scholarship_list_screen.dart` → `athlete/scholarship-feed.html` | Like C10 for scholarships: search + chips, cards (image/title/sponsor/sport/amount/deadline). | Same as C10 |
| C13 | Scholarship Detail `/scholarship-detail/:id` → `scholarship_detail_screen.dart` → `athlete/scholarship-detail.html` | About, Eligibility, 4-step Application Steps, Documents chips. CTA [Apply Now] (external URL) + Call + Save. | Detail + steps 1-2-3-4 |
| C14 | Venue List `/sports-venues` → `sports_venue_list_screen.dart` → (new, no v1) | Simple venue browser: rows (name/city/Bookable chip). → detail. | `≡ rows` |
| C15 | Venue Detail `/sports-venue-detail/:id` → `sports_venue_detail_screen.dart` → (new) | Tags, rate/contact/amenities. CTA [Book/Enquire] (currently placeholder — designer defines booking flow) + Call + Save. | Detail pattern |
| C16 | Generic Public Profile `/view-profile?type&id` → `view_profile_screen.dart` → `profile-view.html` | Fallback public profile for any athlete/coach: Sliver header, Message btn → chat, Stats (Posts/Connects/Achievements), About, Achievements, Tournament/Performance (if data), Media, Social links. CTAs: Message, Share, Favorite. | Sliver / Stats / About / Media grid |

---

## D — Registration, Enquiry & Application Flows (12 screens)

### D1. Trial Registration — `/trial-registration/:id` — `trial_registration_screen.dart` — ref: `trial-registration.html`
**Description:** Athlete requests trial slot (approval flow). Shows profile card + fee info (Free/Paid + "Approval Required"), fields: Playing Role, DOB picker, Medical conditions, ID-proof upload, Parental-consent ☑ (gating). CTA [Request to Participate] → Confirmation (D12).
```
┌──────────────┐
│< Register    │
│◉ profile card│
│(Role)(DOB📅) │
│(Medical)     │
│[Upload ID]   │
│☑ Parental…   │
│Fee: ₹500 · Approval required│
│[Request to Participate]│
└──────────────┘
```

### D2. Tournament Registration — `/tournament-registration/:id` — `tournament_registration_screen.dart` — ref: `athlete/tournament-registration.html`
**Description:** Individual/Team tournament entry. Toggle {Individual/Team} → conditional Team Name/Manager/Player-count (8–22)/Captain/Coach + Category dropdown + fee/approval notice. CTA [Request to Participate] → Confirmation.

### D3. Registration Confirmation — `/registration-confirmation` — `registration_confirmation_screen.dart` — ref: `registration-confirmation.html`
**Description:** Success screen (trial or tournament via `is_trial` flag). Big ✓, date/time/location card, ref-hash pill (e.g. TRN-8F3K). CTAs [View in Activity] [Back to Home]. No form.

### D4. My Registrations (athlete) — `/my-registrations` — `my_registrations_screen.dart` — (new)
**Description:** Athlete's own entries. Tabs {Tournaments/Trials}, cards with approval chip + rejection reason. Pull-to-refresh.

### D5. Enquire (athlete → coach/academy) — `/enquire/:subjectType/:subjectId/:title` — `shared/enquire_screen.dart` — ref: `athlete/enquire-coach.html`
**Description:** Sends enquiry: subject card, auto-attached profile, Message textarea, Preferred training days (day/time pickers ×3), Age dropdown, Phone. CTA [Send Enquiry] → inbox thread.

### D6. Enquiry Inbox (shared, academy/organizer lens) — `/enquiry-inbox` — `enquiry_inbox_screen.dart` — (v1 academy/coach inbox refs)
**Description:** Tabs {All/New/Replied} w/ counts; rows (avatar/name/message preview/sport/time/badge). → Detail.

### D7. Enquiry Detail (shared) — `/enquiry-detail` — `enquiry_detail_screen.dart`
**Description:** Chat-like thread (me/other bubbles), reply bar [Send]. Minimal — designer should align with Chat (K3) styling.

### D8. Coach Enquiry Inbox — `/coach-enquiry-inbox` — `coach_enquiry_inbox_screen.dart` — ref: `coach/enquiry-inbox.html`
**Description:** Same as D6 but coach-scoped: tabs {All/New/Replied/Closed} w/ counts. → coach enquiry detail.

### D9. Coach Enquiry Detail — `/coach-enquiry-detail` — `coach_enquiry_detail_screen.dart` — ref: `coach/enquiry-detail.html`
**Description:** 1:1 enquiry chat + enquirer card + Quick Replies ("Slots available", "Free trial…") that fill composer. CTA [Send].

### D10. Coach Enrollment (athlete → coach plan) — `/coach-enrollments` (athlete books; coach manages — see F) — `coach_enrollment_screen.dart`
**Description:** Athlete selects coaching plan (plan type/fees) and requests enrollment. Status shown in E (My Coaching Enrollments). Designer: design plan-picker + request sheet + pending/approved/rejected states.

### D11. Apply for Sponsorship — `/apply-sponsor/:id` — `apply_sponsor_screen.dart` — ref: `athlete/apply-sponsor.html`
**Description:** Athlete application: sponsor summary, auto-attached profile card, Pitch Note textarea, optional docs upload. CTA [Submit Application] → confirmation/activity.

### D12. Sponsor Pitch (legacy alt) — `/sponsor-pitch/:id` — `sponsor_pitch_screen.dart` — ref: `athlete/apply-sponsor.html` (same)
**Description:** Older variant of D11 keyed by `sponsorId`. Info banner (auto-attach), pitch textarea, additional link field. Designer: merge D11+D12 into ONE apply screen.

```
Enquiry/Chat thread pattern (D7/D9/K3):
┌──────────────┐
│< Name ✓      │
│▭ enquirer card (coach lens)│
│{Quick replies} (coach lens)│
│  ◀ other msg │
│       me msg ▶│
│( Type…  [Send])│
└──────────────┘
```

---

## E — Athlete Workspace (6 screens)

All under athlete shell tabs or Settings.

### E1. Athlete Profile (My Profile hub) — `/profile` (tab 5) — `athlete/profile_screen.dart` — refs: `profile-view.html`, `athlete/settings.html`
**Description:** Role-adaptive hub (shows role Quick Links for non-athletes too). Header (avatar/verified/sport/age/location + Posts/Connects/Achievements counts), About, Achievements, Tournament History (empty state today), Performance Stats (empty state), Media preview → gallery, Share (share_plus), Quick Links grid, Settings + Logout. CTAs: Edit → `/edit-profile`, Add → `/add-achievement`, See all → `/media-gallery`.
```
┌──────────────┐
│< Profile [⚙] │
│◉ Name ✓      │
│sport·age·city│
│Posts|Conns|Achs│
│About…        │
│Achievements ›│
│Media preview ›│
│Quick Links ▦ │
│[Edit Profile]│
└──────────────┘
```

### E2. Edit Profile — `/edit-profile` — `athlete/edit_profile_screen.dart` — ref: `profile-edit.html`
**Description:** Athlete edit form (GET→PUT profile + sports). Avatar [Change Photo] (upload), Basic (Name/DOB/Gender/Bio/Primary Sport/City/AgeGroup/Skill), Physical (Height/Weight/Dominant side). CTAs [Cancel][Save].

### E3. Add Achievement — `/add-achievement` — `athlete/add_achievement_screen.dart` — (new)
**Description:** Title, Description, Year dropdown (10 yrs), Certificate-photo uploader. CTA [Add Achievement].

### E4. Media Gallery — `/media-gallery` — `athlete/media_gallery_screen.dart` — ref: `athlete/media-gallery.html`
**Description:** Tabs {Photos(n)/Videos(n)/Achievements(n)}, grid + Add tile, achievements list, Tips card, Reorder mode (drag + Cancel/Save). Actions: Add, Delete (trash overlay), Reorder.

### E5. My Coaching Enrollments — `/my-coaching-enrollments` — `my_coaching_enrollments_screen.dart` — (new)
**Description:** Athlete read-only enrollment requests: cards (coach/plan/fees + approval chip + rejection reason). No CTA except refresh.

### E6. Athlete Sponsorship Applications (TO DESIGN — backend ready, UI missing/partial)
**Description:** Per `BACKEND_INTEGRATION_MISSING_SCREENS.md`: list (`GET /me/applications`: sponsorship title/sport/logo/deadline + status pending/reviewed/shortlisted/rejected) + detail (pitch note, benefits, eligibility, amount). Currently only `shortlist_screen.dart` (sponsor lens) exists — designer must design athlete-lens list + detail. Treat as C10/C11 "My Applications" tab.

---

## F — Coach Workspace (14 screens)

### F1. Coach Dashboard — `/coach-dashboard` — `coach_dashboard_screen.dart` — ref: `coach/coach-dashboard.html`
**Description:** 4-tab `NavigationBar` (Home/Schedule/Enquiries/Profile). Home: welcome header+photo, stats (Total/ThisMonth/AvgRating), Profile-completeness bar + tips, Quick Actions, Recent Enquiries. Schedule: weekly availability + edit. Enquiries/Profile tabs embed inbox + profile summary. Icons: Settings, Notifications.
```
┌──────────────┐
│Hi Coach ◉ ⚙🔔│
│Stats [12|3|4.8★]│
│Profile 80% ████░│
│Quick actions ▦│
│Recent enquiries ≡│
│[Home][Schedule][Enq][Profile]│
└──────────────┘
```

### F2. Coach Profile Edit (full) — `/coach-profile-edit` — `coach_profile_edit_screen.dart` — ref: `coach/coach-profile-edit.html`
**Description:** Full editor (PUT coach-profile): photo (instant persist), Personal (First/Last/Headline/Location/Contact), Professional (Sport/City/Experience/Qualification/Certs/Languages/Personal-coaching switch), Fees (per-session/monthly/quarterly), Bio, Weekly availability grid (Mon–Sun × slots). CTAs [Change Photo][Save][Log out].

### F3. Coach Profile Posting (simplified listing edit) — `/edit-coach-profile` — `coach_profile_posting_screen.dart` — (new)
**Description:** Slim "Edit My Listing": First/Last, Headline, Sport/City/Area, Experience, Fee session/monthly/quarterly, Bio, availability note. Designer may merge F2+F3 (Full vs Quick edit).

### F4. Manage Enrollments — (route `/coach-enrollments`) — `coach_enrollment_screen.dart` — (new)
**Description:** Approve/reject athlete plan requests. Tabs {Pending/Active/Rejected}, cards (athlete/plan/fees/status + notes + rejection reason). Actions: [Approve] (date picker), [Reject] (reason dialog).

### F5/F6. Enquiry Inbox + Detail — see D8/D9.

### F7. Add Credential — `/add-credential` — `add_credential_screen.dart` — (new)
**Description:** Title, Issuing Authority, Year, Certificate upload. CTA [Save Credential].

### F8. Edit Facilities & Programs — `/edit-facilities` — `edit_facilities_screen.dart` — (new)
**Description:** Repeating cards (Name/Description/Type={facility/program}). Actions [+ Add Another][Delete][Save Facilities].

### F9. Showcase Athletes — `/showcase-athletes` — `showcase_athletes_screen.dart` — (new)
**Description:** Curate featured athletes: search field, selected horizontal chips, results list w/ select toggle, empty states. CTA [Save].

### F10. Sponsor Directory (coach lens) — `/sponsor-directory-coach` — `sponsor_directory_screen.dart` — (new)
**Description:** Coach finds sponsorships: search + Industry chips {All/Sportswear/Nutrition/Finance/Tech/Media}, sponsor cards → `/sponsor-pitch/:id`.

### F11. Coach Public Profile — see C5. F12. Coach Detail legacy — see C4. F13. Coach Onboarding — see A8. F14. Coach Schedule (tab inside F1, design as sub-view: week grid Mon–Sun × Morning/Evening slots + [Edit Availability]).

---

## G — Academy Workspace (7 screens)

### G1. Academy Dashboard — `/academy-dashboard` — `academy_dashboard_screen.dart` — ref: `academy/academy-dashboard.html`
**Description:** Owner home: academy banner (logo/name/sport·city), stats (Active/Total/Drafts), Quick Actions, My Trials (3 recent), bottom 4-tab bar. CTAs: [Post Trial]→`/post-trial`, [My Trials], [Enquiries], [Edit Listing], Notifications, Logout.

### G2. Post Trial — `/post-trial` — `trial_posting_screen.dart` — ref: `academy/trial-posting-form.html`
**Description:** Create trial (academy/organizer): Title, Sport, Eligibility age chips {U-10…Open}+free text, Date+Time, Deadline, City, Venue, Entry Fee, Max Registrations, Required-docs checkboxes, Contact. Dual CTA: [Save as Draft] (status=draft) vs [Publish Trial] (published).

### G3. My Trials (manage) — `/my-trials` — `my_trials_management_screen.dart` — ref: `academy/my-trials.html`
**Description:** Owner CRUD: trial cards (title/date/registrations/status badge + popup menu). FAB [+ New Trial]; menu: Edit / View Registrants / Publish / Close.

### G4. Registrant List — `/registrant-list` — `registrant_list_screen.dart` — ref: `academy/registrant-list.html`
**Description:** Trial entries w/ inline approve/reject: trial header + capacity progress, registrant cards (photo/age/gender/phone/docs + approval status). Actions: row → detail, [Approve], [Reject + reason dialog].

### G5. Registrant Detail — `/registrant-detail` — `registrant_detail_screen.dart` — ref: `academy/registrant-detail.html`
**Description:** Single registration: Registration #id, athlete summary, Reminder/ICS row. Actions: [Toggle Reminder] [Download ICS] [Reject] [Mark as Verified].

### G6. Academy Profile (owner read-only) — `/academy-profile` — `academy_profile_screen.dart` — (new)
**Description:** Header (logo/name/sport·city/address), StatsRow (Trials/Active/Drafts), About, Sports tags, Facilities tags, Details grid (Fee/Timings/AgeGroups/City/Address), Contact rows. Pencil → `/edit-academy-profile`.

### G7. Academy Listing Edit — `/edit-academy-profile` — `academy_profile_posting_screen.dart` — ref: `academy/academy-listing-edit.html`
**Description:** Edit listing: Basic (name/city/address/contact/description), Sports chips, Facilities chips (Turf/Gym…), Fee range, Age groups {5-8…20+}, Timings, Logo/Cover pickers. CTA [Save Changes] → toast "Academy Updated!".

---

## H — Organizer Workspace (10 screens)

### H1. Organizer Dashboard — `/organizer-dashboard` — `organizer_dashboard_screen.dart` — ref: `organizer/organizer-dashboard.html`
**Description:** Command center (trials+tournaments), 4 tabs (Home/Events/Analytics/Profile). Home: analytics stats, capacity bar, pending banner, deadline alert, 8 Quick Actions, Capacity-by-Category preview, My Trials/Tournaments w/ inline Registrations/Capacity/Results shortcuts. Events: lists + popup menu. Analytics preview. Profile: org card/verified/menu/logout.

### H2. Post Tournament — `/post-tournament` — `tournament_posting_screen.dart` — ref: `organizer/tournament-create.html`
**Description:** Create tournament. Sections: Details (name/sport/format/city/gender/dates/venue/description), Prize Pool (total+1st/2nd/3rd), Entry Fee & Categories (fee, default capacity, dynamic name+ageGroup+capacity rows +Add), Deadline. Bottom bar [Save as Draft][Publish Tournament].

### H3. Edit Tournament — `/edit-tournament/:id` — `tournament_edit_screen.dart` — (new)
**Description:** Same fields as H2 preloaded (+ capacity), overflow menu, status footer. Actions: [Save], [Publish]/[Close].

### H4. My Tournaments — `/my-tournaments` — `my_tournaments_management_screen.dart` — ref: `organizer/my-tournaments.html`
**Description:** Sections {PUBLISHED/DRAFTS}; cards (dates/venue/teams/collected/capacity bar + popup). FAB [+ New]; menu: Edit / Registrations / Capacity / Results / Publish / Close.

### H5. Registration Management — `/registration-management` — `registration_management_screen.dart` — ref: `organizer/registration-management.html`
**Description:** Approve/reject tournament entries: header (title/date·venue, Registered/Spots Left), search, tabs {Pending/Approved/Rejected} grouped by category, cards (avatar/team/participation·status, approval+payment chips, rejection reason), Export CSV. Actions [Approve][Reject+reason].

### H6. Capacity Management — `/capacity-management` — `capacity_management_screen.dart` — ref: `organizer/capacity-management.html`
**Description:** Spots per category + waitlist: header card, per-category card (name, Spots slider 0–32 + registered/max, waitlist toggle, info banner). CTA [Save].

### H7. Results Publishing — `/results-publishing` — `results_publishing_screen.dart` — ref: `organizer/results-publishing.html`
**Description:** Enter scores, publish winners: header (title, approved count, category dropdown), MATCHES list (TeamA [scoreA–scoreB] TeamB), warning if 0 approved. CTA [Publish Results].

### H8. Results View (shared) — `/results-view` — `results_view_screen.dart` — (new)
**Description:** Published results: Podium 🥇🥈🥉 + Full Standings (rank avatar + name), empty state, pull-to-refresh.

### H9. Organizer Analytics — `/organizer-analytics` — `organizer_analytics_screen.dart` — (new)
**Description:** KPIs: summary grid (Total/Pending/Rate/Tournaments/Trials/Revenue), Breakdown bar (Approved/Pending/Rejected), Capacity Utilization bar, Events Status (Published/Drafts/Closed), deadline alert, Capacity-by-Category bars. [Refresh].

### H10. Organizer Profile — `/organizer-profile` — `organizer_profile_screen.dart` — (new)
**Description:** Edit org profile (prefilled): Org Name*, Type (federation/club/other), Reg No, Website, info banner (docs via support). AppBar [Save].

---

## I — Sponsor Workspace (12 screens)

### Athlete side
- **I1. Sponsorship List** `/sponsorships` — see C10.
- **I2. Sponsorship Detail** `/sponsorship-detail/:id` — see C11.
- **I3. Apply** `/apply-sponsor/:id` — see D11 (+ legacy D12).
- **I4. My Sponsorship Applications (TO DESIGN)** — see E6.

### Sponsor side
- **I5. Sponsor Dashboard** `/sponsor-dashboard` — `sponsor_dashboard_screen.dart` — ref: `sponsor/sponsor-dashboard.html`. Brand banner, stats (Active/Applications/Shortlisted), Quick Actions, My Sponsorships preview, Recent Applications. CTAs: New Listing / Applications / Discover / Shortlist / View All / Logout / Notifications.
- **I6. Sponsor Onboarding** `/sponsor-onboarding` — see A11.
- **I7. Sponsorship Posting (create/edit)** `/sponsor-posting` — `sponsorship_posting_screen.dart` — ref: `sponsor/sponsorship-create.html`. Title, Sports multi-chip, Grant Amount, Deadline picker, Eligibility, dynamic Benefits list [+ Add Benefit]. CTA [Save & Publish].
- **I8. My Sponsorships (manage)** `/my-sponsorships` — `my_sponsorships_management_screen.dart` — (new). Status-colored cards (draft/published) + popup (Edit/View Applications/Publish/Close). FAB [+ New Sponsorship].
- **I9. Athlete Discovery** `/athlete-discovery` — `athlete_discovery_screen.dart` — ref: `sponsor/athlete-discovery.html`. Filter chips (Sport/Age/City/Level), athlete cards → profile view.
- **I10. Athlete Profile View (sponsor lens)** `/athlete-profile-view` — `athlete_profile_view_screen.dart` — ref: `sponsor/athlete-profile-view.html`. Header avatar/sport, Achievements, Media Gallery. CTA [Shortlist].
- **I11. Applications Inbox** `/applications-inbox` — `applications_inbox_screen.dart` — ref: `sponsor/applications-inbox.html`. Cards (name/sport, listing title, date, New badge) → detail.
- **I12. Application Detail** `/application-detail` — `application_detail_screen.dart` — ref: `sponsor/application-detail.html`. Detail stub + [View Full Profile]; actions [Shortlist][Approve][Reject].
- **I13. Shortlist** `/shortlist` — `shortlist_screen.dart` — (new). Amber cards + notes; actions: view profile, delete/remove.

Scholarships (often grouped with sponsorships for athletes): see C12/C13.

---

## J — Talent Scout Workspace (8 screens)

Own `ScoutShell` bottom nav: Dashboard/Discovery/Shortlist/Connections/Profile. Role `talent_scout`. No v1 HTML (all new — design freely, reuse directory/card patterns).

- **J1. Dashboard** `/scout-dashboard` — `talent_scout_dashboard_screen.dart`. Welcome banner, profile-completeness bar, stats (Shortlisted/Connections/Pending), Quick Actions, Recent Shortlist. CTAs: Discover / Shortlist / Connections / Profile / Logout.
- **J2. Onboarding** `/scout-onboarding` — `talent_scout_onboarding_screen.dart`. Photo picker, Organization/Affiliation, Experience years, City, Sports-specialization chips, Bio. CTA [Create Scout Profile].
- **J3. Athlete Discovery (advanced)** `/scout-discovery` — `talent_scout_athlete_discovery_screen.dart`. Search + filter toggle, quick sport chips, advanced panel (sport/age/city/skill/has_achievements), result count + paginated cards w/ shortlist ★. Actions [Apply Filters][Clear all][Shortlist toggle] → `/scout-athlete/:id`.
- **J4. Athlete Profile View (scout lens)** `/scout-athlete/:id` — `talent_scout_athlete_profile_view_screen.dart`. Header (photo/verified/sport/age/skill/location/stats), About, Sports, Achievements, Tournament History, Performance Stats grid, Media Gallery. CTAs [Shortlist][Connect/Request Sent/Connected][View My Shortlist].
- **J5. Shortlist** `/scout-shortlist` — `talent_scout_shortlist_screen.dart`. Dismissible cards + notes, empty state. Actions: view profile, edit/add note, Connect, Remove, [Discover Athletes].
- **J6. Send Connection Request** `/scout-connect/:athleteId` — `talent_scout_connection_screen.dart`. Athlete summary card + Message textarea (max 1000). CTAs [Send Request][Cancel].
- **J7. Connections (scout tracking)** `/scout-connections` — `talent_scout_connections_screen.dart`. Status badges {accepted/pending/rejected} + message quote. Tap accepted → profile; [Cancel pending].
- **J8. Scout Profile (own)** `/scout-profile` — `talent_scout_profile_screen.dart`. Header (photo/name/email/chips), completeness, At-a-glance, Discoverable switch, edit form, Account (Settings/Help/Logout/Delete). CTAs [Save Profile][Remove photo][Logout][Delete Account].

---

## K — Social, Chat & Connections (8 screens)

- **K1. Create Post** `/create-post` — `social/create_post_screen.dart` — (new). Caption field, media preview strip, hashtag chips. Actions: Gallery/Camera pick, hashtags toggle, [Post].
- **K2. Post Detail** `/post-detail/:id` — `social/post_detail_screen.dart` — (new). Author header, body/image, Like/Comment counts, comments list. Actions: Like toggle, comment submit.
- **K3. Chat List** `/chat-list` — `chat/chat_list_screen.dart` — (new). Search field, tiles (title/last msg/time/unread). → chat screen.
- **K4. Chat (1-1)** `/chat-screen` — `chat/chat_screen.dart` — (new). Bubbles me/other + timestamps, composer (Type… [Send]). See thread wireframe in §D.
- **K5. My Connections** `/my-connections` — `connections/my_connections_screen.dart` — (new). Search, tiles (name/role). Tap → view-profile; chat icon → chat; long-press Remove.
- **K6. Connection Requests** `/connection-requests` — `connection_requests_screen.dart` — (new). Scout-requests banner w/ pending count → `/scout-requests`; Received/Sent tabs; request cards [Accept][Decline].
- **K7. Scout Requests (athlete inbox)** `/scout-requests` — `scout_requests_screen.dart` — (new). Scout cards (org/city/exp/affiliation/message/status badge) [Accept][Decline].
- **K8. View Profile (generic)** `/view-profile` — see C16 (also used from connections/chat/discover).

---

## L — Personal Productivity (6 screens)

- **L1. Saved Items** `/saved` (tab 3) — `saved/saved_screen.dart` — ref: `saved-items.html`. Scrollable TabBar {All/Academies/Coaches/Trials/Tournaments/Scholarships/Sponsorships}, skeleton/error/empty, rows → detail, trash delete, Retry.
- **L2. Activity Hub** `/activity-hub` (tab 4) — `shared/activity_hub_screen.dart` — ref: `activity-hub.html`. 4 tabs {Trials/Tournaments/Sponsorships/Enquiries}, status-colored cards (title/date/status pill). Tab switch + pull-to-refresh. (Deep-links to D4/my-coaching/E5.)
- **L3. Notifications** `/notifications` — `notifications/notifications_screen.dart` — refs: `notifications.html`, `shared/notifications-center.html`. AppBar + [Mark all read], paginated inbox grouped {TODAY/YESTERDAY/THIS WEEK/EARLIER}, rows (type icon + unread dot). Tap → mark-read + deep-link.
- **L4. Settings** `/settings` — `settings/settings_screen.dart` — refs: `settings.html`, `shared/settings.html`, `athlete/settings.html`. Account (role-aware Edit Profile, Media Gallery, Change-Password dialog), Notification toggles, Language/Location, Support links, [Log Out][Delete Account].
- **L5. Help & Support** `/help-support` — `settings/help_support_screen.dart` — refs: `help-support.html`, `shared/help-support.html`. "Search for help" field, 6 FAQ ExpansionTiles, "Still need help" contact card [Email Support].
- **L6. Report Listing** — ref: `shared/report-listing.html`, `report-listing.html` — **exists in design, partially in app** (`report_detail_screen.dart` admin side). Designer: design user-lens "Report content/user" sheet + "My Reports" list (reason + status). See also Admin M5/M6.

---

## M — Admin Panel (15 screens)

Base route `/admin/*`. Use `AdminWebLayout` components: `AdminStatCard`, `AdminSectionLabel`, `AdminTabPills`, `AdminUserCard`, `AdminReportCard`, `AdminOpportunityCard`. Design responsive (mobile list → desktop table). Refs: `admin/*.html`.

- **M1. Admin Login** `/admin/login` — `admin_login_screen.dart`. Email + Password + 2FA code. CTA [Log In]. (Separate from app login.)
- **M2. Admin Dashboard** `/admin/dashboard` — `admin_dashboard_screen.dart` — ref: `admin-dashboard.html`. Stat cards (Active Listings/Flagged/Expirations/Signups/Total Users/Pending Approvals), Quick Actions → Reports/Users/Moderation/Approvals. [Logout].
- **M3. Manage Users** `/admin/users` — `manage_users_screen.dart` — ref: `admin-user-management.html`. Search field, `AdminUserCard` list + popup (Verify/Suspend/Activate/Delete), [+ Add User] (dialog stub). Row → verify screen.
- **M4. User Detail & Verify** `/admin/users/:id/verify` — `user_detail_verify_screen.dart` — ref: `admin-sponsor-verification.html`. Profile header, verification documents, checklist (photo/docs/verified). CTAs [Verify/Approve][Reject].
- **M5. Pending Approvals** `/admin/approvals` — `pending_approvals_screen.dart` — ref: `admin-listing-moderation.html` (partial). Approval cards (role badge/docs: coach/sponsor/academy signups). [Approve][Reject][Refresh].
- **M6. Moderation Queue** `/admin/moderation` — `moderation_queue_screen.dart` — ref: `admin-content-flagging.html` (partial). Sections {Pending Review/Recently Reviewed}, report items (preview/reporter). [Review → detail][Dismiss].
- **M7. Report Detail** `/admin/reports/:id` — `report_detail_screen.dart` — ref: `admin-report-center.html` (item view). Status header, reported-content preview, reporter info, action panel. [Mark Resolved][Dismiss Report].
- **M8. Platform Reports / Analytics (current)** `/admin/reports` — `platform_reports_screen.dart` — ref: `admin-report-center.html`. Quick-stats grid, Users-by-Role bars, Users-by-Region/Sport lists, Activity metrics. [Refresh].
- **M9. Opportunity Approval Queue** `/admin/opportunities` — `opp_approval_queue_screen.dart` — (new). Pills {Pending/Approved/Rejected}, `AdminOpportunityCard` list. [Approve][Reject]; tap → review detail.
- **M10. Opportunity Review Detail** `/admin/opportunities/:id` — `opp_review_detail_screen.dart` — (new). Status header, details, sponsor info, budget. [Approve][Reject].
- **M11. Compose Notification** `/admin/notifications/compose` — `compose_notification_screen.dart` — ref: `admin-notification-templates.html` (partial). Title/Body + char count, Target-audience radios, live preview. [Send Notification] [→ Advanced Targeting].
- **M12. Notification Targeting** `/admin/notifications/targeting` — `notification_targeting_screen.dart` — (new). Toggles + chips (Role/Sport/City), summary. [Apply Targeting Filters] (pop w/ map).
- **M13. Content Picker (hub)** (no route; internal) — `admin_content_picker_screen.dart` — (new). Category tiles (Academies/Coaches/Trials/Tournaments/Scholarships/Sponsorships + counts) → content list.
- **M14. Content List** (no route; internal) — `admin_content_list_screen.dart` — (new). Search + title/status rows for chosen category.
- **M15. TO DESIGN (missing per audit):** Admin Analytics (full charts: user growth, listings, registrations, top sports/cities, engagement; period 7/30/90/365d) — ref: `admin-analytics.html`; System Settings (grouped settings + maintenance mode) — ref: `admin-system-settings.html`; Sport Category Management — ref: `admin-sport-category-management.html`; Notification Templates CRUD — ref: `admin-notification-templates.html`. Backend specs exist in `BACKEND_INTEGRATION_MISSING_SCREENS.md`.

```
Admin list pattern:
┌─────────────────────┐
│< Admin  ⌕  [+ Add]  │
│{Pending}{Appr}{Rej} │
│▭ user/report/opp    │
│  [Approve][Reject]  │
└─────────────────────┘
```

---

## N — Marketing / Web-only (reference, not in-app)

Do NOT put inside app tabs; design as responsive web separately if needed: `landing.html`, `website/*` (index/pricing/careers/press/changelog/privacy/terms/security/cookies), `playstore-assets/*` (feature-graphic, 4 screenshots), `index.html` (launcher/overview), `app.html`. Old design also duplicates `profile-edit/profile-view/notifications/settings/help-support/search-results` at root — canonical versions are in §§E/L.

---

## O — Full Screen Inventory Table

Route → Flutter file → v1 design ref. (Use for traceability; descriptions above are canonical.)

| # | Route | Flutter (`sportx_app/lib/…`) | Design ref (`sportsx-design-v1/…`) |
|---|-------|-------------------------------|-------------------------------------|
| 1 | `/splash` | `features/auth/…/splash_screen.dart` | `splash-screen.html` |
| 2 | `/role-selection` | `features/auth/…/role_selection_screen.dart` | `role-selection.html` |
| 3 | `/sign-up` | `features/auth/…/sign_up_screen.dart` | `shared/sign-up.html` |
| 4 | `/login` | `features/auth/…/login_screen.dart` | `shared/login.html` |
| 5 | `/otp` (flow) | `features/auth/…/otp_screen.dart` | `shared/otp-verification.html` |
| 6 | `/onboarding-1` | `features/onboarding/…/onboarding_sport_age_screen.dart` | `onboarding-sport.html` |
| 7 | `/onboarding-2` | `features/onboarding/…/onboarding_skill_location_screen.dart` | `onboarding-location.html` |
| 8 | `/coach-onboarding` | `features/coach/…/coach_onboarding_screen.dart` | `coach/coach-onboarding.html` |
| 9 | `/academy-onboarding` | `features/academy/…/academy_onboarding_screen.dart` | `academy/academy-onboarding.html` |
| 10 | `/organizer-onboarding` | `features/organizer/…/organizer_onboarding_screen.dart` | `organizer/organizer-onboarding.html` |
| 11 | `/sponsor-onboarding` | `features/sponsor/…/sponsor_onboarding_screen.dart` | `sponsor/sponsor-onboarding.html` |
| 12 | `/scout-onboarding` | `features/talent_scout/…/talent_scout_onboarding_screen.dart` | — (new) |
| 13 | `/home` ⚫tab | `features/home/…/home_screen.dart` | `home-dashboard.html` |
| 14 | `/discover` | `features/home/…/discover_screen.dart` | — (new) |
| 15 | (prefilter) | `features/home/…/search_screen.dart` | `search-results.html` (partial) |
| 16 | `/universal-search` ⚫tab | `features/search/…/universal_search_screen.dart` | `universal-search.html` + `search-results.html` |
| 17 | `/search-filter` | `features/search/…/search_filter_screen.dart` | `shared/filter-panel.html` |
| 18 | `/saved` ⚫tab | `features/saved/…/saved_screen.dart` | `saved-items.html` |
| 19 | `/activity-hub` ⚫tab | `features/shared/…/activity_hub_screen.dart` | `activity-hub.html` |
| 20 | `/profile` ⚫tab | `features/athlete/…/profile_screen.dart` | `profile-view.html` |
| 21 | `/academies` | `features/academy/…/academy_directory_screen.dart` | `academy-directory.html` |
| 22 | `/academy-detail/:id` | `features/academy/…/academy_detail_screen.dart` | `academy-detail.html` |
| 23 | `/coaches` | `features/coach/…/coach_directory_screen.dart` | `coach-directory.html` |
| 24 | `/coach-detail/:id` | `features/coach/…/coach_detail_screen.dart` | `coach-detail.html` |
| 25 | `/coach-profile-detail/:id` | `features/coach/…/coach_profile_detail_screen.dart` | `coach-detail.html` (rich) |
| 26 | `/trials` | `features/trial/…/trial_directory_screen.dart` | `trial-listings.html` |
| 27 | `/trial-detail/:id` | `features/trial/…/trial_detail_screen.dart` | `trial-detail.html` |
| 28 | `/tournaments` | `features/tournament/…/tournament_directory_screen.dart` | — (list impl; detail ref below) |
| 29 | `/tournament-detail/:id` | `features/tournament/…/tournament_detail_screen.dart` | `athlete/tournament-detail.html` |
| 30 | `/tournament-calendar` | `features/tournament/…/tournament_calendar_screen.dart` | `tournament-calendar.html` |
| 31 | `/sponsorships` | `features/sponsorship/…/sponsorship_list_screen.dart` | `athlete/sponsorship-list.html` |
| 32 | `/sponsorship-detail/:id` | `features/sponsorship/…/sponsorship_detail_screen.dart` | `athlete/sponsorship-detail.html` |
| 33 | `/scholarships` | `features/scholarship/…/scholarship_list_screen.dart` | `athlete/scholarship-feed.html` |
| 34 | `/scholarship-detail/:id` | `features/scholarship/…/scholarship_detail_screen.dart` | `athlete/scholarship-detail.html` |
| 35 | `/sports-venues` | `features/sports_venue/…/sports_venue_list_screen.dart` | — (new) |
| 36 | `/sports-venue-detail/:id` | `features/sports_venue/…/sports_venue_detail_screen.dart` | — (new) |
| 37 | `/view-profile` | `features/shared/…/view_profile_screen.dart` | `profile-view.html` |
| 38 | `/trial-registration/:id` | `features/trial/…/trial_registration_screen.dart` | `trial-registration.html` |
| 39 | `/tournament-registration/:id` | `features/tournament/…/tournament_registration_screen.dart` | `athlete/tournament-registration.html` |
| 40 | `/registration-confirmation` | `features/shared/…/registration_confirmation_screen.dart` | `registration-confirmation.html` |
| 41 | `/my-registrations` | `features/shared/…/my_registrations_screen.dart` | — (new) |
| 42 | `/enquire/:t/:id/:title` | `shared/…/enquire_screen.dart` | `athlete/enquire-coach.html` |
| 43 | `/enquiry-inbox` | `features/shared/…/enquiry_inbox_screen.dart` | `coach/enquiry-inbox.html` (shared) |
| 44 | `/enquiry-detail` | `features/shared/…/enquiry_detail_screen.dart` | `coach/enquiry-detail.html` (shared) |
| 45 | `/coach-enquiry-inbox` | `features/coach/…/coach_enquiry_inbox_screen.dart` | `coach/enquiry-inbox.html` |
| 46 | `/coach-enquiry-detail` | `features/coach/…/coach_enquiry_detail_screen.dart` | `coach/enquiry-detail.html` |
| 47 | `/coach-enrollments` | `features/coach/…/coach_enrollment_screen.dart` | — (new) |
| 48 | `/apply-sponsor/:id` | `features/sponsorship/…/apply_sponsor_screen.dart` | `athlete/apply-sponsor.html` |
| 49 | `/sponsor-pitch/:id` | `features/shared/…/sponsor_pitch_screen.dart` | `athlete/apply-sponsor.html` (legacy) |
| 50 | (athlete apps — TO DESIGN) | — | `athlete/sponsorship-list.html`, `athlete/sponsorship-detail.html` (athlete lens) |
| 51 | `/edit-profile` | `features/athlete/…/edit_profile_screen.dart` | `profile-edit.html` |
| 52 | `/add-achievement` | `features/athlete/…/add_achievement_screen.dart` | — (new) |
| 53 | `/media-gallery` | `features/athlete/…/media_gallery_screen.dart` | `athlete/media-gallery.html` |
| 54 | `/my-coaching-enrollments` | `features/athlete/…/my_coaching_enrollments_screen.dart` | — (new) |
| 55 | `/coach-dashboard` | `features/coach/…/coach_dashboard_screen.dart` | `coach/coach-dashboard.html` |
| 56 | `/coach-profile-edit` | `features/coach/…/coach_profile_edit_screen.dart` | `coach/coach-profile-edit.html` |
| 57 | `/edit-coach-profile` | `features/coach/…/coach_profile_posting_screen.dart` | — (new) |
| 58 | `/add-credential` | `features/coach/…/add_credential_screen.dart` | — (new) |
| 59 | `/edit-facilities` | `features/coach/…/edit_facilities_screen.dart` | — (new) |
| 60 | `/showcase-athletes` | `features/coach/…/showcase_athletes_screen.dart` | — (new) |
| 61 | `/sponsor-directory-coach` | `features/coach/…/sponsor_directory_screen.dart` | — (new) |
| 62 | `/academy-dashboard` | `features/academy/…/academy_dashboard_screen.dart` | `academy/academy-dashboard.html` |
| 63 | `/post-trial` | `features/academy/…/trial_posting_screen.dart` | `academy/trial-posting-form.html` |
| 64 | `/my-trials` | `features/shared/…/my_trials_management_screen.dart` | `academy/my-trials.html` |
| 65 | `/registrant-list` | `features/shared/…/registrant_list_screen.dart` | `academy/registrant-list.html` |
| 66 | `/registrant-detail` | `features/shared/…/registrant_detail_screen.dart` | `academy/registrant-detail.html` |
| 67 | `/academy-profile` | `features/academy/…/academy_profile_screen.dart` | — (new) |
| 68 | `/edit-academy-profile` | `features/academy/…/academy_profile_posting_screen.dart` | `academy/academy-listing-edit.html` |
| 69 | `/organizer-dashboard` | `features/organizer/…/organizer_dashboard_screen.dart` | `organizer/organizer-dashboard.html` |
| 70 | `/post-tournament` | `features/organizer/…/tournament_posting_screen.dart` | `organizer/tournament-create.html` |
| 71 | `/edit-tournament/:id` | `features/organizer/…/tournament_edit_screen.dart` | — (new) |
| 72 | `/my-tournaments` | `features/shared/…/my_tournaments_management_screen.dart` | `organizer/my-tournaments.html` |
| 73 | `/registration-management` | `features/organizer/…/registration_management_screen.dart` | `organizer/registration-management.html` |
| 74 | `/capacity-management` | `features/organizer/…/capacity_management_screen.dart` | `organizer/capacity-management.html` |
| 75 | `/results-publishing` | `features/organizer/…/results_publishing_screen.dart` | `organizer/results-publishing.html` |
| 76 | `/results-view` | `features/organizer/…/results_view_screen.dart` | — (new) |
| 77 | `/organizer-analytics` | `features/organizer/…/organizer_analytics_screen.dart` | — (new) |
| 78 | `/organizer-profile` | `features/organizer/…/organizer_profile_screen.dart` | — (new) |
| 79 | `/sponsor-dashboard` | `features/sponsor/…/sponsor_dashboard_screen.dart` | `sponsor/sponsor-dashboard.html` |
| 80 | `/sponsor-posting` | `features/sponsor/…/sponsorship_posting_screen.dart` | `sponsor/sponsorship-create.html` |
| 81 | `/my-sponsorships` | `features/sponsor/…/my_sponsorships_management_screen.dart` | — (new) |
| 82 | `/athlete-discovery` | `features/sponsor/…/athlete_discovery_screen.dart` | `sponsor/athlete-discovery.html` |
| 83 | `/athlete-profile-view` | `features/sponsor/…/athlete_profile_view_screen.dart` | `sponsor/athlete-profile-view.html` |
| 84 | `/applications-inbox` | `features/sponsor/…/applications_inbox_screen.dart` | `sponsor/applications-inbox.html` |
| 85 | `/application-detail` | `features/sponsor/…/application_detail_screen.dart` | `sponsor/application-detail.html` |
| 86 | `/shortlist` | `features/sponsor/…/shortlist_screen.dart` | — (new) |
| 87 | `/scout-dashboard` ◆ | `features/talent_scout/…/talent_scout_dashboard_screen.dart` | — (new) |
| 88 | `/scout-discovery` ◆ | `features/talent_scout/…/talent_scout_athlete_discovery_screen.dart` | — (new) |
| 89 | `/scout-athlete/:id` | `features/talent_scout/…/talent_scout_athlete_profile_view_screen.dart` | — (new) |
| 90 | `/scout-shortlist` ◆ | `features/talent_scout/…/talent_scout_shortlist_screen.dart` | — (new) |
| 91 | `/scout-connect/:athleteId` | `features/talent_scout/…/talent_scout_connection_screen.dart` | — (new) |
| 92 | `/scout-connections` ◆ | `features/talent_scout/…/talent_scout_connections_screen.dart` | — (new) |
| 93 | `/scout-profile` ◆ | `features/talent_scout/…/talent_scout_profile_screen.dart` | — (new) |
| 94 | `/create-post` | `features/social/…/create_post_screen.dart` | — (new) |
| 95 | `/post-detail/:id` | `features/social/…/post_detail_screen.dart` | — (new) |
| 96 | `/chat-list` | `features/chat/…/chat_list_screen.dart` | — (new) |
| 97 | `/chat-screen` | `features/chat/…/chat_screen.dart` | — (new) |
| 98 | `/my-connections` | `features/connections/…/my_connections_screen.dart` | — (new) |
| 99 | `/connection-requests` | `features/connections/…/connection_requests_screen.dart` | — (new) |
| 100 | `/scout-requests` | `features/connections/…/scout_requests_screen.dart` | — (new) |
| 101 | `/notifications` | `features/notifications/…/notifications_screen.dart` | `notifications.html` + `shared/notifications-center.html` |
| 102 | `/settings` | `features/settings/…/settings_screen.dart` | `settings.html` + `shared/settings.html` |
| 103 | `/help-support` | `features/settings/…/help_support_screen.dart` | `help-support.html` + `shared/help-support.html` |
| 104 | (report flow — TO DESIGN user lens) | — | `shared/report-listing.html` + `report-listing.html` |
| 105 | `/admin/login` | `features/admin/…/admin_login_screen.dart` | `shared/login.html` (admin use) |
| 106 | `/admin/dashboard` | `features/admin/…/admin_dashboard_screen.dart` | `admin/admin-dashboard.html` |
| 107 | `/admin/users` | `features/admin/…/manage_users_screen.dart` | `admin/admin-user-management.html` |
| 108 | `/admin/users/:id/verify` | `features/admin/…/user_detail_verify_screen.dart` | `admin/admin-sponsor-verification.html` |
| 109 | `/admin/approvals` | `features/admin/…/pending_approvals_screen.dart` | `admin/admin-listing-moderation.html` (partial) |
| 110 | `/admin/moderation` | `features/admin/…/moderation_queue_screen.dart` | `admin/admin-content-flagging.html` (partial) |
| 111 | `/admin/reports/:id` | `features/admin/…/report_detail_screen.dart` | `admin/admin-report-center.html` (item) |
| 112 | `/admin/reports` | `features/admin/…/platform_reports_screen.dart` | `admin/admin-report-center.html` |
| 113 | `/admin/opportunities` | `features/admin/…/opp_approval_queue_screen.dart` | — (new) |
| 114 | `/admin/opportunities/:id` | `features/admin/…/opp_review_detail_screen.dart` | — (new) |
| 115 | `/admin/notifications/compose` | `features/admin/…/compose_notification_screen.dart` | `admin/admin-notification-templates.html` (partial) |
| 116 | `/admin/notifications/targeting` | `features/admin/…/notification_targeting_screen.dart` | — (new) |
| 117 | (internal) | `features/admin/…/admin_content_picker_screen.dart` | — (new) |
| 118 | (internal) | `features/admin/…/admin_content_list_screen.dart` | — (new) |
| 119 | (TO DESIGN) | — | `admin/admin-analytics.html`, `admin/admin-system-settings.html`, `admin/admin-sport-category-management.html` |

`⚫tab` = athlete bottom-nav tab · `◆` = ScoutShell tab.

---

## P — Designer Checklist & Screen States to Design

For **every screen** deliver: default / loading skeleton / empty / error+retry / filled / validation-error (forms) / success-toast or confirmation. Plus:

1. Merge duplicates into canonical designs: Coach Detail (C4+C5), Sponsorship Apply (D11+D12), Coach Profile Edit (F2+F3), Notifications/Settings/Help (single canonical each covering root + `shared/` + `athlete/` variants).
2. net-new / missing screens to prioritize: Athlete Sponsorship Applications list+detail (E6/I4), Admin Analytics + System Settings + Category Mgmt + Template CRUD (M15), Report flow user lens (L6), Venue booking flow (C15 CTA is placeholder), Coach Schedule sub-view (F14).
3. Navigation: Splash → Role Selection → Sign Up/Login → OTP → role Onboarding → role Dashboard/Home; athlete tabs; scout tabs; deep-links (notification → detail, saved row → detail, activity card → registration/enquiry).
4. Breakpoints: 360×800, 390×844, 430×932 (phones) · 820×1180 tablet · 1366×768/1440×900/1920×1080 (admin web + marketing).
5. Handoff format suggestion: Figma pages per §A–M, components for Directory row / Detail hero / Form section / Status pill / Empty-error / Admin cards, prototype links matching routes in §O.

*Generated 2026-09-21 from `sportx_app/lib` + `sportsx-design-v1` + status docs. Counts: ~124 in-app screens (11 auth/onboarding + 6 home/search + 16 directories/details + 12 registration/enquiry + 6 athlete + 14 coach + 7 academy + 10 organizer + 13 sponsor-side incl. scholarships + 8 scout + 8 social/chat/connections + 6 productivity + 15 admin + Report flow).*
