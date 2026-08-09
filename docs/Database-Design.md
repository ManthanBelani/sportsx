# Database Design — SportX India

Physical schema matching **Laravel migration structure** (Blueprint-style definitions). Logical model: see `ER-Diagram.md`.

> **Conventions & global decisions**
> - **Engine:** MySQL 8 / MariaDB 10.6+ assumed (AS-02). PostgreSQL-compatible with minor type adjustments (`json`→`jsonb`, enums→check constraints).
> - Every table gets: `id()` (bigint PK), `timestamps()` (created_at/updated_at). `softDeletes()` only where user-facing records must be removable without losing history (noted per table).
> - Status fields on listings share the enum set: `draft`, `published`, `closed`, `expired`, `removed` (scholarships/sponsorships use a subset — noted per table).
> - "Fee" columns are `string` (display-only, e.g. `"₹2000–₹5000/mo"`) because no payment processing exists (decision). Only `scholarships.amount` is numeric since it's a single figure to display/sort by.
> - All FKs `constrained()` with `cascadeOnDelete()` for owned children, `nullOnDelete()` for optional references.
> - **Mandatory/Optional** labels match `SportX_India_Mandatory_Fields_MVP.pdf` (now resolved — AS-05). Mandatory fields are marked `■ Mandatory`; optional fields are nullable or have defaults.

---

## 1. Identity & Auth

### `users`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint unsigned | PK, auto | |
| role | enum('athlete','coach','academy','organizer','sponsor','admin') | index | Fixed at sign-up (S2) |
| name | string(100) | | Display name |
| email | string(190) | unique | Primary verified channel (decision) |
| email_verified_at | timestamp | nullable | Set by OTP verify (S4) |
| phone | string(20) | nullable, index | Captured but **not verified** at MVP |
| password | string(255) | | bcrypt/argon hash; nullable only if Google-only account |
| google_id | string(64) | nullable, unique | "Continue with Google" (S3) |
| status | enum('active','suspended','deleted') | default 'active' | Admin moderation of users |
| remember_token | string(100) | nullable | |

**Indexes:** `role`, `status`, composite `(role, status)` for admin dashboard counts.

### `otp_codes`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| user_id | FK → users | cascadeOnDelete |
| channel | enum('email','phone') | index (email used at MVP) |
| destination | string(190) | The address the code was sent to |
| code_hash | string(255) | Hashed 6-digit code — never stored plain |
| expires_at | timestamp | index for purge job |
| attempts | unsignedTinyInteger | default 0 |
| consumed_at | timestamp | nullable |

**Index:** `(user_id, channel, created_at)`.

### `admin_profiles`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| user_id | FK → users | unique, cascadeOnDelete |
| two_factor_secret | string(255) | nullable until enrolled (AD1 2FA) |
| is_super_admin | boolean | default false (assumption AS-13 — roles beyond "admin" unspecified) |

---

## 2. Master Data (admin-managed, AD10–12)

### `sports`

| id | name string(60) unique | is_active boolean default true | sort_order unsignedSmallInteger default 0 |

### `cities`

| id | name string(100) | state string(100) | is_active boolean |

**Index:** unique `(name, state)`; index `state` (S8 filter shows city/state).

### `age_groups`

| id | name string(30) unique (e.g. "Under-14") | min_age nullable tinyint | max_age nullable tinyint | is_active boolean |

---

## 3. Athlete

### `athlete_profiles`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| user_id | FK → users | unique, cascadeOnDelete | — |
| full_name | string(100) | | ■ Mandatory (PDF) |
| date_of_birth | date | index | ■ Mandatory (PDF) |
| gender | enum('male','female','other','prefer_not_to_say') | | ■ Mandatory (PDF) |
| age_group_id | FK → age_groups | restrictOnDelete | ■ Mandatory (onboarding) |
| skill_level | enum('beginner','intermediate','advanced','competitive') | | ■ Mandatory (onboarding A2) |
| city_id | FK → cities | nullOnDelete | ■ Mandatory (onboarding A2) |
| phone | string(20) | nullable | Optional (PDF) |
| academy_id | FK → academies | nullable, nullOnDelete | Optional (PDF) |
| coach_id | FK → coach_profiles | nullable, nullOnDelete | Optional (PDF) |
| position | string(100) | nullable | Optional (PDF) |
| experience | string(255) | nullable | Optional (PDF) |
| photo_media_id | FK → media_items | nullable, nullOnDelete | ■ Mandatory (PDF) |

### `athlete_sports`

| id | athlete_id FK→athlete_profiles cascade | sport_id FK→sports restrict |

**Unique:** `(athlete_id, sport_id)`.

### `achievements`

| id | athlete_id FK cascade | text string(255) — one line per wireframe bullet | sort_order smallint |

### `media_items` (shared)

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| owner_type | string | morphs index — athlete_profile / coach_profile / academy / organizer_profile / sponsor_profile / trial_registration |
| owner_id | bigint | |
| media_type | enum('photo','video','document') | |
| disk | string(30) default 's3' | Object storage (NFR-4) |
| path | string(255) | |
| original_name | string(190) | nullable |
| mime_type | string(80) | |
| size_bytes | unsignedInteger | |
| sort_order | smallint | default 0 — drag-to-reorder (A6) |

**Index:** `(owner_type, owner_id, sort_order)`. softDeletes.

---

## 4. Providers

### `coach_profiles`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| user_id | FK → users | unique, cascadeOnDelete | — |
| full_name | string(100) | | ■ Mandatory (PDF) |
| sport_id | FK → sports | restrictOnDelete | ■ Mandatory (PDF) |
| city_id | FK → cities | nullOnDelete | ■ Mandatory (PDF) |
| contact_number | string(20) | nullable | ■ Mandatory (PDF) |
| experience | string(255) | | ■ Mandatory (PDF) |
| qualification | string(255) | nullable | Optional (PDF) |
| certifications | json | nullable | Optional (PDF) |
| academy_id | FK → academies | nullable, nullOnDelete | Optional (PDF) |
| languages | json | nullable | Optional (PDF) |
| email | string(190) | nullable | Optional (PDF) |
| personal_coaching | boolean | default false | Optional (PDF) |
| fee_structure | string(120) | nullable | Optional (PDF) |
| bio | text | nullable | |
| listing_status | enum('draft','published','closed','removed') | default 'draft' | System |
| profile_completeness | tinyint unsigned | default 0 | System |
| photo_media_id | FK → media_items | nullable, nullOnDelete | Optional (PDF) |

**Index:** `(listing_status, city_id)` for directory queries; fulltext on `(bio)` if MySQL.

### `academies`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| owner_user_id | FK → users | cascade | — |
| name | string(150) | | ■ Mandatory (PDF) |
| description | text | | ■ Mandatory (PDF) |
| address | string(255) | | ■ Mandatory (PDF) |
| city_id | FK → cities | nullOnDelete | ■ Mandatory (PDF) |
| contact_number | string(20) | | ■ Mandatory (PDF) |
| google_maps_url | string(255) | nullable | ■ Mandatory (PDF — URL or embed) |
| facilities | json | nullable | Optional (PDF) |
| fee_range | string(60) | nullable | Optional (PDF) |
| timings | string(120) | nullable | Optional (PDF) |
| age_groups | json | nullable | Optional (PDF) |
| year_established | smallint unsigned | nullable | Optional (PDF) |
| achievements | json | nullable | Optional (PDF) |
| email | string(190) | nullable | Optional (PDF) |
| website | string(255) | nullable | Optional (PDF) — Website/Social Media |
| head_coach_id | FK → users | nullable, nullOnDelete | Optional (PDF) |
| logo_media_id | FK → media_items | nullable, nullOnDelete | Optional (PDF) |
| cover_media_id | FK → media_items | nullable, nullOnDelete | Optional (PDF) |
| listing_status | enum('draft','published','closed','expired','removed') | | System |
| verification_badge | boolean | default false | System |

**Index:** `(listing_status, city_id)`.

### `academy_sports` — id, academy_id FK cascade, sport_id FK; unique pair.

### `academy_coaches`

| id | academy_id FK cascade | coach_user_id FK→users nullable | display_name string(100) nullable | *coach_user_id set when linked to a coach account (AS-12); display_name fallback otherwise* |

### `organizer_profiles`

| id | user_id FK unique cascade | organization_name string(150) | org_type enum('federation','club','other') | verification_status enum('pending','verified','rejected') default 'pending' |

### `sponsor_profiles`

| id | user_id FK unique cascade | brand_name string(150) | logo_media_id FK nullable | category string(80) | verification_status enum('pending','verified','rejected') default 'pending' |

---

## 5. Trials

### `trials`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| posted_by_user_id | FK → users | cascade | — |
| academy_id | FK → academies | nullable, nullOnDelete | — |
| name | string(150) | | ■ Mandatory (PDF) |
| organization_name | string(150) | nullable | ■ Mandatory (PDF) |
| sport_id | FK → sports | restrict | ■ Mandatory (PDF) |
| event_datetime | timestamp | index | ■ Mandatory (PDF: "Date") |
| venue | string(190) | | ■ Mandatory (PDF) |
| google_maps_url | string(255) | nullable | ■ Mandatory (PDF) |
| city_id | FK → cities | nullOnDelete | — |
| contact_number | string(20) | | ■ Mandatory (PDF) |
| registration_deadline | timestamp | nullable, index | ■ Mandatory (PDF) |
| eligibility | text | nullable | Optional (PDF) |
| required_documents | json | nullable | Optional (PDF) |
| vacancies | smallint unsigned | nullable | Optional (PDF) |
| benefits | text | nullable | Optional (PDF) |
| entry_fee | string(60) | nullable | Optional (PDF) |
| status | enum('draft','published','closed','expired','removed') | default 'draft', index | System |
| expires_at | timestamp | nullable, index | System |
| softDeletes | | |

**Indexes:** `(status, event_datetime)` (discovery lists), `(status, expires_at)` (expiry sweep), `(sport_id, city_id, status)` (filtered browse), `(posted_by_user_id, status)` (My Trials).

### `trial_registrations`

| id | trial_id FK cascade | athlete_id FK→athlete_profiles cascade | registration_ref string(20) unique — e.g. `#TR20260815-0042` (format AS-08) | document_status enum('pending','submitted') default 'pending' | verification_status enum('pending','verified','rejected') default 'pending' — AC7 actions | reminder_enabled boolean default false | softDeletes |

**Unique:** `(trial_id, athlete_id)`. **Index:** `(athlete_id, verification_status)` for My Activity.

### `trial_registration_documents`

| id | trial_registration_id FK cascade | document_type string(60) — must be in trial.required_documents (app-level check) | media_item_id FK→media_items cascade | status enum('uploaded','rejected') default 'uploaded' |

---

## 6. Tournaments

### `tournaments`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| organizer_id | FK → organizer_profiles | cascade | — |
| sport_id | FK → sports | restrict | ■ Mandatory (PDF) |
| name | string(150) | | ■ Mandatory (PDF) |
| organizer_name | string(150) | nullable | ■ Mandatory (PDF) |
| format | string(40) | nullable | — (AS-09) |
| start_date | date | | ■ Mandatory (PDF: "Tournament Dates") |
| end_date | date | nullable | ■ Mandatory (PDF) |
| registration_deadline | date | nullable, index | ■ Mandatory (PDF) |
| venue | string(190) | | ■ Mandatory (PDF) |
| google_maps_url | string(255) | nullable | ■ Mandatory (PDF) |
| city_id | FK → cities | nullOnDelete | — |
| entry_fee | string(60) | nullable | ■ Mandatory (PDF) |
| contact_number | string(20) | nullable | ■ Mandatory (PDF) |
| registration_link | string(255) | nullable | ■ Mandatory (PDF — external link) |
| prize_pool | string(60) | nullable | Optional (PDF) |
| rules | text | nullable | Optional (PDF) |
| banner_media_id | FK → media_items | nullable, nullOnDelete | Optional (PDF) |
| gender | enum('male','female','mixed','open') | nullable | Optional (PDF) |
| status | enum('draft','published','closed','expired','removed') | | System |
| expires_at | timestamp | nullable | System |
| softDeletes | | |

**Indexes:** `(status, start_date)` (calendar), `(sport_id, city_id, status)`, `(organizer_id, status)`.

### `tournament_categories`

| id | tournament_id FK cascade | age_group_id FK restrict | name string(60) nullable — display override e.g. "U-16" | capacity unsignedSmallInteger | waitlist_enabled boolean default false |

**Unique:** `(tournament_id, age_group_id)`.

### `tournament_registrations`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| tournament_id | FK → tournaments | cascade |
| category_id | FK → tournament_categories | cascade |
| athlete_id | FK → athlete_profiles | cascade |
| participation_type | enum('individual','team') | A18 team/individual |
| team_name | string(120) | nullable |
| payment_status | enum('pending','paid') | default 'pending' — **manual flag only (O7), no payment gateway** |
| status | enum('pending','confirmed','waitlisted','cancelled') | default 'pending' |
| softDeletes | | |

**Unique:** `(tournament_id, category_id, athlete_id)`. **Index:** `(category_id, status)` for capacity counts.

### `tournament_results`

| id | tournament_id FK cascade | category_id FK→tournament_categories cascade | place tinyint — 1/2/3 | winner_name string(150) | bracket_media_id FK→media_items nullable — uploaded bracket image (O9) | published_at timestamp nullable |

**Unique:** `(category_id, place)` — one row per podium slot.

---

## 7. Scholarships (admin-curated)

### `scholarships`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| organization_name | string(150) | | ■ Mandatory (PDF) |
| name | string(150) | | ■ Mandatory (PDF: "Sponsorship/Scholarship Name") |
| sport_id | FK → sports | nullable, restrict | ■ Mandatory (PDF) |
| eligibility | text | | ■ Mandatory (PDF) |
| deadline | date | index | ■ Mandatory (PDF: "Last Date") |
| application_link | string(255) | | ■ Mandatory (PDF: "Application Link") |
| contact_email | string(190) | nullable | ■ Mandatory (PDF: "Contact Email/Number") |
| contact_phone | string(20) | nullable | ■ Mandatory (PDF) |
| amount | decimal(12,2) | nullable | Optional (PDF) |
| currency | char(3) | default 'INR' | — |
| benefits | text | nullable | Optional (PDF) |
| documents_required | json | nullable | Optional (PDF) |
| description | text | nullable | Optional (PDF) |
| logo_media_id | FK → media_items | nullable, nullOnDelete | Optional (PDF) |
| status | enum('draft','published','expired','removed') | default 'published' | System |
| created_by | FK → users | nullOnDelete (admin) | — |
| softDeletes | | |

**Indexes:** `(status, deadline)`, `(sport_id, status)`.

---

## 8. Sponsorships

### `sponsorships`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| sponsor_id | FK → sponsor_profiles | cascade | — |
| organization_name | string(150) | nullable | ■ Mandatory (PDF) |
| sport_id | FK → sports | restrict | ■ Mandatory (PDF) |
| title | string(150) | | ■ Mandatory (PDF: "Sponsorship/Scholarship Name") |
| eligibility_criteria | text | | ■ Mandatory (PDF) |
| deadline | date | index | ■ Mandatory (PDF: "Last Date") |
| application_link | string(255) | nullable | ■ Mandatory (PDF: "Application Link") |
| contact_email | string(190) | nullable | ■ Mandatory (PDF: "Contact Email/Number") |
| contact_phone | string(20) | nullable | ■ Mandatory (PDF) |
| benefits_offered | text | nullable | Optional (PDF) |
| amount | decimal(12,2) | nullable | Optional (PDF) |
| documents_required | json | nullable | Optional (PDF) |
| description | text | nullable | Optional (PDF) |
| logo_media_id | FK → media_items | nullable, nullOnDelete | Optional (PDF) |
| status | enum('draft','published','closed','expired','removed') | default 'draft' | System |
| expires_at | timestamp | nullable | System |
| softDeletes | | |

**Indexes:** `(status, deadline)`, `(sport_id, status)`.

### `sponsorship_applications`

| id | sponsorship_id FK cascade | athlete_id FK cascade | pitch_note text | status enum('submitted','shortlisted','rejected') default 'submitted' | replied_at timestamp nullable — SP8 Reply leaves a marker |

**Unique:** `(sponsorship_id, athlete_id)`. **Index:** `(athlete_id, status)` (My Activity), `(sponsorship_id, status)` (inbox).

### `shortlist_entries`

| id | sponsor_id FK cascade | athlete_id FK cascade | note text nullable |

**Unique:** `(sponsor_id, athlete_id)`.

---

## 9. Enquiries (coach/academy inboxes + sponsor application replies)

### `enquiries`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| athlete_id | FK → athlete_profiles | cascade — initiator |
| subject_type | string | morphs: `coach_profile`,`academy`,`sponsorship_application` |
| subject_id | bigint | |
| preferred_datetime | timestamp | nullable — A11 preferred date/time |

**Indexes:** morphs `(subject_type, subject_id, updated_at)` for inbox sort; `(athlete_id, updated_at)`.

### `enquiry_messages`

| id | enquiry_id FK cascade | sender_user_id FK→users cascade | body text | read_at timestamp nullable |

**Index:** `(enquiry_id, created_at)`.

---

## 10. Saves, Reports, Notifications

### `saved_items`

| id | user_id FK cascade | item_type string — morphs (academy/coach_profile/trial/tournament/scholarship/sponsorship) | item_id bigint |

**Unique:** `(user_id, item_type, item_id)`.

### `listing_reports`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| reporter_user_id | FK → users | cascade |
| reportable_type | string | morphs across the six listing types |
| reportable_id | bigint | |
| reason | enum('fake','outdated','inappropriate','other') | S10 options |
| comment | text | nullable |
| status | enum('pending','approved','edited','removed','warned') | default 'pending' — AD7 outcomes |
| resolved_by | FK → users (admin) | nullable, nullOnDelete |
| resolved_at | timestamp | nullable |

**Indexes:** `(reportable_type, reportable_id, status)` for AD6 aggregation; `(status, created_at)` for the queue.

### `notifications`

| id | user_id FK cascade | type enum('reminder','enquiry_reply','status_update') | title string(190) | body string(255) | notifiable_type string nullable | notifiable_id bigint nullable | read_at timestamp nullable index |

**Index:** `(user_id, read_at, created_at)` — unread-first listing (S9).

---

## 11. Expiry System

### `expiry_rules`

| id | content_type enum('trial','tournament','sponsorship','scholarship') | trigger_field enum('event_date','final_date','listed_deadline') | days_after smallint default 0 | is_active boolean default true |

**Unique:** `content_type` (one active rule per type — matches AD8's per-type rows).

### `expiry_events`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| content_type | enum(...) | same set as rules |
| content_id | bigint | Polymorphic without ORM morph (kept loose for sweep queries) |
| scheduled_at | timestamp | |
| executed_at | timestamp | nullable |
| status | enum('pending','expired','overridden','restored') | default 'pending' — AD9 tabs |
| overridden_by | FK → users (admin) | nullable |

**Indexes:** `(status, scheduled_at)` (sweep), `(content_type, content_id)`, unique pending per item via app logic.

---

## 12. Sports Venues (new entity — from Mandatory Fields PDF)

> A discoverable listing type for physical sports venues (stadia, grounds, courts). Not in the original wireframe Screen Inventory but defined as a mandatory entity in the PDF field spec.

### `sports_venues`

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| name | string(150) | | ■ Mandatory (PDF) |
| sport_id | FK → sports | restrict | ■ Mandatory (PDF) |
| address | string(255) | | ■ Mandatory (PDF) |
| google_maps_url | string(255) | nullable | ■ Mandatory (PDF) |
| contact_number | string(20) | nullable | ■ Mandatory (PDF) |
| city_id | FK → cities | nullOnDelete | — |
| photos | json | nullable | Optional (PDF) |
| booking_available | boolean | default false | Optional (PDF) |
| pricing | string(120) | nullable | Optional (PDF) |
| facilities | json | nullable | Optional (PDF) |
| working_hours | string(120) | nullable | Optional (PDF) |
| listing_status | enum('draft','published','closed','expired','removed') | default 'draft' | System |
| softDeletes | | | |

**Indexes:** `(listing_status, city_id)`, `(sport_id, city_id, status)`.
**Reuses:** T1 directory list template and T2 detail template.
**Added to:** `saved_items.morphs`, `listing_reports.morphs`, universal search categories, and admin content management.

---

## 13. Reminder Scheduling

### `reminder_subscriptions`

| id | user_id FK cascade | reminderable_type string — morphs (trial/tournament/scholarship) | reminderable_id bigint | remind_at timestamp index | sent_at timestamp nullable |

**Unique:** `(user_id, reminderable_type, reminderable_id)` — created by Save-with-reminder, reminder toggle (A15), or scholarship save. *(Consolidated AS-10: wireframes imply several reminder entry points; one subscription table serves all.)*

---

## 14. Migration Order (build sequence)

1. `users`, `otp_codes`, `admin_profiles`
2. `sports`, `cities`, `age_groups`
3. `media_items` (no FKs to profiles)
4. `athlete_profiles`, `athlete_sports`, `achievements`
5. `coach_profiles`, `academies`, `academy_sports`, `academy_coaches`, `organizer_profiles`, `sponsor_profiles`
6. `sports_venues` (new — PDF entity)
7. `trials`, `trial_registrations`, `trial_registration_documents`
8. `tournaments`, `tournament_categories`, `tournament_registrations`, `tournament_results`
9. `scholarships`, `sponsorships`, `sponsorship_applications`, `shortlist_entries`
10. `enquiries`, `enquiry_messages`, `saved_items`, `listing_reports`, `notifications`
11. `expiry_rules`, `expiry_events`, `reminder_subscriptions`

> FK note: `athlete_profiles.photo_media_id` / `academies.cover_media_id` / `sponsor_profiles.logo_media_id` require `media_items` before profile tables (step 3 before 4–5) or nullable FK added in a later migration.

---

## 16. Query Hotspots (index rationale)

| Hotspot screen/query | Tables & indexes used |
|---|---|
| Academy/Coach/Trial/Sports Venue directory with filters (S7/S8) | `academies/coach_profiles/trials/sports_venues (listing_status/status, city_id)`, sport via join tables |
| Trials closing soon (A3) | `trials(status, event_datetime)` range scan |
| Tournament calendar month view (A16) | `tournaments(status, start_date)` |
| My Activity tabs (A24) | `trial_registrations(athlete_id,…)`, `tournament_registrations`, `sponsorship_applications(athlete_id, status)` |
| Enquiry inboxes (T4) | `enquiries(subject_type, subject_id, updated_at)` |
| Moderation queue (AD6) | `listing_reports(status, created_at)` + count group-by |
| Expiry sweep | `trials/tournaments/sponsorships (status, expires_at)` + `expiry_events(status, scheduled_at)` |
| Universal search (S6) | Per-type queries + optional fulltext; merged at service layer (search engine is an enhancement, AS-11) |

---

## 17. Seed Data Scope

Minimum admin-seeded data required for the app to function on day one (since admin UI is phased and scholarships are admin-only):

- `sports`: Cricket, Football, Badminton, Athletics, Swimming (+ admin-extensible) — matches trending chips in S6.
- `cities`: launch city set (e.g. Ahmedabad, Surat; assumption AS-14 — launch cities unspecified).
- `age_groups`: Under-10, Under-12, Under-14, Under-16, Under-18, Open — per A1/S8 options.
- `expiry_rules`: trial = 1 day after event date; tournament = 3 days after final date; sponsorship/scholarship = on listed deadline (AD8 defaults from wireframe).
- `scholarships`: initial curated set (admin CRUD until admin UI ships).
