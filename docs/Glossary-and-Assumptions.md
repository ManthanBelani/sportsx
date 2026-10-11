# Glossary and Assumptions — SportX India

> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

Domain-specific definitions and a consolidated list of every assumption made across the documentation set. If something is not explicitly stated in the source documents but is treated as settled in the docs, it appears here with an ID for traceability.

---

## 1. Glossary

| Term | Definition |
|---|---|
| **Athlete / Parent** | A platform user who discovers opportunities. May be a minor athlete with a parent/guardian operating the account; athletes <18 require verified **guardian consent** before activation. Role value: `athlete`. |
| **Academy** | A sports training organization with a public listing (facilities, programs, fees, timings, coaches). Role value: `academy`. Owner is a `users` row with `role=academy`. |
| **Coach** | An individual offering coaching services. Has a public listing (certifications, experience, fees) and can publish **training programs**. Can also browse the app like an athlete. Role value: `coach`. |
| **Organizer** | An entity (federation, club, other) that runs standalone trials, tournaments, and/or camps. Role value: `organizer`. |
| **Talent Scout** | A first-class role that discovers athletes, maintains a shortlist with status/notes, logs observations, writes scout reports (P1), and posts scouting **opportunities**. Contacts athletes via **Connect** (guardian-routed for minors). Role value: `scout`. |
| **Generalized Provider** | A directory profile for allied sports services (doctor, physiotherapist, NGO, store, brand, nutritionist, journalist, agent, federation, facility, school/college, media, photographer, psychologist, government body). **Not a login role** — a discoverable profile (30 fields). |
| **Sponsor / Brand** | **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 role; removed as a login role. Sponsorship is now an **Opportunity type** posted by a provider. |
| **Admin** | Internal platform team member. Not a marketplace user. Manages users (suspend/ban), verification queue, content, moderation, expiry rules, broadcasts, and master categories. Role value: `admin`. Accesses a separate admin portal with 2FA. |
| **Listing** | Any public, discoverable content on the platform: academy, coach/provider profile, trial, tournament, opportunity, program, or facility. |
| **Trial** | A one-off sports evaluation event posted by an academy or organizer. Athletes register to participate. Has an `event_datetime`, `venue`, `eligibility`, `entry_fee`, and `required_documents`. |
| **Tournament** | A multi-round competitive event posted by an organizer. Has `format`, `start_date`/`end_date`, `venue`, `entry_fee`, `prize_pool`, and per-category capacity. |
| **Scholarship** | **[SUPERSEDED — see Backend-Feature-Delta.md]** now an **Opportunity type** (`type=scholarship`); applied in-app (was external-link only). |
| **Sponsorship** | **[SUPERSEDED — see Backend-Feature-Delta.md]** now an **Opportunity type** (`type=sponsorship`); athletes apply in-app with a profile snapshot. |
| **Opportunity** | A unified listing of type **scholarship / sponsorship / tryout / camp**, browsable by all roles; athletes apply in-app. Posted by Academy/Organizer/Coach/Scout (Athlete P1) or `posted_by_admin`. |
| **Program** | A structured **training program** published by a Coach/Academy (title, sport, age group, duration, mode, price, schedule); supports enquiry. |
| **Facility** | A physical training facility listed by an Academy (name, sports, address, amenities, hours, pricing); public detail page. |
| **Enquiry** | A message thread between a user and a provider, initiated by the user. In v3, enquiries live inside the **chat/conversation** system (no separate cold DMs). |
| **Registration** | An athlete's sign-up for a trial or tournament. For trials, includes document upload and verification. For tournaments, includes category selection and capacity enforcement. |
| **Shortlist** | A scout's (or provider's) saved list of promising athlete profiles, with optional status and notes per athlete. |
| **Leaderboard** | A per-sport/season ranking of athletes computed from verified achievements, profile-completion milestones, and activity. Minors are anonymised unless the guardian opts in. |
| **Feed / Post** | The social home feed of user posts (text/photo/video); users like, comment, and save posts. |
| **Follow vs Connect** | **Follow** is one-way (updates in feed); **Connect** is a mutual request that, once accepted, unlocks 1-to-1 **chat**. |
| **Conversation** | A 1-to-1 chat thread between accepted connections or within an enquiry; text at P0, media P1. |
| **Guardian Consent** | Verified approval (guardian name, phone, relationship, OTP) required before a minor athlete's account activates; governs visibility, messaging, and leaderboard identity. |
| **Verification Request** | A user/provider request for a blue-check badge (ID + organisation proof), approved or rejected by an admin. |
| **Expiry** | Automatic status change (published → expired) triggered by configurable rules after an event date, final date, or deadline passes. Admin can override or restore. |
| **Reminder** | A notification sent to a user as a saved trial/tournament/opportunity date or deadline approaches. Triggered by a scheduled job based on reminder subscriptions. |
| **Report** | A user's flag on a listing, post, profile, or chat (reason: fake, outdated, inappropriate, spam, harassment, other) that enters the admin moderation queue. |
| **Block** | A user action that hides content both ways and disables chat between the two accounts. |
| **Master Data** | Admin-managed reference lists: sports, cities/states, age groups, positions. Used across all filters and forms. |
| **Provider** | Collective term for Coach, Academy, Organizer, and **Talent Scout** (and, for directory purposes, Generalized Providers) — the supply side of the marketplace. **Sponsor removed.** |
| **MVP** | Minimum Viable Product — the scope defined in this documentation set. |
| **T1/T2/T3/T4** | Reusable screen templates from the wireframes: T1 = Directory List, T2 = Detail Page, T3 = Enquiry/Registration Form, T4 = Enquiry Inbox + T4b = Enquiry Thread. |

---

## 2. Assumptions Register

Every assumption across the documentation set is listed here with an ID, description, source (where it was first raised), and status.

### Status Legend
- **Open** — not yet decided; needs stakeholder input
- **Accepted** — confirmed by stakeholder or explicitly decided
- **Derived** — inferred from source documents because they're silent on the detail
- **Environment** — limitation of the authoring environment

| ID | Assumption | Source / Raised In | Status | Affected Documents |
|---|---|---|---|---|
| **AS-01** | One role per account; there are **6 login roles** (athlete, coach, academy, organizer, scout, admin). A person who is both a coach and an athlete needs two separate accounts. Multi-role accounts are **parked (P2)**. Generalized Providers are directory profiles, not roles. | ER-Diagram.md | **Superseded** (v3: 6 roles) | ER, DB, API, Auth |
| **AS-02** | Database engine: MySQL 8 / MariaDB 10.6+ (PostgreSQL compatible with minor type changes). | Database-Design.md | Derived | DB, Backend |
| **AS-03** | OTP/email delivery provider and push notification provider are **undecided**. Abstract `OtpProvider` and `NotificationProvider` interfaces used. Default dev implementations: LogOtpProvider, DatabaseNotificationProvider. | Stakeholder decision | Open | Backend, Integration, Security, Class |
| **AS-04** | **[SUPERSEDED — see Backend-Feature-Delta.md]** Sponsor "Message" (SP6) and application "Reply" (SP8) reused the enquiry/thread infrastructure. In v3, provider↔athlete messaging uses the unified **conversation/chat** system, and opportunity applications use the opportunity application model. | Functional-Requirements.md FR-ENQ-3 | **Superseded** | ER, DB, API, System-Flow |
| **AS-05** | Reminder offset (how many days before the event to remind) is unspecified. Default: T-2 days and T-1 day (matching S9 wireframe copy "in 2 days" and "tomorrow"). Configurable in `config/sportx.php`. | System-Flow.md | Derived | Backend, Integration |
| **AS-06** | Multi-value attributes (e.g. `facilities`, `required_documents`, `certifications`) stored as JSON arrays on the parent table for MVP simplicity. Not normalized into separate tables. | ER-Diagram.md conventions | Derived | ER, DB |
| **AS-07** | Media storage uses S3-compatible object storage with CDN for production; local disk for development. | Database-Design.md, Integration-Architecture.md | Derived | DB, Integration, Backend |
| **AS-08** | `registration_ref` format: e.g. `#TR20260815-0042` (auto-generated, unique, human-readable). Exact format is a convention choice. | Database-Design.md | Derived | DB, API |
| **AS-09** | Tournament `format` field is a free-text string (dropdown values like "knockout", "league" not enumerated). Enum can be added later. | Database-Design.md | Derived | DB, API |
| **AS-10** | Reminder subscriptions consolidated into one `reminder_subscriptions` table serving all content types (trials, tournaments, scholarships). Created by save actions, confirmation toggles, and explicit reminder settings. | Database-Design.md | Derived | ER, DB, Backend |
| **AS-11** | Universal search uses per-category DB queries merged at the service layer. A dedicated search engine (Elasticsearch, Meilisearch) is a future enhancement, not MVP. | Database-Design.md | Derived | Backend, API |
| **AS-12** | `academy_coaches` links to a coach `users` row when the coach has a platform account, with an optional `display_name` fallback for coaches without accounts. | ER-Diagram.md | Derived | ER, DB |
| **AS-13** | Only two admin roles exist: `admin` and `super_admin` (boolean). More granular admin permissions (e.g. "content editor" vs "moderator") are not modeled. | Class-Diagram.md | Derived | DB, Backend |
| **AS-14** | Launch cities are unspecified. Seed data uses a sample set (e.g. Ahmedabad, Surat, Mumbai). Actual launch cities are TBD. | Database-Design.md | Open | DB, Roadmap |
| **AS-15** | API base URL path: `/api/v1`. | API-Specification.md | Derived | API, Integration |
| **AS-16** | Auth mechanism: Laravel Sanctum API bearer tokens. | Stakeholder decision (Flutter + Laravel) | Accepted | Backend, Integration, Security, API |
| **AS-17** | Pagination: offset-based (`page` + `per_page`). Cursor pagination is a future enhancement. | API-Specification.md | Derived | API |
| **AS-18** | Flutter state management: Riverpod. Not explicitly required by spec; recommended choice. | Mobile-Architecture.md | Open | Mobile |
| **AS-19** | Flutter navigation: go_router. Not explicitly required; recommended. | Mobile-Architecture.md | Open | Mobile |
| **AS-20** | Flutter HTTP client: Dio. Not explicitly required; recommended. | Mobile-Architecture.md | Open | Mobile |
| **AS-21** | No local database (SQLite, etc.) at MVP. Auth tokens and minimal prefs via `shared_preferences`. | Mobile-Architecture.md | Derived | Mobile |
| **AS-22** | **[SUPERSEDED — see Backend-Feature-Delta.md]** v1 bottom nav (`[Home] [Search] [Saved] [Profile]`) applied only to athlete screens. In v3 **all roles** share one shell: `Home / Explore / (+) Create / Community / More`; role tools live in the More menu. | Mobile-Architecture.md | **Superseded** | Mobile |
| **AS-23** | Laravel version: 11.x. | Backend-Architecture.md | Derived | Backend |
| **AS-24** | PHP version: 8.2+. | Backend-Architecture.md | Derived | Backend |
| **AS-25** | Queue driver: database for dev; Redis recommended for production. | Backend-Architecture.md | Derived | Backend |
| **AS-26** | Admin 2FA: TOTP (e.g. Google Authenticator). Session tracked via `admin_2fa_verified_at` timestamp on the user model or token. Implementation detail to be finalized. | Backend-Architecture.md, Security doc | Derived | Backend, Security |
| **AS-27** | HTTP timeout: 30s connect, 60s receive for API calls; 120s for media upload. | Integration-Architecture.md | Derived | Mobile, Integration |
| **AS-28** | No token refresh mechanism at MVP. Token lifetime is long (default 1 year, configurable). Refresh + short-lived tokens are post-MVP. | Integration-Architecture.md | Derived | Integration, Security |
| **AS-29** | Rate-limit 429 responses include `Retry-After` header. | Integration-Architecture.md | Derived | API, Security |
| **AS-30** | No offline mode or retry queue at MVP. Network errors show a connectivity banner; stale cached content may display read-only. | Mobile-Architecture.md | Derived | Mobile |
| **AS-31** | Map preview on detail pages (T2 "Location"): implementation choice (static map image embed vs platform-native map view). Vendor/format TBD. | Integration-Architecture.md | Open | Integration, Mobile |
| **AS-32** | Geocoding (address → lat/lng) for map preview. Not specified in sources; may be needed if interactive map is chosen. | Integration-Architecture.md | Open | Integration |
| **AS-33** | **Payments excluded from MVP** — entry fees are informational display strings; tournament payment status is a manual flag set by the organizer. No payment gateway integration. | Stakeholder decision | Accepted | All docs |
| **AS-34** | **RESOLVED (v3):** minors are **not** excluded from discovery, but minors' accounts require verified **guardian consent** before activation, with restricted visibility/messaging defaults, leaderboard anonymisation, and guardian-routed scout contact. (FR-GUARD-1…3.) | Security doc | **Resolved** | Security, Legal, FR |
| **AS-35** | Hard purge of soft-deleted account data: scheduled 90 days after account deletion. | Security doc | Derived | Security, Backend |
| **AS-36** | Full data export (right to access per DPDP Act) and grievance officer contact are not in MVP scope. | Security doc | Derived | Security |
| **AS-37** | Server deployment region is unspecified. Given India-focused user base, India region recommended but not required. | Security doc | Open | Security, Infra |
| **AS-38** | Rate limit values (per-endpoint thresholds) are proposed defaults. Actual values should be validated after load testing. | Security doc | Open | Security |
| **AS-39** | Database read replicas for directory/search queries are deferred to Phase 4 or later. | Security doc | Derived | Backend |
| **AS-40** | API P95 response time targets: <500ms for lists, <300ms for details. Directional; validated via load testing. | Security doc | Derived | Security, Performance |
| **AS-41** | Scheduled sweep job duration target: <30s for up to 10,000 listings. Directional. | Security doc | Derived | Backend |
| **AS-42** | Deployment strategy: blue-green or zero-downtime. Tool choice (Laravel Deployer, Envoyer, or CI/CD) unspecified. | Security doc | Open | Backend, DevOps |
| **AS-43** | Database backups: daily automated + point-in-time recovery. Tool choice unspecified. | Security doc | Open | DevOps |
| **AS-44** | Monitoring/error tracking tool: Sentry or equivalent. Not specified. | Security doc | Open | Backend, DevOps |
| **AS-45** | Audit log: moderation actions and expiry override/restore are tracked via DB columns (`resolved_by`, `overridden_by`) at minimum. A dedicated audit log table is optional. | Security doc | Derived | Backend, Security |
| **AS-46** | Phase duration estimates (~4-6 weeks each) are for a small team. Actual timeline depends on team size and velocity. | Phased-Roadmap.md | Open | Roadmap, Project Planning |
| **AS-47** | **`sports_venues`** is a new entity from the Mandatory Fields PDF (venue name, sport, address, Google Maps, contact — all mandatory). Not in the original Screen Inventory; added as a 7th listing type using T1/T2 templates. | Mandatory Fields PDF | Derived | ER, DB, API, Mobile, FR |
| **AS-48** | **Tournament `registration_link`** is mandatory per PDF (external registration link) — coexists with the in-app registration flow from wireframes. Both paths supported: athletes can register in-app OR the organizer can provide an external link. | Mandatory Fields PDF | Derived | DB, API, FR |
| **AS-49** | **Tournament `registration_deadline`** and **trial `registration_deadline`** are mandatory per PDF. Added to both tables. Can drive expiry or reminder behavior. | Mandatory Fields PDF | Derived | DB, API, FR |
| **AS-50** | **Athlete `date_of_birth` and `gender`** are mandatory per PDF but were not in the wireframes. Added to `athlete_profiles`. `age_group_id` is still the primary grouping field; `date_of_birth` provides precise age. | Mandatory Fields PDF | Derived | DB, API, FR |
| **AS-51** | **Academy `description`** and **`year_established`** are mandatory/optional per PDF. Description added as mandatory; year_established as optional. | Mandatory Fields PDF | Derived | DB, API |
| **AS-52** | **Coach `contact_number`** is mandatory per PDF (separate from `city_id`). Added as dedicated field on `coach_profiles`. | Mandatory Fields PDF | Derived | DB, API |
| **AS-53** | **OTP via phone OR email** (both P0). Users verify one contact channel at signup; the other can be added later. Replaces the v1 "email-first" assumption (A1). | Backend-Feature-Delta.md (D1) | Accepted | Auth, API, Backend |
| **AS-54** | **Sponsor role removed** (D2); sponsorship is an opportunity type. Talent Scout is promoted to a first-class login role. | Backend-Feature-Delta.md (D2) | Accepted | All docs |
| **AS-55** | **Generalized Providers are directory profiles, not login roles.** 16 categories with 30 fields (9 mandatory). | SportX_Mandatory_Fields.md §6 | Accepted | DB, API, FR |
| **AS-56** | **Profiles capture 30 fields per role** (8–9 mandatory) with a completion checklist. Replaces the v1 PDF field set (AS-47–AS-52 remain as history). | SportX_Mandatory_Fields.md | Accepted | DB, API, Mobile, FR |
| **AS-57** | **New P0 areas** added: social feed/posts/likes/comments, follow/connect, 1:1 chat, leaderboard, unified opportunities, programs, facilities, verification queue, admin user management, blocks/reports. | Backend-Feature-Delta.md §9 | Accepted | All docs |
| **AS-58** | **Parked (P2):** payments, boosts, groups, polls, live streaming, map view, multi-role, teams, staff recruiting. | Backend-Feature-Delta.md §10 | Accepted | Roadmap, All docs |

### Assumptions from PRD (decisions confirmed by stakeholder)

| PRD ID | Description | Status |
|---|---|---|
| **A1** | **[SUPERSEDED — see Backend-Feature-Delta.md]** v1: email is the primary OTP channel. v3: **OTP via phone OR email (both P0)** — see AS-53. | Superseded |
| **A2** | No in-app payments in MVP. Entry fees/prize pools are display-only. | Accepted |
| **A3** | **[SUPERSEDED by AS-58]** Paid boosts/promotion are parked (P2). Push notification and SMS/OTP providers undecided (abstract interfaces). | Open |
| **A4** | Admin module fully documented; the **P0 slice** (user management + verification queue) ships; the rest follows in later phases. | Accepted |
| **A5** | `SportX_India_Mandatory_Fields_MVP.pdf` could not be parsed in this environment. | Environment | **RESOLVED** — converted via pdftotext; superseded by `SportX_Mandatory_Fields.md` (30 fields/role). See AS-47–AS-56. |
| **A6** | Platform targets India (phone +91, pricing ₹). | Derived |
| **A7** | MVP ships English only despite language selector in Settings. | Derived |

---

## 3. Decision Log

| Decision | Options Considered | Chosen | Reason |
|---|---|---|---|
| Payments in MVP | Razorpay UPI/cards, External link only, Generic gateway placeholder | **Excluded entirely** | Stakeholder wants to defer payment complexity |
| Notification/OTP vendor | Firebase FCM + MSG91, FCM only + email OTP, Undecided placeholders | **Undecided placeholders** | Stakeholder wants to defer vendor selection |
| Admin build phase | Full docs later phase, Phase 1, Exclude from MVP | **Full docs; P0 slice (users + verification) in MVP** | Stakeholder wants admin documented but not blocking core flows |
| Primary auth channel | Phone SMS OTP, Email OTP first, Both equally supported | **Phone OR Email OTP (both P0)** | v3 decision (D1); user chooses at signup |
| Sponsor role | Keep Sponsor, Replace with Scout, Fold into opportunities | **Remove Sponsor; Talent Scout first-class** | v3 decision (D2) |
| Generalised providers | Login roles, Directory profiles, Exclude | **Directory profiles (not login roles)** | v3 decision; 16 categories, 30 fields |
| Flutter state management | Riverpod, BLoC, Provider, GetX | **Riverpod** (recommended) | Best fit for the project's complexity and code-gen approach |
| Flutter navigation | go_router, auto_route, Navigator 2.0 | **go_router** (recommended) | Declarative, deep link support |
| Flutter HTTP client | Dio, http, chopper | **Dio** (recommended) | Interceptor ecosystem, mature |

---

## 4. Open Items (Require Stakeholder Input)

| # | Item | Urgency | Relevant Assumption(s) |
|---|---|---|---|
| 1 | **Select SMS/OTP vendor** (MSG91, Twilio, etc.) for production | Before Phase 3 (reminders need delivery) | AS-03 |
| 2 | **Select push notification vendor** (FCM, OneSignal, etc.) | Before Phase 3 | AS-03 |
| 3 | ~~**Confirm minors' data handling**~~ **RESOLVED (v3):** guardian consent + restricted defaults + leaderboard anonymisation. Remaining legal sign-off on consent copy. | Before launch (legal review) | AS-34 |
| 4 | **Select map preview implementation** — static image vs interactive map SDK | Before Phase 1 (affects detail page template) | AS-31, AS-32 |
| 5 | **Specify launch cities** for initial seed data | Before Phase 1 (data seeding) | AS-14 |
| 6 | **Determine reminder offset strategy** — T-2d and T-1d, or user-configurable? | Before Phase 3 | AS-05 |
| 7 | **Review and confirm rate limit values** after load testing | Phase 4 | AS-38 |
| 8 | **Select monitoring/error tracking tool** (Sentry, etc.) | Phase 4 | AS-44 |
| 9 | **Select deployment strategy and tooling** | Phase 4 | AS-42 |
| 10 | **Clarify tournament `registration_link` (external) vs in-app registration** — should both be mandatory? Which takes priority? | Before Phase 2 | AS-48 |
| 11 | **Clarify `age_group_id` vs `date_of_birth`** on athlete profile — both present now; which drives eligibility checks? | Before Phase 2 | AS-50 |
| 12 | **Confirm Flutter state management choice** (Riverpod recommended) | Before Phase 0 | AS-18 |
| 13 | **Confirm Flutter navigation choice** (go_router recommended) | Before Phase 0 | AS-19 |
| 14 | **Plan payment integration for post-MVP** — Razorpay, Paytm, or other? | Post-MVP | A2 (Accepted exclusion) |
| 15 | **Guardian consent copy + age threshold** (DPDP Act compliance) | Before launch (legal review) | AS-34, FR-GUARD |
| 16 | **Scout contact of minors** — confirm guardian-routing flow and any consent-log requirements | Before launch | FR-SOC-5, FR-GUARD-2 |
| 17 | **Generalized Provider category list** — confirm the 16 categories and their mandatory fields | Before Phase 1 | AS-55 |
