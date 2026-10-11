# Product Requirements Document (PRD) — SportX India

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

| | |
|---|---|
| **Document** | Product Requirements Document |
| **Project** | SportX India |
| **Version** | 2.0 (idea-stage, SRS-level; synced to v3 design) |
| **Sources of truth** | `SportX-India-MVP-Overview.md`, `SportX-India-Screen-Inventory.md`, `SportX-India-Wireframes.md` |
| **Status** | Draft for review |

---

## 1. Vision

SportX India is a **discovery and connection platform for India's sports ecosystem**.

It brings together **athletes and parents**, **coaches**, **academies**, **trial/tournament organizers**, and **talent scouts** (now a first-class role) in one place — so athletes can find opportunities (academies, coaches, trials, tournaments, scholarships, sponsorships, tryouts, camps, training programs) and the supply side (coaches, academies, organizers, scouts, plus **generalized provider** directory profiles such as NGOs, doctors, stores, nutritionists, agents, federations) can find, engage, and manage athletes.

> **[SUPERSEDED — see Backend-Feature-Delta.md]** The v1 vision listed **sponsors/brands** as a full role here. The `sponsor` role is **removed** (decision D2); sponsorship is now an `opportunities.type` posted by Academy/Organizer/Coach/Scout. Brands/NGOs/etc. appear as **generalized provider directory profiles**, not login roles.

An **Admin** team operates behind the scenes to keep the data clean, moderate listings, run the verification queue, manage users, and manage master categories (sports, cities, age groups, positions).

> The platform has two core jobs:
> 1. **Discovery** — let athletes/parents search and filter academies, coaches, trials, tournaments, opportunities (scholarships/sponsorships/tryouts/camps), programs, facilities, and athletes.
> 2. **Connection & Management** — let coaches, academies, organizers, and scouts publish listings, manage enquiries/registrations, post opportunities, and find/connect with athletes (feed, follow/connect, 1-to-1 chat).

---

## 2. Problem Statement

India's sports ecosystem is fragmented:

- **Athletes / parents** have no single trustworthy place to discover academies, coaches, upcoming trials, tournaments, scholarships, or sponsorship opportunities. Discovery happens through word of mouth, local WhatsApp groups, or scattered social media posts.
- **Coaches and academies** have no structured channel to market themselves or manage incoming interest beyond phone calls and messages.
- **Organizers** of trials and tournaments lack a distribution channel to reach athletes, and track registrations through ad-hoc spreadsheets and forms.
- **Providers and brands** — academies, organizers, coaches, scouts, and generalized directories (NGOs, stores, doctors) — looking to back or recruit promising athletes have no searchable pool of verified athlete profiles or a single place to post scholarships, sponsorships, tryouts, and camps.
- **Talent scouts** looking for promising athletes have no structured way to discover, shortlist, observe, and connect with talent across sports and regions.

> **[SUPERSEDED — see Backend-Feature-Delta.md]** The v1 line "Sponsors/brands … no searchable pool" is replaced by the provider/brand line above (sponsor role removed, D2).
- **Fake, stale, or out-of-date listings** erode trust in every one of these interactions.

SportX India solves this by being the single, moderated, searchable marketplace for the Indian sports ecosystem.

---

## 3. Goals & Objectives

### 3.1 Product Goals

| # | Goal |
|---|---|
| G1 | A single, universal search surface across academies, coaches, trials, tournaments, and opportunities (scholarships/sponsorships/tryouts/camps) — plus athletes |
| G2 | Every listing type (academy, coach, trial, tournament, opportunity, program, facility, sports venue) has a consistent browse → filter → detail → act flow |
| G3 | Every supply-side role (coach, academy, organizer, scout) can self-serve their listing creation and management; generalized providers are directory-discoverable |
| G4 | Athletes can register/apply/enquire directly in-app and track all their activity in one place (registrations, opportunities, applications) |
| G5 | The platform is moderated — users can report users/posts/listings and block, admins can act on reports/verifications, and time-boxed listings auto-expire |
| G6 | Reminders ensure athletes never miss a saved trial date, tournament date, or opportunity deadline; a leaderboard surfaces verified achievement |

### 3.2 Non-Goals (out of scope for MVP)

> **[SUPERSEDED — see Backend-Feature-Delta.md]** Several v1 "non-goals" are now **in scope** in the new design (v3): ratings & reviews (P1), in-app 1-to-1 chat (P0), and event analytics (P1). The map view stays **parked (P2)**. The table below is preserved for history; the "Reason / Source" column records the new status.

The following were **explicitly excluded** from the v1 MVP, either flagged in the source gap-analysis or decided during documentation authoring:

| Item | Reason / Source |
|---|---|
| In-app payments / payment gateway integration | **Still excluded** (parked, P2). Entry fees shown as informational "payment note" only; tournament payment-status is a manual flag. See `Glossary-and-Assumptions.md` |
| Ratings & reviews | **Now P1** (Superseded — see `Backend-Feature-Delta.md` BE-P1.1); gated to verified interactions |
| In-app chat / messaging threads (beyond enquiry reply flow) | **Now P0** (Superseded — see `Backend-Feature-Delta.md` M7/BE-M7.4): conversations + messages introduced alongside enquiry threads; accepted-connections + enquiry threads only, no cold DMs |
| Listing analytics dashboards | **Now P1** event analytics (Superseded — see BE-P1.4) |
| Native maps integration beyond a "map preview" on detail pages | **Still parked (P2)** — map view is explicitly out |
| Groups, polls, live/webinar/streaming, boosted/promoted placement, multi-role accounts, teams, staff recruiting | **Parked (P2)** per `Backend-Feature-Delta.md` §10 |

---

## 4. Target Users & Personas

Six roles are defined in the MVP (v3): **athlete, coach, academy, organizer, scout, admin**. Personas below are consistent with the sample data used throughout the wireframes (e.g. "Aryan Patel — Cricket U-14 — Ahmedabad"). **129 screens** span these 6 roles (see `SCREEN_INVENTORY.md`).

### 4.1 Athlete / Parent (primary consumer)

> **Persona: "Aryan", 14-year-old cricketer in Ahmedabad (or his parent operating the account on his behalf)**

- Wants to find a good cricket academy nearby, know about upcoming U-14 trials before they close, and apply for scholarships he's eligible for.
- Frustrated by missing trial dates and by fake/outdated listings.
- Uses the app to: build a digital profile with achievements and media, search across all opportunity types, register for trials/tournaments, pitch to sponsors, and get deadline reminders.

### 4.2 Coach

> **Persona: "Coach Rahul Mehta", cricket coach, 8 years experience, Ahmedabad**

- Lists coaching services (certifications such as "BCCI Level 2", fee per session, location).
- Receives and replies to enquiries from athletes/parents in an inbox.
- Also uses the app exactly like an athlete/parent (Browse Like Any User).

### 4.3 Academy

> **Persona: "Elite Cricket Academy", Ahmedabad**

- Maintains a public listing: facilities (turf, nets, gym), fee range, age groups, timings, coaches, photos.
- Posts trials under the academy name, manages registrants per trial (documents submitted, verification status), replies to enquiries.

### 4.4 Organizer (Trial / Tournament)

> **Persona: "SportsFed Gujarat", a sports federation**

- Posts standalone trials and tournaments (e.g. "U-16 State Cricket Cup") with format, dates, venue, entry fee, prize pool, categories.
- Tracks registrations with payment-status flags and capacity per category, manages spots and waitlists.
- Publishes results/brackets after events conclude.

### 4.5 ~~Sponsor / Brand~~ → Talent Scout (first-class) + Generalized Provider

> **[SUPERSEDED — see Backend-Feature-Delta.md]** The v1 PRD defined **"Sponsor / Brand"** as a full role (persona "ProGear Sports"). The `sponsor` role is **removed** (D2). Sponsorship is now an `opportunities.type` posted by Academy/Organizer/Coach/Scout. Two replacements:

- **Talent Scout** (§4.6) is now a **first-class role** — scouts post scouting opportunities, discover/shortlist/observe athletes, and contact athletes/parents.
- **Generalized Provider** — NGOs, doctors/physiotherapists, sports stores, brands, nutritionists, journalists, agents, federations, facilities, schools/colleges, sports media, photographers, psychologists, and government bodies appear as **directory profiles** (`generalized_profiles`), not login roles; they are discoverable in search and can be created via generic provider onboarding or admin.

### 4.6 Talent Scout

> **Persona: "Priya Sharma", talent scout for a sports academy, 5 years experience, Mumbai**

- Searches for promising athletes across sports, age groups, locations, and skill levels.
- Reviews athlete profiles including sports history, achievements, and media.
- Shortlists promising athletes with status/tags/private notes, adds observations, and sends contact requests through the platform (guardian-routed for minors).

### 4.7 Admin (Internal / Platform team)

- Not a marketplace end-user. Secured behind a dedicated admin login with 2FA.
- Runs the **verification queue** and **user management** (suspend/ban) — both **P0** in v3, not deferred.
- Seeds and corrects data across all categories, reviews flagged users/posts/listings, configures auto-expiry rules, manages master lists (sports, cities, age groups, positions).

---

## 5. Scope

### 5.1 In Scope (MVP)

Aligned with the new design (v3) `MVP_FEATURE_LIST.md` (P0) and `SCREEN_INVENTORY.md` (**129 screens across 6 roles** — Athlete/Parent, Coach, Academy, Organizer, Talent Scout, Admin). `sponsor` is **not** a role.

- **Roles (6):** athlete, coach, academy, organizer, scout, admin. One account = one role (multi-role parked, P2). Sponsorship is an **opportunity type**, not a role.
- **Auth (P0):** Sign up / login via **phone or email + 6-digit OTP** (resend timer); password login kept alongside; role onboarding per role; **guardian consent for minors (<18)** gating profile activation; forgot-password via OTP (P1); Google sign-in shown but deferred (decision D9). **[SUPERSEDED — see Backend-Feature-Delta.md]** The v1 decision "email-OTP first, phone deferred" is superseded: OTP now serves **both** phone and email channels at MVP (D1/D5), making SMS-vendor selection (AS-03) blocking.
- **Profiles (P0):** **30 fields per role** (8–9 mandatory; see `SportX_Mandatory_Fields.md`); per-sport role/level/experience/primary; rich typed achievements + certificates; media gallery; privacy controls (visibility, who can message/connect); profile completion checklist.
- **Athlete/Parent (P0):** Digital profile, explore/discovery (athletes, coaches, academies, training), unified **opportunities** (scholarship/sponsorship/tryout/camp) with in-app apply + pitch and status tracking, event/trial registration with status notifications, **leaderboard**, saved/bookmarks, report/block, my activity/registrations/opportunities.
- **Coach (P0):** Own profile, **training programs** (create/manage), enquiry/chat inbox, browse like any user.
- **Academy (P0):** Own listing, **facilities CRUD**, training programs, trials/events (reuse organizer flow), registrant management (approve/reject/export), opportunities, enquiry inbox; our-athletes (P1).
- **Organizer (P0):** Trial/tournament/**camp** listing management, registration management (capacity/waitlist, manual payment-status flag), **registrant export CSV**, results publishing; event schedule/gallery/analytics/announcements (P1).
- **Talent Scout (first-class, P0):** Scout onboarding + profile, discover talents with advanced filters, **shortlist with status/tags/private notes**, **observations**, contact athlete/parent (guardian-routed for minors), scouting opportunities hub; talent reports + compare (P1).
- **Generalized Provider (directory, P0):** NGOs, doctors, stores, brands, nutritionists, agents, federations, facilities, schools, media etc. exist as `generalized_profiles` (directory-only, not login roles), discoverable in search.
- **Social (P0):** lightweight **feed + posts + likes + comments**; **follow (one-way)** / **connect (mutual)**; **1-to-1 chat** (accepted connections + enquiry threads only; no cold DMs); share/deep links (P1).
- **Trust & Safety (P0):** report users/posts/listings, **block users**, verification request + blue-check **admin queue**, moderation actions (remove/warn/suspend) with outcome notifications.
- **Admin (P0 slice):** dedicated 2FA portal, dashboard, **user management (suspend/ban)**, verification queue, content CRUD (incl. opportunities/programs/facilities/posts), moderation, master data (incl. **positions**), expiry rules; leaderboard config + broadcasts (P1). **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "full documentation, build scheduled later" is superseded: the verification queue (AD.4) and user management (AD.3) are **P0**.
- **Sponsor/Brand:** **[SUPERSEDED — see Backend-Feature-Delta.md]** Removed as a role (D2). Sponsorship posting is now an opportunity type available to Academy/Organizer/Coach/Scout (athlete P1).
- **Shared:** Universal search across categories (incl. **athletes**), shared filter panel (sport, city/state, age group, position, level, facilities, price, date; sort relevance/distance/rating), notifications center, settings (notification prefs, visibility/messaging prefs, language, logout, delete account), help/support (FAQ + contact form).

### 5.2 Out of Scope (MVP)

See §3.2.

---

## 6. Success Metrics

Success metrics are **not stated in the source documents**. The following are proposed, directional metrics for the MVP stage and are flagged as **assumptions to be validated** with stakeholders:

| # | Metric | What it indicates |
|---|---|---|
| M1 | Sign-ups by role (athletes, coaches, academies, organizers, scouts) | Marketplace health on both sides |
| M2 | Number of active (published, non-expired) listings per category | Supply depth |
| M3 | Searches per active user; filter usage rate | Discovery engagement |
| M4 | Trial/tournament registrations completed per week | Core transactional activation |
| M5 | Enquiries sent → replied-to rate (coach & academy inboxes) | Connection quality |
| M6 | Opportunity applications submitted; shortlist rate | Provider-side value |
| M7 | Listings reported → resolved within SLA (moderation turnaround) | Trust & safety |
| M8 | Auto-expired listings per week (hygiene working as intended) | Data freshness |
| M9 | Reminder opt-in rate on saved items; notification open rate | Retention loops |
| M10 | 7-day / 30-day retention of athlete accounts | Product stickiness |
| M11 | Posts / likes / comments per active user; follows & connections made | Social engagement (new P0) |
| M12 | Verification requests → approved; % verified profiles; leaderboard participation | Trust & credibility (new P0) |

---

## 7. Assumptions & Constraints

### 7.1 Key Assumptions (rolled up in `Glossary-and-Assumptions.md`)

| # | Assumption | Rationale |
|---|---|---|
| A1 | **OTP signup/login supports phone OR email** (6-digit code); password login kept alongside. SMS-vendor selection (AS-03) is blocking for the phone channel. **[SUPERSEDED — see Backend-Feature-Delta.md]** The v1 "email-OTP first; phone deferred" decision is superseded (D1/D5). | Stakeholder decision (v3) |
| A1b | **Guardian consent is mandatory for minors (<18)**: guardian name/phone + consent OTP before profile activation; restricted defaults; leaderboard anonymization. Closes AS-34. | Stakeholder decision (v3, D4) |
| A2 | **No in-app payments in this MVP** — entry fees and payment-related fields are informational; where a fee applies, the UI carries a "payment note" only and organizer registration lists track a payment status flag manually. Payments are **parked (P2)**. | Confirmed by stakeholder decision |
| A3 | Push notification provider and SMS/OTP provider are **undecided placeholders**; the docs define abstract interfaces (e.g. `NotificationProvider`, `OtpProvider`) rather than committing to a vendor. **OTP SMS vendor is now blocking** (phone channel is P0). | Confirmed by stakeholder decision |
| A4 | Admin verification queue (AD.4) and user management (AD.3) are **P0** — not deferred. Remaining admin console pages can follow. **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 "admin built in a later phase" is superseded. | Stakeholder decision (v3, D6) |
| A5 | `SportX_India_Mandatory_Fields_MVP.pdf` could not be parsed in this environment; all field-level decisions are inferred from the three markdown sources and marked as assumptions where ambiguous | Environment limitation |
| A6 | The product launches in **India**, with phone numbers in `+91` format and pricing in ₹ (per wireframes) | Implied by S3 and all fee fields |
| A7 | Multi-language support exists as a settings option (S11 "Language") but MVP ships **English only** | Language switcher shown, no localization content specified |

### 7.2 Constraints

| # | Constraint | Source |
|---|---|---|
| C1 | **Flutter mobile app + Laravel backend** — fixed technology stack | Stated by stakeholder |
| C2 | Mobile-first UX, ~375px portrait baseline | Wireframes header |
| C3 | Data model must be consistent with the reusable screen templates (directory list → detail → form, inbox list → detail → action) | Screen Inventory "Notes for Build Planning" |
| C4 | Time-boxed content (trials, tournaments, opportunities with deadlines) must support automatic expiry, per admin-configurable rules. Programs/facilities do not expire. | AD8/AD9, BE-M4.4 |
| C5 | Trust & safety (user reporting, admin moderation actions) must exist at MVP level, even though the admin console build is phased | S10, AD6/AD7 |

---

## 8. Release Strategy (summary)

The build is broken into demo-able phases in `Phased-Roadmap.md`. The v3 sequence follows `Backend-Feature-Delta.md` §9:

1. **Phase 1 — Roles & Trust:** role model (drop `sponsor`, add `scout`), OTP stack (phone + email), role onboarding (incl. scout), **guardian consent for minors**, verification request + admin queue + blue-check badge.
2. **Phase 2 — Profiles & Discovery:** 30-field profiles per role, achievements/media, universal search (incl. athletes), filters/sort, saved items, explore/discovery, report.
3. **Phase 3 — Opportunities & Programs:** unified opportunities (scholarship/sponsorship/tryout/camp) + in-app applications, programs, facilities, enquiries→chat threads.
4. **Phase 4 — Social, Network & Leaderboard:** posts/feed/likes/comments, follow/connect, 1-to-1 chat, blocks, leaderboard points engine.
5. **Phase 5 — Events & Supply-side Management:** event/trial/camp create flow, registrations + decision notifications + CSV export, coach/academy/organizer management, admin P0 (users, verification, content types, moderation).
6. **Phase 6 — Polish & Scale (incl. P1 wave):** reviews, event schedule/gallery/analytics, announcements, scout reports + compare, admin broadcasts, recommendations, settings/language shell, performance & hardening.

*(Decisions applied: no payment phase — payments parked; sponsor role removed, so no sponsor phase.)*

---

## 9. Cross-References

| Document | Relationship to this PRD |
|---|---|
| `Functional-Requirements.md` | Decomposes §5 scope into numbered, prioritized requirements |
| `Use-Cases.md` | Actor/interaction model for the personas in §4 |
| `ER-Diagram.md`, `Database-Design.md` | Data model supporting §5 features |
| `API-Specification.md` | Contract for every feature in §5 |
| `Phased-Roadmap.md` | Delivery slicing of §8 |
| `Glossary-and-Assumptions.md` | Authoritative list of assumptions referenced here |
