# Glossary and Assumptions — SportX India

Domain-specific definitions and a consolidated list of every assumption made across the documentation set. If something is not explicitly stated in the source documents but is treated as settled in the docs, it appears here with an ID for traceability.

---

## 1. Glossary

| Term | Definition |
|---|---|
| **Athlete / Parent** | A platform user who discovers opportunities. May be a minor athlete with a parent operating the account. Role value: `athlete`. |
| **Academy** | A sports training organization with a public listing (facilities, fees, timings, coaches). Role value: `academy`. Owner is a `users` row with `role=academy`. |
| **Coach** | An individual offering coaching services. Has a public listing (certifications, experience, fees). Can also browse the app like an athlete. Role value: `coach`. |
| **Organizer** | An entity (federation, club, other) that runs standalone trials and/or tournaments. Role value: `organizer`. |
| **Sponsor / Brand** | A brand or company seeking to back athletes. Posts sponsorship opportunities, discovers athletes, reviews applications. Role value: `sponsor`. |
| **Admin** | Internal platform team member. Not a marketplace user. Manages data quality, moderation, expiry rules, and master categories. Role value: `admin`. Accesses a separate admin portal with 2FA. |
| **Listing** | Any public, discoverable content on the platform: academy, coach profile, trial, tournament, scholarship, or sponsorship. |
| **Trial** | A one-off sports evaluation event posted by an academy or organizer. Athletes register to participate. Has an `event_datetime`, `venue`, `eligibility`, `entry_fee`, and `required_documents`. |
| **Tournament** | A multi-round competitive event posted by an organizer. Has `format`, `start_date`/`end_date`, `venue`, `entry_fee`, `prize_pool`, and per-category capacity. |
| **Scholarship** | A curated, admin-maintained listing of a sports scholarship or government scheme. Athletes apply externally via a provider link. |
| **Sponsorship** | An opportunity posted by a sponsor/brand. Athletes pitch their profile and achievements. Sponsor reviews, shortlists, and responds. |
| **Enquiry** | A message thread between an athlete and a coach, academy, or sponsor. Initiated by the athlete; the provider replies. Not a real-time chat system. |
| **Registration** | An athlete's sign-up for a trial or tournament. For trials, includes document upload and verification. For tournaments, includes category selection and capacity enforcement. |
| **Shortlist** | A sponsor's saved list of promising athlete profiles, with optional notes per athlete. |
| **Expiry** | Automatic status change (published → expired) triggered by configurable rules after an event date, final date, or deadline passes. Admin can override or restore. |
| **Reminder** | A notification sent to a user as a saved trial date, tournament date, or scholarship deadline approaches. Triggered by a scheduled job based on reminder subscriptions. |
| **Report** | A user's flag on a listing (reason: fake, outdated, inappropriate, other) that enters the admin moderation queue. |
| **Master Data** | Admin-managed reference lists: sports, cities/states, age groups. Used across all filters and forms. |
| **Provider** | Collective term for Coach, Academy, Organizer, and Sponsor — the supply side of the marketplace. |
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
| **AS-01** | One role per account. A person who is both a coach and an athlete needs two separate accounts. | ER-Diagram.md | Derived | ER, DB, API, Auth |
| **AS-02** | Database engine: MySQL 8 / MariaDB 10.6+ (PostgreSQL compatible with minor type changes). | Database-Design.md | Derived | DB, Backend |
| **AS-03** | OTP/email delivery provider and push notification provider are **undecided**. Abstract `OtpProvider` and `NotificationProvider` interfaces used. Default dev implementations: LogOtpProvider, DatabaseNotificationProvider. | Stakeholder decision | Open | Backend, Integration, Security, Class |
| **AS-04** | Sponsor "Message" (SP6) and sponsor application "Reply" (SP8) reuse the enquiry/thread infrastructure (`enquiries` + `enquiry_messages` with `subject_type = sponsorship_application`). No separate chat system exists. | Functional-Requirements.md FR-ENQ-3 | Derived | ER, DB, API, System-Flow |
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
| **AS-22** | Bottom navigation bar (`[Home] [Search] [Saved] [Profile]`) applies only to athlete/parent screens. Provider roles (Coach, Academy, Organizer, Sponsor) have their own navigation patterns (dashboard + tabs). | Mobile-Architecture.md | Derived | Mobile |
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
| **AS-34** | Sponsor discovery can find all athlete profiles regardless of age group (including minors). Whether minors should be excluded by default requires **legal/compliance review before launch**. | Security doc | Open | Security, Legal |
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

### Assumptions from PRD (decisions confirmed by stakeholder)

| PRD ID | Description | Status |
|---|---|---|
| **A1** | Email is the primary OTP-verified channel; phone verification comes later. | Accepted |
| **A2** | No in-app payments in MVP. Entry fees/prize pools are display-only. | Accepted |
| **A3** | Push notification and SMS/OTP providers undecided (abstract interfaces). | Open |
| **A4** | Admin module fully documented but built in a later phase. | Accepted |
| **A5** | `SportX_India_Mandatory_Fields_MVP.pdf` could not be parsed in this environment. | Environment | **RESOLVED** — converted via pdftotext; fields merged. See AS-47–AS-50. |
| **A6** | Platform targets India (phone +91, pricing ₹). | Derived |
| **A7** | MVP ships English only despite language selector in Settings. | Derived |

---

## 3. Decision Log

| Decision | Options Considered | Chosen | Reason |
|---|---|---|---|
| Payments in MVP | Razorpay UPI/cards, External link only, Generic gateway placeholder | **Excluded entirely** | Stakeholder wants to defer payment complexity |
| Notification/OTP vendor | Firebase FCM + MSG91, FCM only + email OTP, Undecided placeholders | **Undecided placeholders** | Stakeholder wants to defer vendor selection |
| Admin build phase | Full docs later phase, Phase 1, Exclude from MVP | **Full docs, later phase** | Stakeholder wants admin documented but not blocking Phase 1 |
| Primary auth channel | Phone SMS OTP, Email OTP first, Both equally supported | **Email OTP first** | Stakeholder decision; phone deferred |
| Flutter state management | Riverpod, BLoC, Provider, GetX | **Riverpod** (recommended) | Best fit for the project's complexity and code-gen approach |
| Flutter navigation | go_router, auto_route, Navigator 2.0 | **go_router** (recommended) | Declarative, deep link support |
| Flutter HTTP client | Dio, http, chopper | **Dio** (recommended) | Interceptor ecosystem, mature |

---

## 4. Open Items (Require Stakeholder Input)

| # | Item | Urgency | Relevant Assumption(s) |
|---|---|---|---|
| 1 | **Select SMS/OTP vendor** (MSG91, Twilio, etc.) for production | Before Phase 3 (reminders need delivery) | AS-03 |
| 2 | **Select push notification vendor** (FCM, OneSignal, etc.) | Before Phase 3 | AS-03 |
| 3 | **Confirm minors' data handling** — should minors be excluded from sponsor discovery? | Before launch (legal review) | AS-34 |
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
