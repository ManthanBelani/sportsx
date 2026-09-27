# SportX — Complete User Flow Guide (All Roles)

> Last updated: Sep 2026, verified against `sportx_app/lib/core/router.dart`, `sportx-api/routes/api.php`, and a screen-by-screen audit of all feature modules.
> Purpose: understand **who does what, where they land, and how every journey flows end-to-end**.

---

## 1. The App in One Paragraph

SportX is a sports ecosystem marketplace. **Athletes** discover and register for trials, tournaments, coaching, and sponsorships. **Providers** (Coach, Academy, Organizer, Sponsor) post opportunities and approve who gets in. **Talent Scouts** hunt and connect with athletes. **Admin** verifies users, approves listings, moderates content. There is **no payment gateway** — every registration/enrollment/application is **request → provider approves/rejects** (approval-based system, fees display-only).

### The 7 Roles

| # | Role (`users.role`) | Signup card | In one line | Lands on |
|---|---|---|---|---|
| 1 | `athlete` | **Athlete / Parent** | Discovers everything, registers, applies, networks, chats | `/home` (bottom-nav app) |
| 2 | `coach` | Coach | Offers coaching, gets enquiries + enrollments, can post trials | `/coach-dashboard` |
| 3 | `academy` | Academy | Public listing + posts trials, manages registrants | `/academy-dashboard` |
| 4 | `organizer` | Organizer | Runs tournaments: registrations, capacity, results | `/organizer-dashboard` |
| 5 | `sponsor` | Sponsor / Brand | Posts sponsorships, discovers athletes, reviews applications | `/sponsor-dashboard` |
| 6 | `talent_scout` | Talent Scout | Discovers athletes, shortlists, sends connect requests | `/scout-dashboard` (bottom-nav app) |
| 7 | `admin` | **No self-signup** → `/admin/login` + 2FA | Verifies, approves, moderates, broadcasts | `/admin/dashboard` (web layout) |

**Naming notes (important):**
- **Parent is NOT a separate role** — parents use an Athlete account; parental consent is a checkbox on trial registration forms.
- **Federation is NOT a role** — it's an `org_type` sub-type of Organizer.
- "Providers" = Coach + Academy + Organizer + Sponsor collectively.

---

## 2. Global Auth & Onboarding (every role starts here)

```mermaid
flowchart TD
  S[Splash — checks saved token via GET /auth/me] -->|no token| RS[Role Selection — 6 cards]
  S -->|token valid, setup done| DASH[Role Dashboard]
  S -->|token valid, setup pending| OB[Role Onboarding]
  RS -->|pick card| SU[Sign Up — email + password + role]
  RS --> L[Login — email/password or OTP]
  SU --> OTP[Email OTP verify<br/>Google OAuth skips OTP]
  OTP --> OB
  L --> OB
  OB -->|athlete| H1[Step 1: sports + age group<br/>Step 2: skill level + city] --> HOME[/home]
  OB -->|coach| CD[/coach-dashboard]
  OB -->|academy| AD[/academy-dashboard]
  OB -->|organizer| OD[/organizer-dashboard<br/>uploads verification docs]
  OB -->|sponsor| SD[/sponsor-dashboard<br/>uploads verification docs]
  OB -->|talent_scout| SCD[/scout-dashboard]
```

**Router guard rules (`router.dart`):**
- `needs_onboarding = true` → user is **forced** into their role's onboarding screens; nothing else reachable.
- Non-athlete roles tapping athlete bottom-nav screens (`/home, /universal-search, /saved, /network, /activity-hub, /profile`) are **auto-redirected to their dashboard**.
- Admin routes (`/admin/*`) are outside this flow entirely — separate login, separate layout.

**Account statuses:** `pending` (provider awaiting admin approval) → `active` → `suspended`/`deleted`. Organizer & Sponsor are created `pending` + `listing_status=draft` until Admin verifies docs. Phone is stored unverified (deferred).

---

## 3. Role 1 — Athlete / Parent (the consumer)

**Bottom nav (MainShell):** `Home` · `Discover` · **➕ FAB** (create sheet) · `Network` · `Me`

### The full journey

```mermaid
flowchart TD
  subgraph FIND[1. Find opportunities]
    HOME[Home: quick tiles Trials/Tournaments/Scholarships/Sponsorships<br/>+ recommended academies & coaches + latest opportunities]
    HOME --> DISC[Discover tab: Athletes / Coaches / Sponsors tabs<br/>+ sport & state filters]
    HOME --> SRCH[Search: universal-search + filter sheet<br/>GET /search]
    HOME --> OPP[Opportunities feed /opportunities<br/>tabs All / Trials / Tournaments / Scholarships / Sponsorships]
  end
  FIND --> DET[Detail page<br/>academy / coach / trial / tournament / scholarship / venue / sponsorship]
  DET --> SAVE[Save → /saved]
  DET --> REP[Report → /report]
  DET --> ENQ[Enquire — message + preferred time<br/>POST /enquiries]
  DET --> REG[Register<br/>trial form + docs / tournament + category pick]
  DET --> ENROLL[Enroll with coach<br/>plan: session / monthly / quarterly]
  DET --> APPLY[Apply for sponsorship<br/>pitch note + profile auto-attached]
  REG --> CONF[Confirmation screen<br/>ref number + Add to Calendar + Remind me]
  ENROLL --> TRACK[Track everything]
  APPLY --> TRACK
  ENQ --> CHAT[Chat: /chat-list → /chat-screen]
  TRACK[My Activity /activity-hub<br/>My Applications /my-applications<br/>Application status timeline]
  HOME --> NET[Network: connect athletes, find scouts<br/>connection requests, scout requests]
  NET --> MYCON[/my-connections — search, message, remove]
  HOME --> ME[Me /profile — edit profile, achievements,<br/>media gallery, settings, social links]
```

### Step-by-step: the core athlete loops

**A. Register for a trial**
1. Home → Trials tile (or Discover / Opportunities / Search) → Trial detail.
2. Tap **Register** → form (sport, age group, experience) + document upload + parental consent (if minor).
3. Submit → `POST /trials/{id}/register` → status **Pending Approval**.
4. Confirmation screen: registration ref, event details, **Add to Calendar** (ICS download), **Remind me** toggle.
5. Provider (Academy/Coach) reviews → **Confirmed** (green) or **Rejected + reason** (red) → push notification.
6. Track under **My Activity** → Trials tab, and `/my-registrations`.

**B. Enter a tournament**
1. Tournament detail → **Register** → pick category (Individual/Team) → submit.
2. Capacity logic: spots free → `confirmed` after approval; full + waitlist on → **waitlisted**; full + no waitlist → error.
3. Organizer approves/rejects; organizer can also flip `payment_status` manually (no gateway).

**C. Enroll with a coach**
1. Coach detail → **Enroll** → pick plan (session/monthly/quarterly) + notes.
2. Coach approves with start/end dates → status **Active** → appears in `/my-coaching-enrollments`.

**D. Apply for a sponsorship**
1. Sponsorship detail → **Apply** → pitch note (profile auto-attached; document dropzone is UI-only currently) → `POST /sponsorships/{id}/apply`.
2. On success the app pops back past the detail screen.
3. Sponsor shortlists/rejects/replies; athlete tracks via **My Applications → status timeline** (Applied → Under Review → Shortlisted → Final Selection → Result).

**E. Enquire (ask a question)**
1. Any coach/academy detail → **Enquire** modal → message + preferred datetime.
2. Provider replies in their inbox → athlete gets notification → continue in **Chat**.

**F. Network**
1. Network tab → suggested athletes with Connect / Requested / Message states.
2. "Find Talent Scouts & Chat" → `/scout-directory`; incoming scout requests in `/scout-requests`.
3. `/my-connections`: search, message, view profile, long-press to remove.

---

## 4. Role 2 — Coach

**Landing:** `/coach-dashboard` (no bottom nav — dashboard + push screens).

```mermaid
flowchart TD
  OB[/coach-onboarding: sport, experience, certifications, fees, location] --> DASH[Coach Dashboard<br/>listing status, enquiry stats, recent enquiries]
  DASH --> PROF[Manage listing<br/>/edit-coach-profile · /coach-profile-edit<br/>/add-credential · /edit-facilities · /showcase-athletes]
  DASH --> INBOX[Enquiry Inbox — tabs All / New / Replied]
  INBOX --> TH[Enquiry thread → Reply<br/>athlete notified]
  DASH --> ENR[Enrollments queue]
  ENR --> APP[Approve — set start/end dates + response]
  ENR --> REJ[Reject — with reason]
  DASH --> TRIAL[Post Trial /post-trial]
  TRIAL --> MYT[/my-trials → registrant-list → registrant-detail<br/>verify / reject athlete + view docs]
  DASH --> SPON[Browse /sponsor-directory-coach]
```

**Enrollment approval:** athlete request arrives `pending` → coach approves (`PATCH /coaching-enrollments/{id}/approve` with dates) or rejects with reason → athlete sees status change + push.

---

## 5. Role 3 — Academy

**Landing:** `/academy-dashboard`.

```mermaid
flowchart TD
  OB[/academy-onboarding: name, sports, city, facilities, fees, photos] --> DASH[Academy Dashboard<br/>listing status, trial stats, enquiry count]
  DASH --> LIST[Own public listing /academy-profile<br/>edit via /edit-academy-profile]
  DASH --> POST[Post Trial — name/sport/dates/venue/<br/>eligibility/fee/docs → publish or draft]
  POST --> MY[/my-trials]
  MY --> RL[Registrant list — document status badges]
  RL --> RD[Registrant detail — athlete snapshot + docs via signed URL]
  RD --> V[Mark Verified / Reject → athlete's My Activity updates]
  DASH --> IN[Enquiry Inbox tabs → thread → reply]
```

Same trial-management pipeline as coach (shared `/my-trials` + registrant screens).

---

## 6. Role 4 — Organizer (incl. Federations)

**Landing:** `/organizer-dashboard` (+ `/organizer-analytics`).

```mermaid
flowchart TD
  OB[/organizer-onboarding: org name, type federation/club, verification docs] --> PEND[Admin verification — account pending until approved]
  PEND --> DASH[Organizer Dashboard + Analytics]
  DASH --> POST[Post Tournament — format, dates, venue, fees,<br/>prize, categories + capacity + waitlist per category]
  POST --> MY[/my-tournaments → /edit-tournament/:id]
  MY --> REGM[Registration Management<br/>approve / reject with reason]
  REGM --> CAP[Capacity Management — view + adjust per category]
  REGM --> PAY[Flip payment status manually — no gateway]
  MY --> RES[Results Publishing — winners/runner-up/3rd + bracket image<br/>publish / unpublish]
  RES --> RESV[Results View — public]
  DASH --> CAL[Tournament Calendar]
```

**Athlete-side effects:** approve → `confirmed` (or `waitlisted` if capacity full); reject → `cancelled` + reason shown to athlete. Results publication notifies participants.

---

## 7. Role 5 — Sponsor / Brand

**Landing:** `/sponsor-dashboard`. Account starts **pending until Admin verifies docs**.

```mermaid
flowchart TD
  OB[/sponsor-onboarding: brand, category, verification docs] --> V[Admin verification]
  V --> DASH[Sponsor Dashboard — active sponsorships,<br/>application stats, shortlist count]
  DASH --> POST[Post Sponsorship /sponsor-posting]
  POST --> MY[/my-sponsorships — publish / close]
  POST --> GATE[Admin opportunity approval gate<br/>listing visible only after approval]
  DASH --> DISC[Athlete Discovery — filters: sport, age, city, achievements]
  DISC --> PV[Athlete Profile View]
  PV --> SL[Shortlist + note]
  DASH --> INBOX[Applications Inbox per sponsorship]
  INBOX --> DET[Application Detail]
  DET --> S2[Shortlist]
  DET --> RJ[Reject]
  DET --> RP[Reply → opens enquiry thread with athlete]
  DASH --> SL2[/shortlist — grouped list, per-athlete notes]
```

**Two approval gates for sponsors:** (1) account verification at onboarding, (2) each **sponsorship listing** passes the Admin opportunity queue before it's publicly visible.

---

## 8. Role 6 — Talent Scout

**Landing:** `/scout-dashboard` — the only other role with a bottom nav (ScoutShell): `Home · Discover · Shortlist · Connections · Profile`.

```mermaid
flowchart TD
  OB[/scout-onboarding: org/affiliation, sports multi-select, experience, city, bio] --> DASH[Scout Dashboard — search shortcut,<br/>saved count, connections sent, profile completeness]
  DASH --> DIS[Discover — athlete grid + chips sport/age/city/skill<br/>+ advanced filters]
  DIS --> PROF[Athlete Profile — info, sports history timeline,<br/>achievements, media gallery]
  PROF --> SH[Shortlist ♥ + private note]
  PROF --> CONN[Connect — message form<br/>POST /athletes/{id}/connect]
  CONN --> WAIT[Status: pending until athlete accepts/rejects]
  DASH --> CONNS[Connections — incoming + outgoing, accept/reject]
  DASH --> SPROF[Scout Profile — edit + PUT /me/scout-profile]
```

**Athlete side of the same flow:** athlete sees the request in Network → `/scout-requests` → accept/reject → scout is notified; accepted scouts appear in the athlete's connections.

---

## 9. Role 7 — Admin

Separate web-style layout, `/admin/login` → **2FA verify** → `/admin/dashboard`. All admin APIs guarded by `role:admin` + `admin.2fa` middleware.

| Flow | Screens | What happens |
|---|---|---|
| **User management** | `/admin/users` → `/admin/users/:id/verify` | Browse/filter all users; verify, approve, reject, suspend, delete |
| **Provider approvals** | `/admin/approvals` | Approve pending Organizer/Sponsor accounts (they can't list until approved) |
| **Opportunity approvals** | `/admin/opportunities` → `:id` | Approve/reject sponsorship listings before they go public |
| **Moderation** | `/admin/moderation` → report detail | Queue grouped by content; actions: dismiss, remove content (owner notified), warn owner |
| **Platform reports** | `/admin/reports` → `:id` | User-submitted reports (`POST /reports`) land here |
| **Registrations override** | — | Admin can force approve/reject any trial/tournament registration or enrollment (logged as `admin_override`) |
| **Broadcast notifications** | `/admin/notifications/compose` + targeting | Push notifications by audience targeting |
| **Analytics & masters** | `/admin/analytics`, `/admin/settings` | Dashboard metrics, category masters (sports/cities/age-groups) |
| **Expiry engine** | monitor tabs | Hourly scheduler expires old listings → override (keep live) or restore (re-publish) |

---

## 10. Cross-Cutting Flows

### A. The universal "Approval" pattern (no payments)
Every athlete→provider action follows: **Request (pending) → Provider reviews → Approve / Reject (+reason) → Push notification → status visible in My Activity**.

| Action | Athlete sends | Provider queue | Athlete sees |
|---|---|---|---|
| Trial registration | `POST /trials/{id}/register` | `/my-trials` → registrant list | `/my-registrations`, activity hub |
| Tournament entry | `POST /tournaments/{id}/register` | Registration management | `/my-registrations` + ICS calendar |
| Coach enrollment | `POST /coaches/{id}/enroll` | `/coach-enrollments` | `/my-coaching-enrollments` |
| Sponsorship application | `POST /sponsorships/{id}/apply` | `/applications-inbox` | `/my-applications` + timeline |
| Scout connect | `POST /athletes/{id}/connect` | `/scout-connections` | `/scout-requests` |
| Enquiry | `POST /enquiries` | Enquiry inbox | Notifications → chat thread |

### B. Search & Discovery (athlete)
`Home` / `Discover` / `Opportunities` / `Universal Search` (+ filter sheet: sport, city, age, price, date) → directory grids → **detail page** → act (save / report / enquire / register / apply / enroll). Public listings (scholarships, venues, sponsorships) are readable without auth; acting requires login.

### C. Social layer
FAB **➕** → create sheet: Create Post · Create Opportunity (`/post-trial`) · Add Achievement · Add Event (`/post-tournament`) · Upload Photo/Video. Feed → `/post-detail/:id` (like, comment). ⚠️ The create sheet is **not role-gated** — every role sees the same athlete-flavored options.

### D. Chat & Notifications
Enquiry replies and accepted connections create **conversations** (`/chat-list` → `/chat-screen`). All approval/rejection/expiry events push to the **Notifications center** (`/notifications`), backed by device tokens.

### E. Saved & Report
Save anything from any detail page → `/saved`. Report any listing/post → `/report` → lands in Admin moderation queue.

---

## 11. Status Cheat-Sheet (what each color means)

| Entity | Pending | Success | Fail | Notes |
|---|---|---|---|---|
| Registration (trial/tournament) | Pending Approval (orange) | Confirmed (green) / Waitlisted | Rejected (red) + reason | ICS + reminder toggles after confirm |
| Coaching enrollment | Pending | Active (with start/end dates) | Rejected + reason | |
| Sponsorship application | Applied | Shortlisted → Final Selection | Rejected / Closed | 5-step tracker timeline |
| Scout connection | Pending | Accepted | Rejected | Both sides notified |
| Enquiry | New | Replied | — | Thread marks read |
| Listing (trial/tournament/sponsorship) | Draft | Published | Closed / Expired | Sponsorship needs admin approval to publish |
| User account | Pending (providers) | Active | Suspended / Deleted | Admin-managed |

---

## 12. Known Gaps & Quirks (found in code audit)

1. **FAB create sheet isn't role-gated** — coaches/organizers see "Add Achievement" etc.
2. **Application status timeline is static** — driven by route params, no live API fetch.
3. **Home screen mock data** — opportunity cards show hardcoded dates/prizes; "Recommended Athletes" actually shows academies+coaches; the **Follow button just navigates** (doesn't follow).
4. **Activity Hub rows aren't tappable** — read-only feed, no drill-down.
5. **My Applications "Registrations/Enquiries" tabs are static link menus**, not live lists.
6. **Discover's Age-Group filter is cosmetic** — selectable but not applied.
7. **Sponsorship apply document dropzone is UI-only** — no file picker wired.
8. **No payment gateway** — fees display-only, `payment_status` flipped manually by organizer.
9. **Phone numbers stored unverified**; OTP-resend endpoint is a known backend gap.
10. **Three different coach-detail routes** in use (`/coach-detail/:id`, `/coach-profile-detail/:id`, generic `/view-profile`) — consolidation opportunity.
11. **Admin has no mobile signup flow** — separate `/admin/login` + 2FA, web layout.

---

## 13. Key Product Decisions to Remember

1. **Approval, not booking.** Nothing is confirmed until a human provider approves.
2. **Parent = Athlete account**; federation = organizer sub-type; no extra roles.
3. **Only Athlete gets the MainShell bottom nav; only Scout gets ScoutShell.** Coach/Academy/Organizer/Sponsor are dashboard + drill-down apps.
4. **Sponsors face two gates:** account verification + per-listing opportunity approval.
5. **Admin is web-first** with 2FA; every admin action is audit-logged.
6. **Verification documents** flow: organizer/sponsor upload at onboarding → admin reviews in `/admin/approvals` → account activates.

---

## 14. Screen Inventory Quick Reference

**Auth/shared:** splash, role-selection, sign-up, login, onboarding-1/2, home, universal-search, search-filter, discover, opportunities, saved, activity-hub, my-applications, application-status, network, my-connections, connection-requests, scout-requests, scout-directory, athlete-directory, view-profile, notifications, settings, social-links, help-support, chat-list, chat-screen, create-post, post-detail, report, sports-venues(+detail), sponsors, scholarships(+detail), sponsorships(+detail), apply-sponsor, sponsor-pitch

**Coach:** coach-onboarding, coach-dashboard, coach-profile-edit, edit-coach-profile, coach-profile-detail, add-credential, edit-facilities, showcase-athletes, sponsor-directory-coach, coach-enquiry-inbox(+detail), coach-enrollments, my-coaching-enrollments

**Academy:** academy-onboarding, academy-dashboard, academy-profile, edit-academy-profile, post-trial, my-trials, registrant-list, registrant-detail, enquiry-inbox(+detail)

**Organizer:** organizer-onboarding, organizer-dashboard, organizer-profile, organizer-analytics, post-tournament, edit-tournament, my-tournaments, registration-management, capacity-management, results-publishing, results-view, tournament-calendar

**Sponsor:** sponsor-onboarding, sponsor-dashboard, sponsor-posting, my-sponsorships, athlete-discovery, athlete-profile-view, applications-inbox, application-detail, shortlist

**Scout:** scout-onboarding, scout-dashboard, scout-discovery, scout-athlete/:id, scout-connect/:athleteId, scout-shortlist, scout-connections, scout-profile

**Admin:** admin/login, admin/dashboard, admin/analytics, admin/settings, admin/users(+verify), admin/approvals, admin/moderation, admin/reports(+detail), admin/opportunities(+detail), admin/notifications/compose + targeting
