# SportX India — MVP Feature List (v2)

> Built from the old screen inventory + `FEATURE_DOCUMENTATION.md` (UI screenshots, features F-01 to F-40).
> Companion document: `SCREEN_INVENTORY.md` (screen IDs like `D.6`, `OR.7` refer to it).

**Priority legend**

| Tag | Meaning |
|---|---|
| **P0** | MVP launch — must ship |
| **P1** | MVP+ — immediately after launch / if capacity allows |
| **P2** | Post-MVP — design for it, don't build it now |

---

## 1. Product summary

SportX India is a mobile sports networking and discovery platform. Athletes (and parents), coaches, academies, event organizers and talent scouts discover each other, publish profiles, events, programs and opportunities, register, connect and message — with a verified-profile trust layer and an internal admin dashboard for moderation.

**Roles:** Athlete / Parent · Coach · Academy · Event Organizer · Talent Scout · Admin (internal)

**MVP goal:** prove that athletes can *be found* and *find opportunities*, and that providers (academies, coaches, organizers, scouts) get *real registrations, enquiries and shortlists*.

### Scope changes vs. the old inventory

| Topic | Old MVP | New MVP |
|---|---|---|
| Sponsor / Brand role | Separate role with 9 screens | **Removed as a role.** Sponsorship = an *Opportunity type* posted/browsed by other roles |
| Social feed & posts | Explicitly excluded | **Included, lightweight** (text/photo/video posts, like, comment, save; no stories, no group chat) |
| Athlete chat | Accepted connections only | Same rule kept + enquiry threads with coaches/academies/organizers |
| Leaderboard | Not present | Athletes in P0; coaches/academies/teams/events in P1 |
| Groups, polls, live/webinar | Not present | P2 |
| Payments | Not present | **Not in MVP** — fees are displayed, collected offline |
| Admin | Content, moderation, categories, expiry | Same + user management + verification queue |

---

## 2. Role × capability matrix (P0 only)

| Capability | Athlete / Parent | Coach | Academy | Organizer | Scout | Admin |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Sign up / onboarding / verification request | ✔ | ✔ | ✔ | ✔ | ✔ | — |
| Public profile + edit | ✔ | ✔ | ✔ | ✔ | ✔ | — |
| Explore, search, filter, save | ✔ | ✔ | ✔ | ✔ | ✔ | — |
| Follow / connect | ✔ | ✔ | ✔ | ✔ | ✔ | — |
| Posts (create, like, comment) | ✔ | ✔ | ✔ | ✔ | ✔ | moderate |
| Achievements & certificates | ✔ | ✔ | — | — | — | — |
| Media gallery | ✔ | ✔ | ✔ | ✔ | ✔ | — |
| Register for events/trials | ✔ | — | — | — | — | — |
| Create & manage events/trials | (P1) | (P1) | ✔ | ✔ | (P1) | edit |
| Manage registrations (approve/reject/export) | — | — | ✔ | ✔ | — | — |
| Training programs (create/manage) | — | ✔ | ✔ | — | — | edit |
| Facilities / venues | — | — | ✔ | (P1) | — | edit |
| Opportunities (browse & apply) | ✔ | ✔ | ✔ | ✔ | ✔ | — |
| Opportunities (create) | (P1) | ✔ | ✔ | ✔ | ✔ | edit |
| Enquiry / chat | ✔ | ✔ | ✔ | ✔ | ✔ | — |
| Shortlist + observations | — | — | — | — | ✔ | — |
| Leaderboard (view) | ✔ | ✔ | ✔ | ✔ | ✔ | config (P1) |
| Notifications (in-app + push) | ✔ | ✔ | ✔ | ✔ | ✔ | broadcast (P1) |
| Report / block | ✔ | ✔ | ✔ | ✔ | ✔ | resolve |

---

## 3. MVP feature list by module

`Ref` = feature ID from `FEATURE_DOCUMENTATION.md` (— = new or from old inventory only). `Screens` = IDs in `SCREEN_INVENTORY.md`.

### M1 — Accounts, onboarding & trust

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M1.1 | Sign up / login | Phone or email with OTP; password optional; T&C + privacy consent; session persistence | — | A.3–A.5 | P0 |
| M1.2 | Role selection | 5 roles at first launch; one account = one role in MVP | — | A.2 | P0 |
| M1.3 | Role-based onboarding | Short wizard per role capturing minimum data to create a useful profile | — | AT.2, CO.1, AC.1, OR.1, SC.1 | P0 |
| M1.4 | Guardian consent for minors | DOB < 18 triggers guardian name/phone/OTP; guardian controls messaging & visibility | — | A.9, AT.10 | P0 |
| M1.5 | Profile completion meter | Percentage + checklist with deep links; shown on Home, More, Profile | F-02 | AT.6, S.1 | P0 |
| M1.6 | Verification request & blue check | Upload ID/org proof → admin review → badge; status visible; notification on result | F-37 | A.10, AD.4 | P0 |
| M1.7 | Forgot password | OTP-based reset | — | A.6 | P1 |
| M1.8 | Language selection | English, Hindi, Gujarati | — | A.7 | P1 |
| M1.9 | Permissions primer | Location, notifications, media | — | A.8 | P1 |
| M1.10 | Role switching / multi-role account | Not designed in source UI | — | — | P2 |

### M2 — Profiles & portfolio

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M2.1 | Athlete profile | Cover, avatar, stats, bio, About (role, location, age group, college, interests), tabs Overview/Posts/Achievements/Media/Connections | F-13 | D.1, AT.3 | P0 |
| M2.2 | Multi-sport data | Primary sport, playing role, level, experience per sport | F-19 | AT.4 | P0 |
| M2.3 | Achievements & certificates | Add/edit/delete with certificate upload; shown on profile | F-18 | S.11, AT.5 | P0 |
| M2.4 | Media gallery | Photos/videos grid, "+n" overflow, full-screen viewer | — | S.10, S.28 | P0 |
| M2.5 | Coach profile | Level, experience, specialization, age groups, languages, programs tab | F-14 | D.2, CO.3 | P0 |
| M2.6 | Academy profile | Sports, age range, staff count, facilities, established year; Programs/Facilities/Events/Reviews tabs | F-15 | D.3, AC.3 | P0 |
| M2.7 | Organizer profile | Event stats, event types, venues, team, media | F-16 | D.4, OR.3 | P0 |
| M2.8 | Scout profile | Organization, sports focus, experience, availability; shortlist/reports visible only to owner | F-17 | D.5, SC.3 | P0 |
| M2.9 | Privacy controls | Profile visibility, who can connect/message; minors default to restricted | — | S.22, AT.10 | P0 |
| M2.10 | View as Public / Share profile | Preview and deep-link share | — | AT.7, S.30 | P1 |
| M2.11 | Social links | Instagram, LinkedIn, YouTube | — | AT.3 | P1 |
| M2.12 | Ratings & reviews | Display average + count (P0 read-only if seeded), submit after verified interaction | F-36 | D.14, D.15 | P1 |
| M2.13 | Team pages / Find-Add Team | — | — | D.17 | P2 |

### M3 — Discovery, search & saved

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M3.1 | Explore (All + category tabs) | Athletes, Coaches, Academies, Events (+ Venues for organizers); "See All" per section | F-04 | S.2, S.3 | P0 |
| M3.2 | Athlete discovery | Cards with sport, state, age group, position, achievements/media counts, Follow | F-05 | S.3, SC.4 | P0 |
| M3.3 | Coach discovery | Specialization tags, rating, Connect/Follow | F-06 | S.3 | P0 |
| M3.4 | Academy / training discovery | Cards with photos, rating, distance, chips, facilities; Academies / Coaches / Training segments | F-07 | S.3, D.3 | P0 |
| M3.5 | Event / trial discovery | Date badge, location, sport/age, registration status | F-08 | S.3, D.6 | P0 |
| M3.6 | Universal search | Cross-entity search with grouped results and empty state | F-04 | S.5 | P0 |
| M3.7 | Filters & sort | Sport, state/city, age group, position, level, facilities, price, date; sort by relevance / distance / rating | — | S.4 | P0 |
| M3.8 | Distance / "near me" | Uses city or location permission; shows km on academy cards | — | S.3 | P0 |
| M3.9 | Saved / bookmarks | Save athletes, coaches, academies, posts, opportunities, events | F-21 | S.20 | P0 |
| M3.10 | Venue / facility discovery | Browse venues | F-09 | D.13 | P1 |
| M3.11 | Recommendations | Rule-based "Recommended athletes / events for you" (sport, age, location) | — | AT.1 | P1 |
| M3.12 | Map view | Academy/venue map | — | D.16 | P2 |

### M4 — Events, trials & registrations

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M4.1 | Create / edit event or trial | Type (tournament/trial/camp), sport, dates, venue, categories/age, fee (display only), slots, eligibility, required documents, cover; draft/publish | F-12, F-27 | OR.5 | P0 |
| M4.2 | Event detail | Overview with slots progress, fee, organizer, status; Schedule & Gallery tabs (P1) | F-08 | D.6 | P0 |
| M4.3 | Event registration | Individual or team form, document upload, consent; duplicate-registration guard; capacity enforced | F-08 | D.7, D.8 | P0 |
| M4.4 | Manage registrations | Tabs All/Approved/Pending/Rejected, search, filter, bulk approve/reject, registrant detail | F-28 | OR.7, OR.8 | P0 |
| M4.5 | Export registrant list | CSV/Excel export | F-28 | OR.7 | P0 |
| M4.6 | Registration status & notifications | Pending → Approved/Rejected with push + in-app | — | AT.9, S.16 | P0 |
| M4.7 | Auto-expiry | Events/opportunities auto-close after date/deadline per admin rules | — (old doc) | AD.10 | P0 |
| M4.8 | Event schedule & gallery | Timetable/fixtures, photos | F-27 | OR.9, OR.10 | P1 |
| M4.9 | Results publishing | Brackets/final results | — (old doc) | OR.11 | P1 |
| M4.10 | Event analytics (basic) | Views, registrations, inquiries, timeline chart, top sources | F-29 | OR.12 | P1 |
| M4.11 | Announcements | Message registrants/followers | — | OR.14 | P1 |
| M4.12 | Calendar view | Calendar/list toggle on tournaments | — (old doc) | S.3 | P1 |
| M4.13 | Online payments, revenue analytics | Not shown in source UI | — | — | P2 |
| M4.14 | Promote event | Paid/boosted placement | — | OR.15 | P2 |

### M5 — Opportunities (trials, scholarships, sponsorships, camps)

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M5.1 | Opportunity listing & detail | Types: scholarship, sponsorship, tryout, camp; provider, eligibility, benefits, deadline | F-10 | D.9 | P0 |
| M5.2 | Create opportunity | Academy, Organizer, Coach, Scout (Athlete P1) | F-10 | AC.9, SC.12 | P0 |
| M5.3 | Apply / submit pitch | Profile auto-attached + pitch text + documents | — (old doc) | D.10 | P0 |
| M5.4 | My Opportunities | Applied / Saved / Created tabs | F-10 | AT.8 | P0 |
| M5.5 | Applicant review | Provider views applicants, shortlists/declines | — | AC.9 | P1 |
| M5.6 | Scouting opportunities hub | Trials / Scholarships / Camps tabs | F-35 | SC.11 | P0 |

### M6 — Programs, facilities & academy operations

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M6.1 | Training programs | Create/edit; title, age group, duration, mode, price, Active/Drafts/Past | F-26 | CO.4, CO.5, D.11 | P0 |
| M6.2 | Program / listing enquiry | Enquiry form creates a chat thread with provider | — | D.12 | P0 |
| M6.3 | Facilities | Add/edit/list (ground, indoor, gym, classroom, changing rooms, other) | F-30 | AC.7, AC.8, D.13 | P0 |
| M6.4 | Our Athletes | Athlete links to academy via invite/accept; age filter | F-31 | AC.5, AC.10 | P1 |
| M6.5 | Recruit staff / team | Staff openings and team management | F-32 | AC.11, OR.16 | P2 |
| M6.6 | Collaborations | Org-to-org partnerships | — | AC.12, OR.17 | P2 |

### M7 — Social: feed, follow, connections & messaging

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M7.1 | Create post | Text, photo, video, hashtags; edit/delete own | F-12 | S.9 | P0 |
| M7.2 | Feed | Tabs For You / Following / Athletes / Coaches / Academies / Events; chronological + simple relevance | F-11 | S.1 | P0 |
| M7.3 | Post interactions | Like, comment, save; counts | F-11 | S.27 | P0 |
| M7.4 | Follow / unfollow | One-way follow for any entity | F-20 | S.3, D.x | P0 |
| M7.5 | Connect (mutual) | Request/accept/decline/cancel/remove | F-20 | S.19 | P0 |
| M7.6 | 1-to-1 messaging | Text chat; allowed only for accepted connections or enquiry threads; Chats / Requests tabs; unread badges | F-25 | S.17, S.18 | P0 |
| M7.7 | Share post externally | Link share | F-11 | S.30 | P1 |
| M7.8 | Mentions & hashtags | Mention notifications | F-24 | S.16 | P1 |
| M7.9 | Chat media attachments | Photo/doc in chat | — | S.18 | P1 |
| M7.10 | Community: Network suggestions & Events tab | Suggested For You | F-22 | S.12 | P1 |
| M7.11 | Groups | Join interest/professional groups | F-23 | S.13, S.14 | P2 |
| M7.12 | Polls | Create/vote | F-40 | S.8 | P2 |
| M7.13 | Live / webinar / stream | Not designed in source UI | F-39 | CO.8 | P2 |
| — | *Not in any phase:* stories, open group chat, public DMs from strangers | Kept out per old inventory | — | — | — |

### M8 — Leaderboard

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M8.1 | Athlete leaderboard | Podium + ranks 4–10; filters sport, location, age group; points from verified achievements + activity | F-03 | S.6, AT.1 | P0 |
| M8.2 | Leaderboard strip on Home | Top 5 with sport chips, View All | F-03 | S.1 | P0 |
| M8.3 | Coach / Academy / Team / Event leaderboards | Tabs visible in UI | F-03 | S.6 | P1 |
| M8.4 | Points rules page & admin config | Transparent formula, season reset | — | S.7, AD.11 | P1 |

### M9 — Notifications

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M9.1 | In-app notification feed | Role-adapted tabs, unread dots, Today/Yesterday/This Week/Earlier, Mark all as read | F-24 | S.16 | P0 |
| M9.2 | Push notifications | Follows, connection requests, messages, enquiries, registration updates, verification result | F-24 | S.16 | P0 |
| M9.3 | Deadline / nearby reminders | Event/opportunity deadlines, "trial near you" | — (old doc) | S.16 | P1 |
| M9.4 | Admin broadcast | Platform announcements | — | AD.12 | P1 |
| M9.5 | Email / SMS notifications | — | — | — | P2 |

### M10 — Talent scouting

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M10.1 | Scout dashboard | Top Talents This Week, quick actions, upcoming trials | F-01 | SC.2 | P0 |
| M10.2 | Discover talents | Filters: sport, age group, position, level, location, achievements | F-05 | SC.4 | P0 |
| M10.3 | Shortlist | Add/remove, status (High Potential / Good Potential / Under Review / Final), private notes, tabs All/Under Review/Final | F-33 | SC.5, SC.6 | P0 |
| M10.4 | Add observation | Quick note + rating | F-33 | SC.10 | P0 |
| M10.5 | Contact athlete / parent | Platform-mediated request; minors route to guardian | — (old doc) | SC.13 | P0 |
| M10.6 | Talent report | Key info, 5-dimension assessment, conclusion, notes | F-34 | SC.8, SC.9 | P1 |
| M10.7 | Compare talents | 2–3 side-by-side | F-33 | SC.7 | P1 |
| M10.8 | Top performers shortcut | Leaderboard prefiltered | — | S.6 | P1 |

### M11 — Safety, moderation & admin

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M11.1 | Report user / post / listing | Reason + notes; confirmation | — (old doc) | S.26 | P0 |
| M11.2 | Block user | Hides content, blocks chat; manage list | — (old doc) | S.23 | P0 |
| M11.3 | Moderation queue & actions | Approve, reject, remove, warn, suspend | — | AD.7, AD.8 | P0 |
| M11.4 | Verification queue | Approve/reject with reason | F-37 | AD.4 | P0 |
| M11.5 | User management | Search, suspend, ban | — | AD.3 | P0 |
| M11.6 | Content manager | CRUD on academies, coaches, events, programs, facilities, opportunities, posts | — (old doc) | AD.5, AD.6 | P0 |
| M11.7 | Master data | Sports, cities/states, age groups, positions | — (old doc) | AD.9 | P0 |
| M11.8 | Expiry rules | Auto-expire events/opportunities/stale listings | — (old doc) | AD.10 | P0 |
| M11.9 | Admin dashboard | KPIs and recent activity; 2FA login | — | AD.1, AD.2 | P0 |

### M12 — Account, settings & platform

| ID | Feature | Detail / acceptance notes | Ref | Screens | Pri |
|---|---|---|---|---|---|
| M12.1 | Settings & privacy | Visibility, messaging permission, notification toggles, language, change password | F-38 | S.22 | P0 |
| M12.2 | Delete account | Required for app-store compliance | — | S.22 | P0 |
| M12.3 | Help, About, legal | FAQs, report a problem, terms, privacy, community guidelines | F-38 | S.24, S.25 | P0 |
| M12.4 | Logout | With confirmation | F-38 | S.29 | P0 |
| M12.5 | Empty / loading / error / offline states | Not in source UI — must be designed for every list | §8 of source | all | P0 |
| M12.6 | Product analytics & crash reporting | Funnel events for signup, registration, enquiry, shortlist | — | — | P0 |
| M12.7 | Deep links | Share profile/event | — | S.30 | P1 |

---

## 4. Explicitly out of MVP (P2 / parked)

Online payments & revenue analytics · Promote event · Groups · Polls · Live/webinar/streaming · Map view · Role switching · Team pages / Find-Add Team · Staff recruiting & team management · Collaborations · Email/SMS notifications · Stories · Group chat · Sponsor/Brand as a standalone role.

---

## 5. User flows (feature level)

### 5.1 Onboarding & trust
```text
Splash -> Role selection -> Sign up (OTP) -> [if <18: Guardian consent]
 -> Role onboarding wizard -> Home (completion meter shown)
 -> Complete profile -> Request verification -> Admin approves -> Blue check + notification
```

### 5.2 Athlete: discover → register for a trial
```text
Home "Opportunities" / Explore -> Events -> filter (sport, city, age, date)
 -> Trial detail (fee, eligibility, slots left) -> Register + upload documents
 -> Pending -> Organizer approves -> Notification -> My Registrations
```

### 5.3 Athlete: scholarship / sponsorship
```text
Opportunities -> filter by type -> Detail -> Apply with pitch (profile auto-attached)
 -> Provider reviews (P1) -> Status update notification -> My Opportunities
```

### 5.4 Athlete: academy / coach enquiry
```text
Explore -> Academies/Coaches/Training -> filters (distance, facilities, age)
 -> Academy / Coach profile -> Program -> Enquire -> Chat thread
 -> Reply notification -> Enrol offline (MVP)
```

### 5.5 Athlete: build credibility
```text
Profile -> completion checklist -> add sports -> add achievements + certificates -> upload media
 -> post updates -> request verification -> climb leaderboard
```

### 5.6 Networking
```text
Explore/Leaderboard -> athlete profile -> Follow (instant) or Connect (request)
 -> Accept -> Chat unlocked -> Report / Block available at any point
```

### 5.7 Coach: program → enquiries
```text
Onboarding -> Home -> My Training Programs -> Add Program -> Publish
 -> Appears in profile + Explore -> Enquiry notification -> Reply in chat
```

### 5.8 Academy: listing → trial → registrants
```text
Onboarding -> Listing live (Explore) -> Add facilities + programs
 -> Create trial -> Registrations come in -> Approve/Reject -> Export -> Trial closes (auto-expiry)
 -> Scholarship/opportunity posts -> review applicants (P1)
```

### 5.9 Organizer: event lifecycle
```text
Onboarding -> Create Event (draft) -> Publish -> Share
 -> Registrations (capacity bar) -> Approve/Reject/Export
 -> Schedule + announcements (P1) -> Publish results (P1) -> Analytics (P1)
```

### 5.10 Talent scout: discover → shortlist → contact
```text
Onboarding -> Discover Talents (filters) -> Athlete profile
 -> Shortlist with status + note / Add observation
 -> Talent report (P1) -> Compare (P1)
 -> Contact athlete/parent (guardian for minors) -> Accepted -> Chat
 -> Post scouting opportunity -> athletes apply
```

### 5.11 Content & safety loop
```text
User sees problematic content -> Report -> Moderation queue -> Admin action (remove/warn/suspend)
 -> Outcome notifications -> Repeat offenders auto-flagged (P1)
Block: Chat/profile -> Block -> hidden both ways
```

### 5.12 Admin
```text
Login (2FA) -> Dashboard -> Verification queue / Moderation queue / User management
 -> Content manager (fix records) -> Master data -> Expiry rules
```

---

## 6. Rules the build depends on

1. **One account = one role** in MVP.
2. **Minors (<18):** guardian consent mandatory; default profile visibility limited; chat only with accepted connections *and* guardian-allowed; scouts and strangers contact a minor through a request that notifies the guardian; no precise location shown.
3. **Chat rule:** allowed only (a) between accepted connections or (b) inside an enquiry/registration thread created by a user action. No cold DMs.
4. **Verification** is manual (admin). Blue check shows on profile, cards, search results.
5. **Fees** are informational. No payment collection in MVP; show "Pay at venue/offline" text.
6. **Capacity:** registration closes automatically when slots are full; duplicates blocked.
7. **Expiry:** events/opportunities auto-archive after end date/deadline (admin-configurable).
8. **Leaderboard** counts only verified achievements + platform activity; minors appear by first name + initial unless guardian opts in.
9. **Moderation:** every post, listing and profile can be reported; SLA target set by ops.
10. **Scout data is private:** shortlists, notes and reports are visible only to the scout and admin.

---

## 7. Success metrics for MVP

| Area | Metric |
|---|---|
| Activation | % of signups completing role onboarding; average profile completion |
| Supply | Academies/coaches/organizers with ≥1 live listing; events published per week |
| Demand | Registrations and enquiries per live listing |
| Engagement | Weekly active users; posts/follows per user; chat reply rate |
| Trust | % verified profiles; report-to-resolution time |
| Scouting | Shortlists per scout; contact requests accepted |

---

## 8. Known gaps in the source UI (need design before build)

- Auth, role selection, guardian consent, onboarding forms (not in screenshots)
- Create/edit forms for events, programs, facilities, opportunities, achievements, posts
- Chat thread screen, filter sheets, review screens, registration form, payment (excluded)
- Empty / loading / error / offline states
- Unclear labels: coach profile stat labels, analytics "300" period pill
- Mock-data inconsistencies to fix: cricket athlete with a throwball achievement; registration tabs 280 + 30 ≠ 320

---

## 9. Decisions to confirm

| # | Decision | Recommendation |
|---|---|---|
| 1 | Sponsor role removed — confirm brands will use "Opportunity" or be onboarded by admin | Keep removed for MVP; add "Brand" role later if sponsors want their own tools |
| 2 | Feed/posts added despite old "no social feed" rule | Keep lightweight; invest in moderation first |
| 3 | Leaderboard in P0 | Keep athletes only; define points formula before build |
| 4 | Parent vs athlete account for minors | Single athlete account with guardian consent; separate parent login is P2 |
| 5 | Payments | Post-MVP; collect fees offline |
| 6 | Hosting of verification docs | Private storage, admin-only access |
