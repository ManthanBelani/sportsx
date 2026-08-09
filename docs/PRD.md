# Product Requirements Document (PRD) — SportX India

| | |
|---|---|
| **Document** | Product Requirements Document |
| **Project** | SportX India |
| **Version** | 1.0 (idea-stage, SRS-level) |
| **Sources of truth** | `SportX-India-MVP-Overview.md`, `SportX-India-Screen-Inventory.md`, `SportX-India-Wireframes.md` |
| **Status** | Draft for review |

---

## 1. Vision

SportX India is a **discovery and connection platform for India's sports ecosystem**.

It brings together **athletes and parents**, **coaches**, **academies**, **trial/tournament organizers**, and **sponsors/brands** in one place — so athletes can find opportunities (academies, coaches, trials, tournaments, scholarships, sponsorships) and the supply side (coaches, academies, organizers, sponsors) can find, engage, and manage athletes.

An **Admin** team operates behind the scenes to keep the data clean, moderate listings, and manage master categories (sports, cities, age groups).

> The platform has two core jobs:
> 1. **Discovery** — let athletes/parents search and filter academies, coaches, trials, tournaments, scholarships, and sponsorships.
> 2. **Connection & Management** — let coaches, academies, organizers, and sponsors publish listings, manage enquiries/registrations, and find athletes.

---

## 2. Problem Statement

India's sports ecosystem is fragmented:

- **Athletes / parents** have no single trustworthy place to discover academies, coaches, upcoming trials, tournaments, scholarships, or sponsorship opportunities. Discovery happens through word of mouth, local WhatsApp groups, or scattered social media posts.
- **Coaches and academies** have no structured channel to market themselves or manage incoming interest beyond phone calls and messages.
- **Organizers** of trials and tournaments lack a distribution channel to reach athletes, and track registrations through ad-hoc spreadsheets and forms.
- **Sponsors/brands** looking to back promising athletes have no searchable pool of verified athlete profiles.
- **Fake, stale, or out-of-date listings** erode trust in every one of these interactions.

SportX India solves this by being the single, moderated, searchable marketplace for the Indian sports ecosystem.

---

## 3. Goals & Objectives

### 3.1 Product Goals

| # | Goal |
|---|---|
| G1 | A single, universal search surface across academies, coaches, trials, tournaments, scholarships, and sponsorships |
| G2 | Every listing type (academy, coach, trial, tournament, scholarship, sponsorship, sports venue) has a consistent browse → filter → detail → act flow |
| G3 | Every supply-side role (coach, academy, organizer, sponsor) can self-serve their listing creation and management |
| G4 | Athletes can register/apply/enquire directly in-app and track all their activity in one place |
| G5 | The platform is moderated — users can report listings, admins can act on reports, and time-boxed listings auto-expire |
| G6 | Reminders ensure athletes never miss a saved trial date, tournament date, or scholarship deadline |

### 3.2 Non-Goals (out of scope for MVP)

The following are **explicitly excluded** from the MVP. They were either flagged in the source gap-analysis or decided during documentation authoring:

| Item | Reason / Source |
|---|---|
| In-app payments / payment gateway integration | **Excluded by decision** (entry fees shown as informational "payment note" only). See `Glossary-and-Assumptions.md` |
| Ratings & reviews | Flagged in Screen Inventory as "not yet covered" — not in original MVP feature list |
| In-app chat / messaging threads (beyond enquiry reply flow) | Flagged in Screen Inventory as "not yet covered". The enquiry inbox/reply (T4/T4b) is in scope; a full chat system is not |
| Listing analytics dashboards | Flagged in Screen Inventory as "not yet covered" |
| Native maps integration beyond a "map preview" on detail pages | Map preview shown in wireframes (T2), full interactive maps not specified |

---

## 4. Target Users & Personas

Six roles are defined in the MVP Overview. Personas below are consistent with the sample data used throughout the wireframes (e.g. "Aryan Patel — Cricket U-14 — Ahmedabad").

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

### 4.5 Sponsor / Brand

> **Persona: "ProGear Sports", a sportswear brand**

- Posts sponsorship opportunities (e.g. "U-16 Cricket Kit — free kit + stipend/month").
- Discovers athletes via filtered search (sport, age, city, level, achievements).
- Reviews incoming applications/pitches, shortlists candidates with notes.

### 4.6 Admin (Internal / Platform team)

- Not a marketplace end-user. Secured behind a dedicated admin login with 2FA.
- Seeds and corrects data across all categories, reviews flagged listings, configures auto-expiry rules, manages master lists (sports, cities, age groups).

---

## 5. Scope

### 5.1 In Scope (MVP)

Mapped one-to-one from the MVP Overview feature lists:

- **Auth:** Sign up / login via phone or email, OTP/email verification, onboarding per role, Google social sign-in (shown on S3), password or OTP login toggle (S5).
  - **By decision:** Email is verified via OTP first; phone verification is a later addition. (See Assumptions.)
- **Athlete/Parent:** Digital profile (info, sports, achievements, media gallery), academy directory, coach directory, trial listings, tournament calendar (calendar + list), scholarship feed, sponsorship opportunities, sports venue directory (new from PDF), universal search, global filters, deadline/date reminders, report a listing, saved/bookmarked items, my activity hub.
- **Coach:** Own profile creation, enquiry inbox + reply, browse like any user.
- **Academy:** Own listing creation, trial posting (create/edit/publish/close), registrant management (incl. document viewing and verify/reject actions), enquiry inbox.
- **Organizer:** Trial listing management, tournament listing management, registration management (incl. capacity/spot management, waitlist toggle, payment-status flag), results publishing (bracket/placements + public results view).
- **Sponsor/Brand:** Sponsorship posting, athlete discovery, applications inbox (accept/reject/shortlist/reply), shortlist with notes.
- **Admin:** Content CRUD across all six content categories, listing moderation queue + actions (approve/edit/remove/warn), content expiry rules configuration + expiry monitor with override/restore, category management (sports/cities/age groups), admin dashboard counters. **Full documentation, build scheduled in a later phase (by decision).**
- **Shared:** Universal search results across categories, shared filter panel (sport, city/state, age group, price range, date range), notifications center, settings (notification prefs, language, logout, delete account), help/support (FAQ + contact form).

### 5.2 Out of Scope (MVP)

See §3.2.

---

## 6. Success Metrics

Success metrics are **not stated in the source documents**. The following are proposed, directional metrics for the MVP stage and are flagged as **assumptions to be validated** with stakeholders:

| # | Metric | What it indicates |
|---|---|---|
| M1 | Sign-ups by role (athletes, coaches, academies, organizers, sponsors) | Marketplace health on both sides |
| M2 | Number of active (published, non-expired) listings per category | Supply depth |
| M3 | Searches per active user; filter usage rate | Discovery engagement |
| M4 | Trial/tournament registrations completed per week | Core transactional activation |
| M5 | Enquiries sent → replied-to rate (coach & academy inboxes) | Connection quality |
| M6 | Sponsorship applications submitted; shortlist rate | Sponsor-side value |
| M7 | Listings reported → resolved within SLA (moderation turnaround) | Trust & safety |
| M8 | Auto-expired listings per week (hygiene working as intended) | Data freshness |
| M9 | Reminder opt-in rate on saved items; notification open rate | Retention loops |
| M10 | 7-day / 30-day retention of athlete accounts | Product stickiness |

---

## 7. Assumptions & Constraints

### 7.1 Key Assumptions (rolled up in `Glossary-and-Assumptions.md`)

| # | Assumption | Rationale |
|---|---|---|
| A1 | **Email is the primary verified channel (email-OTP first); phone verification comes later** | Confirmed by stakeholder decision |
| A2 | **No in-app payments in this MVP** — entry fees and payment-related fields are informational; where a fee applies, the UI carries a "payment note" only (T3) and organizer registration lists track a payment status flag manually (O7) | Confirmed by stakeholder decision |
| A3 | Push notification provider and SMS/OTP provider are **undecided placeholders**; the docs define abstract interfaces (e.g. `NotificationProvider`, `OtpProvider`) rather than committing to a vendor | Confirmed by stakeholder decision |
| A4 | Admin (AD1–AD12) is **fully documented** but its **build is scheduled in a later phase**; early data seeding happens directly via database/admin tooling in the interim | Confirmed by stakeholder decision |
| A5 | `SportX_India_Mandatory_Fields_MVP.pdf` could not be parsed in this environment; all field-level decisions are inferred from the three markdown sources and marked as assumptions where ambiguous | Environment limitation |
| A6 | The product launches in **India**, with phone numbers in `+91` format and pricing in ₹ (per wireframes) | Implied by S3 and all fee fields |
| A7 | Multi-language support exists as a settings option (S11 "Language") but MVP ships **English only** | Language switcher shown, no localization content specified |

### 7.2 Constraints

| # | Constraint | Source |
|---|---|---|
| C1 | **Flutter mobile app + Laravel backend** — fixed technology stack | Stated by stakeholder |
| C2 | Mobile-first UX, ~375px portrait baseline | Wireframes header |
| C3 | Data model must be consistent with the reusable screen templates (directory list → detail → form, inbox list → detail → action) | Screen Inventory "Notes for Build Planning" |
| C4 | Time-boxed content (trials, tournaments, sponsorships, scholarships with deadlines) must support automatic expiry, per admin-configurable rules | AD8/AD9 |
| C5 | Trust & safety (user reporting, admin moderation actions) must exist at MVP level, even though the admin console build is phased | S10, AD6/AD7 |

---

## 8. Release Strategy (summary)

The build is broken into demo-able phases in `Phased-Roadmap.md`:

1. **Phase 1 — Foundation & Discovery:** auth + onboarding, master data, all directories/feeds with search & filters, detail pages, saved items, report-a-listing.
2. **Phase 2 — Actions & Supply Side:** athlete registrations/enquiries/applications + activity hub, coach/academy/organizer/sponsor listing creation + inboxes + management.
3. **Phase 3 — Admin, Expiry, Reminders:** admin console, moderation workflow, auto-expiry engine, notification/reminder system.
4. **Phase 4 — Polish & Scale:** capacity/waitlist refinement, results publishing polish, settings/language shell, performance & hardening.

*(Decision applied: no payment phase — payment content removed and noted as excluded.)*

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
