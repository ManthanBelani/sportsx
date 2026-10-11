# Functional & Non-Functional Requirements — SportX India

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

Requirements are numbered `FR-<MODULE>-<n>` / `NFR-<n>` and prioritized **MoSCoW**: **M**ust / **S**hould / **C**ould. Modules follow the six roles plus shared platform concerns. Every requirement traces to the MVP Overview feature list or Screen Inventory.

**Global exclusions (by decision, apply to all requirements):**
- No in-app payment processing. Entry fees/prize pools/stipends are display-only fields; organizer payment tracking is a manual status flag. Payments are **parked (P2)**.
- **OTP signup/login supports phone OR email at P0** (6-digit code + resend). Password login is kept alongside. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "email primary; phone deferred" is superseded (D1/D5).
- **Guardian consent is mandatory for minors (<18)** before profile activation; restricted visibility/messaging defaults; leaderboard anonymization.
- Notification/OTP vendor is unspecified (abstract provider interfaces only); the OTP SMS vendor is now **blocking**.
- Admin **verification queue + user management** are **P0**; remaining admin pages may follow. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "admin built in a later phase" is superseded (D6).
- **Roles:** athlete, coach, academy, organizer, scout, admin. `sponsor` is **removed** (D2). Generalized providers (NGO/doctor/store etc.) are directory profiles, not login roles.
- **30 profile fields per role** (8–9 mandatory) — see `SportX_Mandatory_Fields.md` (supersedes the old `SportX_India_Mandatory_Fields_MVP.pdf`, AS-05). New requirement IDs are appended (e.g. `FR-SOC-*`, `FR-OPP-*`) rather than renumbering existing ones.

---

---

## 1. AUTH — Authentication & Onboarding

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-AUTH-1 | The app shall present a splash screen on launch with branding and a loading state. | S | S1 |
| FR-AUTH-2 | The app shall present role selection with **five** sign-up cards: Athlete/Parent, Coach, Academy, Organizer, Talent Scout. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 listed six cards incl. Sponsor/Brand; the `sponsor` role is removed (D2). Generalized providers are directory profiles, not sign-up cards. | M | A.2 |
| FR-AUTH-3 | The app shall allow sign-up with phone number **or** email input, a terms & privacy checkbox, and a "Continue with Google" option. | M | A.3 |
| FR-AUTH-4 | The app shall verify the account with a 6-digit OTP code screen (A.4) including resend-with-timer; sets `phone_verified_at`/`email_verified_at`. **Channel: phone OR email (both P0).** **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "primary channel: email; phone OTP deferred" is superseded (D1/D5). | M | A.4 + decision |
| FR-AUTH-5 | The app shall provide login with phone/email + password or OTP toggle, forgot-password, and sign-up links. | M | A.5 |
| FR-AUTH-6 | On first sign-up, athletes/parents shall complete onboarding: (a) multi-select sport(s) + age group; (b) skill level + city/state. Full athlete profile totals **30 fields** (8 mandatory) — see FR-MAND. | M | AT.2 |
| FR-AUTH-7 | On first sign-up, coaches shall complete onboarding capturing sport(s) coached, certifications, and years of experience. | M | CO.1 |
| FR-AUTH-8 | On first sign-up, academies shall complete onboarding capturing academy name, sport(s), and city. | M | AC.1 |
| FR-AUTH-9 | On first sign-up, organizers shall complete onboarding capturing organization name, type (Federation/Club/Other), and verification document upload. | M | OR.1 |
| FR-AUTH-10 | **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 sponsor onboarding (brand name, logo, category, docs) is retired with the `sponsor` role (D2). Brands/NGOs/etc. are onboarded as **generalized provider directory profiles** (FR-GP-1) instead. | M | SP1 → FR-GP-1 |
| FR-AUTH-11 | Verification document uploads (organizer, scout, etc.) shall be stored privately (signed URLs) and reviewed through the **admin verification queue** (FR-VERIF-1) — a **P0** feature in v3. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "review workflow is an assumption (no approval screen)" is superseded (D6, A.10/AD.4). | S | OR.1, A.10 |
| FR-AUTH-12 | The Google sign-in option shown in the wireframe may be deferred if it adds delivery risk; OTP must always work. | C | A.3 |
| FR-AUTH-13 | On sign-up/login, the app shall **require guardian consent for any athlete whose DOB < 18**: guardian name + phone + relationship, OTP sent to the guardian, and verified consent before profile activation. Records `guardian_consents` and closes **AS-34**. | M | A.9 |
| FR-AUTH-14 | On first sign-up, talent scouts shall complete onboarding capturing organization/affiliation (or independent), sports focus, experience, availability region, languages, and location. | M | SC.1 |
| FR-AUTH-15 | The app shall allow requesting a **verification (blue check)** by uploading ID/org proof, showing status (Pending/Verified/Rejected+reason), and surfacing the badge on profile/cards/search. | M | A.10 |
| FR-AUTH-16 | The app shall support forgot-password via OTP (P1), alongside the token-link flow. | S | A.6 |

## 2. ATH — Athlete / Parent

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ATH-1 | Athletes shall have a viewable profile: photo, name, sport(s), age group, city/state, achievements list, media gallery preview. | M | A4 |
| FR-ATH-2 | Athletes shall edit profile fields, add/remove achievements, and manage a media gallery (upload, delete, drag-to-reorder photos/videos). | M | A5, A6 |
| FR-ATH-3 | Athletes shall see a home dashboard with: search bar, recommended academies, trials closing soon, saved/upcoming tournaments, new scholarships. | M | A3 |
| FR-ATH-4 | Athletes shall browse the Academy Directory (card list: thumbnail, name, sport · city, fee range) and open a detail page (facilities, coaches, age groups, timings, fees, location map preview, contact). | M | A7, A8, T1, T2 |
| FR-ATH-5 | Athletes shall browse the Coach Directory (name, sport, experience, fee, city) and open a detail page (qualifications, experience, fee structure, location). | M | A9, A10 |
| FR-ATH-6 | Athletes shall send an enquiry to a coach via a modal/form with message box and preferred date/time. | M | A11, T3 |
| FR-ATH-7 | Athletes shall browse Trial Listings (sport, date, venue, organizer, entry fee) and open a detail page (eligibility, required documents, entry fee, contact). | M | A12, A13 |
| FR-ATH-8 | Athletes shall register for a trial via a form (profile auto-fill, document upload, **payment note only — informational**), and receive a confirmation screen with registration ID, add-to-calendar, and reminder toggle. | M | A14, A15, T3 |
| FR-ATH-9 | Athletes shall browse a Tournament Calendar with calendar/list toggle, and open a detail page (format, dates, venue, prize pool, entry categories, entry fee). | M | A16, A17 |
| FR-ATH-10 | Athletes shall register for a tournament via a form (category selection, team/individual selection, personal details). | M | A18, T3 |
| FR-ATH-11 | Athletes shall browse **Opportunities** (unified: scholarship/sponsorship/tryout/camp) with type/sport/age/deadline filters and open a detail page (provider, eligibility, benefits/amount, deadline). **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "scholarship feed, external link" is superseded: athletes now apply **in-app with a pitch** (FR-OPP-3) and track status (D3). | M | D.9 |
| FR-ATH-12 | (Merged into FR-ATH-11.) Sponsorships are an opportunity type, not a separate feed. **[SUPERSEDED — see Backend-Feature-Delta.md]** | M | D.9 |
| FR-ATH-13 | Athletes shall apply/pitch to **any opportunity** via a form with pitch note, documents, and auto-attached profile snapshot; duplicate applications blocked (409). | M | D.10, FR-OPP-3 |
| FR-ATH-14 | Athletes shall track activity in two hubs: **My Registrations** (events/trials; status Pending/Approved/Rejected, cancel) and **My Opportunities** (Applied/Saved/Created; status chips). **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "My Activity: Trials/Tournaments/Sponsorships" is superseded (AT.8/AT.9). | M | AT.9, AT.8 |
| FR-ATH-15 | Athletes shall save/bookmark any listing (incl. posts, opportunities, events) and view saved items grouped by type; the save/unsave heart is available on detail pages. | M | S.20 |
| FR-ATH-16 | Athletes shall receive deadline & date reminders for saved trial dates, tournament dates, and opportunity deadlines (delivery channel per NFR/vendor decision). | M | M9.3 |
| FR-ATH-17 | **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "scholarship applications happen externally; state not tracked" is superseded: applications are in-app and status is tracked (D3, AT.8). | S | AT.8 |
| FR-ATH-18 | Athletes shall view an **athlete leaderboard** (sport/location/age filters; podium + ranks 4–10) and a home leaderboard strip (top 5). Points come from verified achievements + completion + activity; minors are anonymized (first name + initial). | M | S.6, AT.1 |
| FR-ATH-19 | Athletes shall use a **feed** (tabs For You / Following / Athletes / Coaches / Academies / Events), create text/photo/video posts, and like, comment on, and save posts. | M | S.1, S.9, S.27 |
| FR-ATH-20 | Athletes shall **follow** (one-way) and **connect** (mutual request/accept/decline/cancel/remove) other users/profiles. | M | S.3, S.19 |
| FR-ATH-21 | Athletes shall use **1-to-1 chat** with accepted connections and within enquiry threads (Chats/Requests tabs, unread badges); no cold DMs. | M | S.17, S.18 |
| FR-ATH-22 | Athletes (or their guardian) shall manage **parental controls** for minors: consent status, messaging restrictions, profile visibility, and leaderboard name mode. | M | AT.10 |
| FR-ATH-23 | Athletes shall discover and view **training programs** (CO.4/AC.4) and **facilities/venues** (D.13) and enquire about them (D.12 → chat thread). | M | D.11, D.13 |

## 3. COACH — Coach

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-COACH-1 | Coaches shall create/edit a public listing: photo, name, sport(s), certifications, experience, fee structure, location, bio. | M | C2 |
| FR-COACH-2 | Coaches shall see a dashboard with new-enquiry count, profile completeness meter, and quick actions (Edit Listing, Browse App). | M | C3 |
| FR-COACH-3 | Coaches shall have an enquiry inbox (tabs All/New/Replied) listing athlete name, sport, message preview, time, and a Reply action. | M | C4, T4 |
| FR-COACH-4 | Coaches shall open an enquiry detail and reply in a message-thread view. | M | C5, T4b |
| FR-COACH-5 | Coaches shall be able to browse the full app like an athlete/parent (reusing all directory/detail screens). | M | CO.2 |
| FR-COACH-6 | Coaches shall create/edit **training programs** (title, sport, age group, duration, mode, price, schedule, description; Save draft / Publish) and manage them (tabs Active/Drafts/Past). | M | CO.4, CO.5 |
| FR-COACH-7 | Coaches shall create/edit **opportunities** (scholarship/sponsorship/tryout/camp). | M | AC.9 (reused) |
| FR-COACH-8 | Coaches shall create/manage **events/trials** (P1). | S | CO.6 |
| FR-COACH-9 | Coaches shall receive program/listing enquiries as chat threads and reply. | M | D.12, S.18 |

## 4. ACAD — Academy

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ACAD-1 | Academies shall create/edit a public listing: cover photo, name, sport(s), facilities, fee range, age groups, timings, coaches, photos. | M | AC2 |
| FR-ACAD-2 | Academies shall see a dashboard with active-trials count, enquiry count, a "+ Post New Trial" action, and recent registrants. | M | AC3 |
| FR-ACAD-3 | Academies shall create/edit trials: name, sport, date & time, venue, eligibility, entry fee, required documents, contact, and draft/published status; save & publish supported. | M | AC4 |
| FR-ACAD-4 | Academies shall manage their trials in a list with status (Draft/Published/Closed) and edit/close actions. | M | AC5, T1 |
| FR-ACAD-5 | Academies shall view a registrant list per trial with counts (registered, spots left) and per-row document-submission status. | M | AC6 |
| FR-ACAD-6 | Academies shall view a registrant detail (profile snapshot, submitted documents with viewer) and take actions **Mark as Verified** / **Reject**. | M | AC7 |
| FR-ACAD-7 | Academies shall have an enquiry inbox and enquiry detail/reply identical in behavior to the coach inbox. | M | AC8, AC9, T4/T4b |
| FR-ACAD-8 | Academies shall manage **facilities** (name, type [ground/indoor/gym/court/pool/other], size/lanes, amenities, images) with list + Add/Edit (tabs All/Grounds/Indoor/Gym/Other) and a public facility detail page. | M | AC.7, AC.8, D.13 |
| FR-ACAD-9 | Academies shall create/manage **training programs** (reusing CO.4/CO.5) and **opportunities** (scholarships/sponsorships/tryouts/camps). | M | AC.4, AC.9 |
| FR-ACAD-10 | Academies shall run events/trials (reusing the organizer flow OR.5–OR.8) with registrant review and CSV export. | M | AC.6, OR.5–OR.8 |
| FR-ACAD-11 | Academies shall maintain **Our Athletes** (age-chip filters, ratings, invite-by-phone with accept flow) (P1). | S | AC.5, AC.10 |

## 5. ORG — Organizer

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ORG-1 | Organizers shall see a dashboard with active trials count, tournaments count, + Post Trial / + Post Tournament actions, and upcoming deadlines. | M | O2 |
| FR-ORG-2 | Organizers shall create/edit/publish/close trial listings with the same fields as academy trial posting. | M | O3, O4, AC4 |
| FR-ORG-3 | Organizers shall create/edit tournaments: name, format (dropdown), dates, venue, entry fee, prize pool, categories; save & publish supported. | M | O5 |
| FR-ORG-4 | Organizers shall manage tournaments in a list with status and registrant counts. | M | O6, T1 |
| FR-ORG-5 | Organizers shall manage registrations per event, filterable by category with capacity meters (`filled/capacity` per category) and a **manual payment status flag** per registrant (e.g. Paid / Pending — **not** a payment integration). | M | O7 |
| FR-ORG-6 | Organizers shall adjust category capacity (slider/input per category) and toggle a waitlist when full. | S | O8 |
| FR-ORG-7 | Organizers shall publish results per category: winner, runner-up, 3rd place, plus bracket image upload. | M | O9 |
| FR-ORG-8 | Published results shall be publicly viewable as a bracket visualization and/or ranked list (🥇/🥈/🥉). | M | OR.11 |
| FR-ORG-9 | Organizers shall create/edit events via a unified flow with a **type** (tournament/trial/camp), sport, dates, venue, age/categories, fee (display), slots, eligibility, required documents, cover; draft/publish. | M | OR.5 |
| FR-ORG-10 | Organizers shall **export registrant lists** to CSV/Excel (role-scoped). | M | OR.7 |
| FR-ORG-11 | Organizers shall create/edit **opportunities** (scholarship/sponsorship/tryout/camp) and review applicants (shortlist/decline — P1). | M | OR.2, AC.9 |
| FR-ORG-12 | Organizers shall manage event **schedule/fixtures** and **gallery**, and post **announcements** to registrants/followers (P1). | S | OR.9, OR.10, OR.14 |
| FR-ORG-13 | Organizers shall view basic **event analytics** (views/registrations/inquiries, timeline, top sources) (P1). | S | OR.12 |
| FR-ORG-14 | Organizers shall manage owned **venues** (owner CRUD) alongside public browse (P1). | S | OR.13 |

## 6. SPON — Sponsor / Brand **[SUPERSEDED — see Backend-Feature-Delta.md]**

> The `sponsor` role is **removed** (D2). All `FR-SPON-*` capabilities are superseded: sponsorships become an opportunity type (FR-OPP-2, posted by Academy/Organizer/Coach/Scout); athlete discovery + shortlisting move to the **Talent Scout** module (§7) and the provider applicant-review flow (FR-OPP-4, P1). Rows below are preserved for history.

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-SPON-1 | Sponsors shall see a dashboard with active listings count, new applications count, + Post Sponsorship action, and recent applications. | M | SP2 |
| FR-SPON-2 | Sponsors shall create/edit sponsorship listings: title, sport, eligibility criteria, benefits offered, deadline; save & publish supported. | M | SP3 |
| FR-SPON-3 | Sponsors shall manage their sponsorships in a list with status and applications count. | M | SP4, T1 |
| FR-SPON-4 | Sponsors shall search/filter athlete profiles by sport, age group, city, skill level; result cards show name, sport · age group · city, and achievement count. | M | SP5 |
| FR-SPON-5 | Sponsors shall view an athlete profile (photo, achievements, media gallery) with Shortlist and Message actions. **Message action mentions an undefined thread — see AS-* in Glossary.** | M | SP6 |
| FR-SPON-6 | Sponsors shall have an applications inbox listing athlete name, sport, date applied, status. | M | SP7, T4-style |
| FR-SPON-7 | Sponsors shall view an application detail (pitch note, applied-to listing, date, view-full-profile) with actions: Shortlist / Reject / Reply. | M | SP8 |
| FR-SPON-8 | Sponsors shall maintain a shortlist grouped list with a free-text note per athlete. | M | SP9 |

## 7. TS — Talent Scout

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-TS-1 | On first sign-up, talent scouts shall complete onboarding capturing organization/affiliation, sports specialization, experience, and location. | M | TS1 |
| FR-TS-2 | Talent scouts shall see a dashboard with search shortcut, saved athletes count, and activity summary tiles. | M | TS2 |
| FR-TS-3 | Talent scouts shall discover athletes via filterable cards by sport, age group, location, skill level, and achievements. | M | TS3 |
| FR-TS-4 | Talent scouts shall use advanced filters (category, competition level, achievements) alongside the global filter panel. | M | TS3 |
| FR-TS-5 | Talent scouts shall view an athlete's public profile: sports history, achievements, media gallery, with shortlist and connect CTAs. | M | TS4 |
| FR-TS-6 | Talent scouts shall maintain a shortlist of saved athlete profiles with remove option. | M | TS5 |
| FR-TS-7 | Talent scouts shall send an enquiry or connection request to an athlete/parent through the platform. | M | TS6 |
| FR-TS-8 | Talent scouts shall browse the full app like an athlete/parent (reusing all directory/detail screens). | M | TS3 (reused) |
| FR-TS-9 | Talent scouts shall add **observations** on an athlete (quick note + rating + optional media). | M | SC.10 |
| FR-TS-10 | Talent scouts shall maintain a **shortlist pipeline** with status (Under Review / Good Potential / High Potential / Final), tags, and private notes; tabs All/Under Review/Final. Scout data is private (owner + admin only). | M | SC.5, SC.6 |
| FR-TS-11 | Talent scouts shall write **talent reports** (5-dimension assessment, conclusion, notes) and **compare** 2–3 athletes side by side (P1). | S | SC.8, SC.9, SC.7 |
| FR-TS-12 | Talent scouts shall contact an athlete/parent via a platform-mediated request with a stated purpose; for minors the request is **routed to the guardian** and chat unlocks only after consent/acceptance. | M | SC.13 |
| FR-TS-13 | Talent scouts shall browse a **scouting opportunities hub** (Trials/Scholarships/Camps tabs) and post scouting opportunities. | M | SC.11, SC.12 |

## 8. ADMIN — Admin (P0 slice: users + verification queue)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ADMIN-1 | Admins shall log in through a dedicated admin portal with email, password, and 2FA. | M | AD1 |
| FR-ADMIN-2 | Admins shall see a dashboard with counters: active listings, flagged items, pending expirations, new signups. | M | AD2 |
| FR-ADMIN-3 | Admins shall manage content via a category picker (Academies, Coaches, Events/Trials, **Opportunities, Programs, Facilities, Posts**) with per-category counts. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 kept separate Scholarships/Sponsorships categories; both fold into **Opportunities**. | M | AD.5 |
| FR-ADMIN-4 | Admins shall browse/search/sort/filter a content list per category. | M | AD.6 |
| FR-ADMIN-5 | Admins shall create/edit/delete any record via a dynamic form matching the owner's own edit screen schema. | M | AD.6 |
| FR-ADMIN-6 | Admins shall see a flagged/reported queue (users, posts, listings) showing item, reason, report count, and time since first report. | M | AD.7 |
| FR-ADMIN-7 | Admins shall take moderation actions on a flagged item: Approve (no action), Edit, Remove, Warn Owner, **Suspend**; with report detail and view link. Outcome notifies reporter + reported. | M | AD.8 |
| FR-ADMIN-8 | Admins shall configure content expiry rules per content type (e.g. trials auto-expire N days after event date; tournaments N days after final match date; opportunities expire on listed deadline; programs/facilities do not expire). | M | AD.10 |
| FR-ADMIN-9 | Admins shall monitor expirations in tabs Pending/Expired/Overridden, with Override and Restore actions. | M | AD.10 |
| FR-ADMIN-10 | Admins shall manage master categories: sports, cities/states, age groups, **positions** (add/edit/remove). | M | AD.9 |
| FR-ADMIN-11 | **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "scholarships created exclusively by admins" is superseded (D3): providers (Academy/Organizer/Coach/Scout) now post opportunities; admin retains only legacy government/exclusive schemes (`posted_by_admin=true`). | M | FR-OPP-2 |
| FR-ADMIN-12 | Admins shall **manage users**: search/filter by role/status, view detail, and **suspend/ban** (**P0**). | M | AD.3 |
| FR-ADMIN-13 | Admins shall review the **verification queue** and approve/reject with a required reason; the result notifies the requester and surfaces a blue-check badge (**P0**). | M | AD.4 |
| FR-ADMIN-14 | Admins shall configure **leaderboard** weights and season length, and reset a season (P1). | S | AD.11 |
| FR-ADMIN-15 | Admins shall compose/schedule **broadcast notifications** to a filtered audience (P1). | S | AD.12 |

## 9. DISC — Discovery, Search & Filters (shared)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-DISC-1 | A universal search screen shall offer a search bar, recent searches, and trending sport chips. | M | S6 |
| FR-DISC-2 | Unified search results shall be presented in grouped/tabbed results across entity types (**Athletes, Coaches, Academies, Events, Opportunities, Programs, Facilities, Venues**) with paginated card lists. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1's six fixed categories (incl. Scholarships/Sponsorships) are replaced; athletes are added to search. | M | S.5 |
| FR-DISC-3 | A shared filter panel shall support: sport multi-select, city/state dropdown, age group, **position**, level, facilities, price, and date range (where applicable); sort by relevance / distance / rating; with Apply and Clear. | M | S.4 |
| FR-DISC-4 | The same filter/facet semantics shall apply consistently across all listing types. | M | S.4 |
| FR-DISC-5 | All list views shall support pagination ("Load more"). | M | S.3 |
| FR-DISC-6 | Discovery shall surface an **Explore** view with grouped sections and "See All" per category, plus a **feed preview** and **leaderboard strip** on Home. | M | S.2, AT.1 |
| FR-DISC-7 | Search shall include a **saved/recent searches** store and grouped empty states. | S | S.5 |

## 10. ENQ — Enquiry & Messaging (shared pattern)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-ENQ-1 | Enquiry threads shall store athlete message, provider replies, and timestamps, displayed as a message-thread view. | M | S.18 |
| FR-ENQ-2 | Inbox rows shall distinguish unread/new vs replied states. | M | S.17 |
| FR-ENQ-3 | **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "no separate chat system exists; sponsor Message/Reply reuse enquiry infra" is superseded (D7): a real **conversations + messages** system is introduced (FR-SOC-5); enquiries link to a conversation thread. | S | FR-SOC-5 |
| FR-ENQ-4 | Enquiries may be created against a `program` or `opportunity` subject (in addition to coach/academy) and open a chat thread. | M | D.12 |

## 11. NOTIF — Notifications

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-NOTIF-1 | A notifications center shall list all alerts with tabs (All/People/Opportunities/Events/Mentions), grouped timeline (Today/Yesterday/This Week), unread dots, and Mark all as read. | M | S.16 |
| FR-NOTIF-2 | Reminders shall be generated for saved trials, tournaments, and **opportunity deadlines** as they approach, plus "trial near you". | M | M9.3 |
| FR-NOTIF-3 | Notifications shall be generated for follow, connection request/accepted, message, enquiry, registration decision, verification result, mention, and broadcast. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 notification types are extended. | M | S.16 |
| FR-NOTIF-4 | Users shall be able to toggle notifications in Settings. | M | S.22 |
| FR-NOTIF-5 | The delivery mechanism (push provider, in-app badge) is abstracted behind a `NotificationProvider` interface — vendor undecided. | M | Decision |

## 12. TRUST — Reporting & Moderation (user side)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-TRUST-1 | Users shall be able to **report** any user, post, or listing from its surface via a sheet with reasons (Fake/Scam, Outdated, Inappropriate, Misleading, Spam, Other) and optional comment. **[SUPERSEDED — see Backend-Feature-Delta.md]** reportable morphs extended beyond listings to `user`/`post`. | M | S.26 |
| FR-TRUST-2 | Multiple reports on the same item shall be aggregated for the admin queue (report count shown). | M | AD.7 |
| FR-TRUST-3 | Users shall be able to **block** another user; blocked pairs shall have content hidden both ways and chat disabled; blocks can be listed/unblocked. | M | S.23 |
| FR-TRUST-4 | Users shall see the status of their own reports in a safety centre. | S | S.23 |

## 13. PLAT — Platform / Shared UI

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-PLAT-1 | Settings & Privacy shall include: edit profile, change password, notification toggles, **profile visibility, who can message/connect, blocked users**, language selector (English only at MVP), help center, report a problem, log out, delete account. | M | S.22 |
| FR-PLAT-2 | Help Center shall offer FAQ search, popular topics, and a contact-support form. | M | S.24 |
| FR-PLAT-3 | A persistent bottom navigation bar with **Home / Explore / (+) Create / Community / More** shall appear on primary screens for all roles. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 nav (Home/Search/Saved/Profile, athlete-only) is superseded; all roles share the new shell. | M | S.1 |
| FR-PLAT-4 | Every detail page shall expose Save (♡), an overflow menu (⋮), and a "Report" entry. | M | S.26 |
| FR-PLAT-5 | All listing types shall share a consistent card-list → detail → form pattern. | M | SCREEN_INVENTORY §12 |
| FR-PLAT-6 | Each role shall land on its own **role Home dashboard** (AT.1/CO.2/AC.2/OR.2/SC.2), with a role-aware Create launcher (S.8) and More menu (S.15). | M | SCREEN_INVENTORY §1 |
| FR-PLAT-7 | Profiles shall capture **30 fields per role** (8–9 mandatory), with a per-role completion checklist and deep links. | M | AT.6, SportX_Mandatory_Fields |

---

## 14. GUARD — Guardian Consent & Minors (new)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-GUARD-1 | Any athlete with DOB < 18 shall have a **verified guardian consent** (guardian name, phone, relationship, OTP) before profile activation; the account stays `pending` until verified. | M | A.9 |
| FR-GUARD-2 | Guardian controls shall govern a minor's messaging permission, profile visibility, and leaderboard name mode (full/initials/hidden). | M | AT.10 |
| FR-GUARD-3 | Minors shall be restricted by default: limited profile visibility, chat only with accepted connections the guardian allows, and no precise location shown. | M | MVP_FEATURE_LIST §6 |

## 15. OPP — Opportunities (new; replaces Scholarships/Sponsorships)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-OPP-1 | Opportunities shall be a unified type set: **scholarship, sponsorship, tryout, camp**; browsable by all roles with type/sport/age/deadline filters. | M | D.9 |
| FR-OPP-2 | Providers (Academy/Organizer/Coach/Scout; Athlete P1) shall create/edit/publish/close opportunities; admin may post legacy/`posted_by_admin` schemes. | M | AC.9, SC.12 |
| FR-OPP-3 | Athletes shall apply to an opportunity in-app with a pitch + documents and an auto-attached profile snapshot; duplicate applications blocked. | M | D.10 |
| FR-OPP-4 | Providers shall review applicants and shortlist/decline with a note (P1). | S | AC.9 |
| FR-OPP-5 | Athletes shall see My Opportunities (Applied/Saved/Created) with status. | M | AT.8 |

## 16. PROG — Programs, Facilities & Venues (new)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-PROG-1 | Coaches/academies shall create/edit/manage **training programs** (title, sport, age group, duration, mode, price, schedule, description; Active/Drafts/Past). | M | CO.4, CO.5 |
| FR-PROG-2 | Program detail shall be public (D.11) and support an **enquiry** that opens a chat thread (D.12). | M | D.11, D.12 |
| FR-PROG-3 | Academies shall manage **facilities** (list + Add/Edit + public detail). | M | AC.7, AC.8, D.13 |
| FR-PROG-4 | Organizers shall manage owned **venues** alongside public browse (P1). | S | OR.13 |

## 17. SOC — Social Feed, Network & Chat (new)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-SOC-1 | Users shall create text/photo/video **posts** (hashtags, sport tag, audience) and edit/delete their own. | M | S.9 |
| FR-SOC-2 | Users shall browse a **feed** (For You/Following/Athletes/Coaches/Academies/Events) with chronological + simple relevance. | M | S.1 |
| FR-SOC-3 | Users shall **like**, **comment on**, and **save** posts; counts shown on feed/detail. | M | S.27 |
| FR-SOC-4 | Users shall **follow** (one-way) any profile/entity and manage followers/following tabs. | M | S.3, S.19 |
| FR-SOC-5 | Users shall **connect** (mutual request → accept/decline/cancel/remove); accepted connection unlocks chat. | M | S.19 |
| FR-SOC-6 | Users shall message in **1-to-1 conversations** (text P0; media P1) with accepted connections or within enquiry threads; Chats/Requests tabs, unread badges; no cold DMs. | M | S.17, S.18 |
| FR-SOC-7 | Users shall **report** and **block** from chat/post/profile surfaces; blocks hide content both ways and disable chat. | M | S.23, S.26 |

## 18. LB — Leaderboard (new)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-LB-1 | The platform shall compute athlete points from **verified achievements + profile completion milestones + activity** per sport/season. | M | S.6 |
| FR-LB-2 | Athletes shall view **leaderboards** (sport/location/age filters; podium + ranks 4–10) and a home strip (top 5). | M | S.6, AT.1 |
| FR-LB-3 | Minors shall appear anonymized (first name + initial) unless the guardian opts in. | M | AT.10 |
| FR-LB-4 | Coaches/Academies/Teams/Events leaderboard tabs shall be P1-ready; admin config + season reset (P1). | S | AD.11 |

## 19. VERIF/GP — Verification & Generalized Providers (new)

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-VERIF-1 | Users/providers shall request verification (ID + org proof) and view status; admin approves/rejects with reason; the badge surfaces on profile/cards/search. | M | A.10, AD.4 |
| FR-GP-1 | **Generalized provider profiles** (NGO, doctor, physiotherapist, store, brand, nutritionist, journalist, agent, federation, facility, school/college, media, photographer, psychologist, government body) shall exist as directory profiles (not login roles), discoverable in search, with 30 fields (9 mandatory). | M | SportX_Mandatory_Fields §6 |

---

## Non-Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| NFR-1 | **Platform:** Flutter mobile app (Android + iOS from one codebase); Laravel REST API backend; relational database (see Database-Design — engine choice is an assumption). | M |
| NFR-2 | **Mobile-first UX:** layouts specified at ~375px portrait baseline; bottom-nav pattern for primary flows. | M |
| NFR-3 | **Performance:** directory/list endpoints paginated; card-list scrolling must remain smooth on low-end Android devices (target: 60fps list scrolling; list page load P95 < 2.5s on 4G — target is an assumption). | M |
| NFR-4 | **Scalability:** stateless API (token auth), queue-backed async work (notifications, expiry sweeps), media stored in object storage not the app server/DB. | M |
| NFR-5 | **Security:** password hashing with a modern algorithm, OTP expiry & rate limiting, role-based authorization on every endpoint, admin 2FA, document/media uploads validated & access-controlled. See `Security-and-NonFunctional.md`. | M |
| NFR-6 | **Privacy (India context):** athlete profiles may belong to minors (Under-10 through Under-18). **Decided (v3):** guardian consent is mandatory (<18) before activation, restricted visibility/messaging defaults, and leaderboard anonymization (FR-GUARD-1…3). Closes AS-34. See Security doc. | M |
| NFR-7 | **Auditability:** moderation actions, listing status changes, and override/restore actions on expiry are auditable (who/when/what). | S |
| NFR-8 | **Availability target:** 99.5% monthly for the API during MVP (assumption — no SLA stated anywhere). | S |
| NFR-9 | **Localization shell:** language setting exists, English-only content at MVP (assumption). | C |
| NFR-10 | **Offline:** no offline mode required for MVP (assumption). | C |

---

## Mandatory Fields Reference — **[SUPERSEDED — see Backend-Feature-Delta.md]**

> **Current source of truth:** `sportsx-design-v3/new_design_docs/SportX_Mandatory_Fields.md` (**30 fields per role**, grouped 🔴 Essential/mandatory · 🟠 High · 🟢 Medium) and `docs/Database-Design.md` §4. The v1 PDF-derived tables below are preserved for history only.

**30 fields per role (mandatory counts):** Athlete 8 · Coach 8 · Academy 9 · Talent Scout 7 · Organizer 7 · Generalized (all other categories) 9. Common mandatory fields across roles: Name, Photo/Logo, Primary Sport(s), City/State, Short Bio/Description, and a role-specific type/level; Contact Information is additionally mandatory for generalized and non-athlete provider profiles.

### Superseded v1 tables (PDF-derived)

### Athlete

| Field | Status | DB Column |
|---|---|---|
| Full Name | ■ Mandatory | `athlete_profiles.full_name` |
| Profile Photo | ■ Mandatory | `athlete_profiles.photo_media_id` |
| Sport | ■ Mandatory | `athlete_sports.sport_id` |
| City | ■ Mandatory | `athlete_profiles.city_id` |
| Date of Birth | ■ Mandatory | `athlete_profiles.date_of_birth` |
| Gender | ■ Mandatory | `athlete_profiles.gender` |
| Contact Number | Optional | `users.phone` |
| Email | Optional | `users.email` |
| Academy | Optional | `athlete_profiles.academy_id` |
| Coach | Optional | `athlete_profiles.coach_id` |
| Position | Optional | `athlete_profiles.position` |
| Experience | Optional | `athlete_profiles.experience` |
| Achievements | Optional | `achievements.text` |
| Videos | Optional | `media_items` (media_type=video) |
| Certificates | Optional | `media_items` (media_type=document) |
| Ranking | System | — |
| Verification | System | — |

### Coach

| Field | Status | DB Column |
|---|---|---|
| Full Name | ■ Mandatory | `coach_profiles.full_name` |
| Sport | ■ Mandatory | `coach_profiles.sport_id` |
| City | ■ Mandatory | `coach_profiles.city_id` |
| Contact Number | ■ Mandatory | `coach_profiles.contact_number` |
| Experience | ■ Mandatory | `coach_profiles.experience` |
| Profile Photo | Optional | `coach_profiles.photo_media_id` |
| Qualification | Optional | `coach_profiles.qualification` |
| Certifications | Optional | `coach_profiles.certifications` |
| Academy | Optional | `coach_profiles.academy_id` |
| Languages | Optional | `coach_profiles.languages` |
| Email | Optional | `coach_profiles.email` |
| Personal Coaching | Optional | `coach_profiles.personal_coaching` |
| Fees | Optional | `coach_profiles.fee_structure` |
| Achievements | Optional | — (not modeled separately; future) |
| Rating | System | — |
| Verification | System | — |

### Academy

| Field | Status | DB Column |
|---|---|---|
| Academy Name | ■ Mandatory | `academies.name` |
| Sport(s) Offered | ■ Mandatory | `academy_sports` |
| Address | ■ Mandatory | `academies.address` |
| City | ■ Mandatory | `academies.city_id` |
| Contact Number | ■ Mandatory | `academies.contact_number` |
| Google Maps Location | ■ Mandatory | `academies.google_maps_url` |
| Description | ■ Mandatory | `academies.description` |
| Logo | Optional | `academies.logo_media_id` |
| Cover Photo | Optional | `academies.cover_media_id` |
| Email | Optional | `academies.email` |
| Website/Social Media | Optional | `academies.website` |
| Head Coach | Optional | `academies.head_coach_id` |
| Year Established | Optional | `academies.year_established` |
| Age Groups | Optional | `academies.age_groups` |
| Training Timings | Optional | `academies.timings` |
| Fees | Optional | `academies.fee_range` |
| Facilities | Optional | `academies.facilities` |
| Achievements | Optional | `academies.achievements` |
| Photos & Videos | Optional | `media_items` morphMany |
| Verification Badge | System | `academies.verification_badge` |

### Tournament

| Field | Status | DB Column |
|---|---|---|
| Tournament Name | ■ Mandatory | `tournaments.name` |
| Sport | ■ Mandatory | `tournaments.sport_id` |
| Organizer | ■ Mandatory | `tournaments.organizer_name` |
| Tournament Dates | ■ Mandatory | `tournaments.start_date`, `tournaments.end_date` |
| Registration Deadline | ■ Mandatory | `tournaments.registration_deadline` |
| Venue | ■ Mandatory | `tournaments.venue` |
| Google Maps | ■ Mandatory | `tournaments.google_maps_url` |
| Entry Fee | ■ Mandatory | `tournaments.entry_fee` |
| Contact Number | ■ Mandatory | `tournaments.contact_number` |
| Registration Link | ■ Mandatory | `tournaments.registration_link` |
| Banner | Optional | `tournaments.banner_media_id` |
| Age Category | Optional | `tournament_categories.age_group_id` |
| Gender | Optional | `tournaments.gender` |
| Prize Pool | Optional | `tournaments.prize_pool` |
| Rules | Optional | `tournaments.rules` |
| Fixtures | Optional | — |
| Results | System | `tournament_results` |
| Photos | Optional | `media_items` |
| Status | System | — |
| Verification | System | — |

### Trial

| Field | Status | DB Column |
|---|---|---|
| Trial Name | ■ Mandatory | `trials.name` |
| Organization | ■ Mandatory | `trials.organization_name` |
| Sport | ■ Mandatory | `trials.sport_id` |
| Date | ■ Mandatory | `trials.event_datetime` |
| Venue | ■ Mandatory | `trials.venue` |
| Google Maps | ■ Mandatory | `trials.google_maps_url` |
| Contact Number | ■ Mandatory | `trials.contact_number` |
| Registration Deadline | ■ Mandatory | `trials.registration_deadline` |
| Eligibility | Optional | `trials.eligibility` |
| Required Documents | Optional | `trials.required_documents` |
| Vacancies | Optional | `trials.vacancies` |
| Benefits | Optional | `trials.benefits` |
| Registration Fee | Optional | `trials.entry_fee` |
| Status | System | `trials.status` |
| Verification | System | — |

### Sponsor / Scholarship

| Field | Status | DB Column (sponsorships / scholarships) |
|---|---|---|
| Organization Name | ■ Mandatory | `organization_name` |
| Sponsorship/Scholarship Name | ■ Mandatory | `sponsorships.title` / `scholarships.name` |
| Sport | ■ Mandatory | `sport_id` |
| Eligibility | ■ Mandatory | `eligibility_criteria` / `eligibility` |
| Last Date | ■ Mandatory | `deadline` |
| Application Link | ■ Mandatory | `application_link` |
| Contact Email/Number | ■ Mandatory | `contact_email`, `contact_phone` |
| Logo | Optional | `logo_media_id` |
| Benefits | Optional | `benefits_offered` / `benefits` |
| Amount | Optional | `amount` |
| Documents Required | Optional | `documents_required` |
| Description | Optional | `description` |
| Verification | System | — |

### Sports Venue (new entity from PDF)

| Field | Status | DB Column |
|---|---|---|
| Venue Name | ■ Mandatory | `sports_venues.name` |
| Sport | ■ Mandatory | `sports_venues.sport_id` |
| Address | ■ Mandatory | `sports_venues.address` |
| Google Maps | ■ Mandatory | `sports_venues.google_maps_url` |
| Contact Number | ■ Mandatory | `sports_venues.contact_number` |
| Photos | Optional | `sports_venues.photos` (json) |
| Booking Available | Optional | `sports_venues.booking_available` |
| Pricing | Optional | `sports_venues.pricing` |
| Facilities | Optional | `sports_venues.facilities` (json) |
| Working Hours | Optional | `sports_venues.working_hours` |
| Rating | System | — |
| Verification | System | — |

---

## Traceability: MVP Feature → FR(s)

| MVP Feature (Overview) | FR IDs |
|---|---|
| Sign Up / Login | FR-AUTH-1…5, role onboarding FR-AUTH-6…10 (FR-AUTH-10 superseded → FR-GP-1) |
| Digital Profile | FR-ATH-1, FR-ATH-2, FR-PLAT-7 |
| Academy Directory + Search & Filter | FR-ATH-4, FR-DISC-1…4 |
| Coach Directory + Search & Filter | FR-ATH-5, FR-DISC-1…4 |
| Book/Enquire with Coaches | FR-ATH-6, FR-ENQ-1…4 |
| Trial Listings + Search & Filter | FR-ATH-7, FR-DISC-1…4 |
| Trial Registration | FR-ATH-8 |
| Tournament Calendar + Registration | FR-ATH-9, FR-ATH-10 |
| Opportunity Feed (scholarship/sponsorship/tryout/camp) | FR-ATH-11, FR-OPP-1…5 (FR-ATH-17 superseded) |
| Apply/Pitch to Opportunities | FR-ATH-13, FR-OPP-3 |
| Universal Search | FR-DISC-1, FR-DISC-2 |
| Global Filters | FR-DISC-3, FR-DISC-4 |
| Deadline & Date Reminders | FR-ATH-16, FR-NOTIF-2 |
| Report a Listing / user / post; Block | FR-TRUST-1…4 |
| Social feed / posts / likes / comments | FR-SOC-1…3 |
| Follow / Connect / 1-to-1 chat | FR-SOC-4…7 |
| Leaderboard | FR-LB-1…4 |
| Programs / Facilities / Venues | FR-PROG-1…4 |
| Verification & Generalized Providers | FR-VERIF-1, FR-GP-1 |
| Guardian consent & minors | FR-GUARD-1…3 |
| Coach: Own Profile / Programs / Enquiry Inbox / Browse Like Any User | FR-COACH-1…9 |
| Academy: Listing / Facilities / Programs / Trial Posting / Registrants / Enquiries | FR-ACAD-1…11 |
| Organizer: Events / Registrations / Export / Results / Opportunities | FR-ORG-1…14 |
| Talent Scout: Discover / Shortlist / Observations / Reports / Contact | FR-TS-1…13 |
| ~~Sponsor: Listing / Discovery / Applications / Shortlisting~~ | **[SUPERSEDED — see Backend-Feature-Delta.md]** FR-SPON-1…8 → FR-OPP-2/3, FR-TS-* |
| Admin: Content CRUD / Moderation / Expiry / Categories / Users / Verification | FR-ADMIN-1…15 |
