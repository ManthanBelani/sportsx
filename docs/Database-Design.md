# Database Design — SportX India

Physical schema matching **Laravel migration structure** (Blueprint-style definitions). Logical model: see `ER-Diagram.md`.

> **⚠️ SYNCED TO THE NEW DESIGN (v3).** This document reflects `sportsx-design-v3/new_design_docs/SportX_Mandatory_Fields.md` (30 profile fields per role) and `docs/Backend-Feature-Delta.md` (the change delta vs the old spec). Where the old schema was superseded it is marked **[CHANGED]** / **[NEW]** / **[REMOVED]** / **[P1]**.
>
> **Conventions & global decisions**
> - **Engine:** MySQL 8 / MariaDB 10.6+ assumed (AS-02). PostgreSQL-compatible with minor type adjustments (`json`→`jsonb`, enums→check constraints).
> - Every table gets: `id()` (bigint PK), `timestamps()` (created_at/updated_at). `softDeletes()` only where user-facing records must be removable without losing history (noted per table).
> - Status fields on listings share the enum set: `draft`, `published`, `closed`, `expired`, `removed`.
> - "Fee" columns are `string` (display-only, e.g. `"₹2000–₹5000/mo"`) because **no payment processing exists**. `opportunities.amount` is numeric since it's a single figure to display/sort by.
> - All FKs `constrained()` with `cascadeOnDelete()` for owned children, `nullOnDelete()` for optional references.
> - **Mandatory/Optional** labels match `SportX_Mandatory_Fields.md`. Mandatory fields are marked `■ Mandatory`; optional (`🟠 High` / `🟢 Medium`) fields are nullable or have defaults.
> - **[CHANGED] Role model:** `athlete`, `coach`, `academy`, `organizer`, `scout`, `admin`. The old `sponsor` role is **REMOVED** (sponsorship is now an `opportunities.type`). See §4.

---

## 1. Identity & Auth

### `users` **[CHANGED]**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint unsigned | PK, auto | |
| role | enum('athlete','coach','academy','organizer','scout','admin') | index | Fixed at sign-up (A.2). **sponsor removed, scout added** |
| name | string(100) | | Display name |
| email | string(190) | unique, nullable | Set when signup uses email channel |
| email_verified_at | timestamp | nullable | Set by OTP verify (A.4) |
| phone | string(20) | nullable, unique, index | Set when signup uses phone channel |
| phone_verified_at | timestamp | nullable | Set by OTP verify (A.4) **[NEW]** |
| password | string(255) | nullable | bcrypt/argon hash; nullable for OTP/Google-only accounts |
| google_id | string(64) | nullable, unique | "Continue with Google" (A.3) — **confirm P0 (D9)** |
| status | enum('pending','active','suspended','banned','deleted') | default 'active' | 'pending' for OTP/guardian gated; banned for admin (AD.3) |
| profile_visibility | enum('public','connections','private') | default 'public' | **[NEW]** privacy enforcement (AT.10/S.22) |
| who_can_message | enum('everyone','connections','nobody') | default 'connections' | **[NEW]** |
| who_can_connect | enum('everyone','nobody') | default 'everyone' | **[NEW]** |
| language | string(8) | default 'en' | A.7 language selection |
| remember_token | string(100) | nullable | |
| social_links | json | nullable | **[NEW]** social/professional links default (per-role copies too) |
| two_factor_secret | string(255) | nullable | Admin 2FA (existing migration) |
| is_phone_login | boolean | default false | Account can log in with phone+OTP |

**Indexes:** `role`, `status`, composite `(role, status)`, `phone`.

### `otp_codes` **[CHANGED — re-enabled for P0]**

> The OTP stack is restored to MVP (D1). Supports both **email** and **phone** channels.

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| user_id | FK → users | nullable, cascadeOnDelete (null for pre-registration OTP) |
| purpose | enum('signup','login','reset_password','guardian_consent','verify_contact') | index, default 'login' |
| channel | enum('email','phone') | index |
| destination | string(190) | The address/number the code was sent to |
| code_hash | string(255) | Hashed 6-digit code — never stored plain |
| expires_at | timestamp | index for purge job |
| attempts | unsignedTinyInteger | default 0 (max 5) |
| resend_available_at | timestamp | nullable | 60s cooldown |
| consumed_at | timestamp | nullable |

**Index:** `(destination, purpose, created_at)`, `(user_id, channel, created_at)`.

### `guardian_consents` **[NEW]**

> Closes AS-34: any athlete with DOB < 18 must have a verified guardian consent before profile activation (A.9 / AT.10).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| athlete_user_id | FK → users | cascade, unique | The minor account |
| guardian_name | string(100) | | |
| guardian_phone | string(20) | index | OTP sent here |
| relationship | enum('parent','guardian','sibling','other') | | |
| consent_status | enum('pending','verified','revoked') | default 'pending', index | |
| verified_at | timestamp | nullable | |
| allow_messages | boolean | default true | Parent control |
| allow_public_profile | boolean | default false | Parent control |
| leaderboard_name_mode | enum('full','initials','hidden') | default 'initials' | Minor anonymization |
| revoked_at | timestamp | nullable | |

### `verification_requests` **[NEW]**

> Drives the A.10 request + AD.4 admin queue + profile badge.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| requester_user_id | FK → users | cascade | |
| requestable_type | string | morphs: athlete_profile/coach_profile/academy/organizer_profile/talent_scout_profile |
| requestable_id | bigint | | |
| id_proof_media_id | FK → media_items | nullable, nullOnDelete | Private (signed URLs) |
| org_proof_media_id | FK → media_items | nullable, nullOnDelete | Private |
| note | text | nullable | Applicant note |
| status | enum('pending','approved','rejected') | default 'pending', index | |
| reviewed_by | FK → users (admin) | nullable, nullOnDelete | |
| review_reason | text | nullable | Required on reject |
| reviewed_at | timestamp | nullable | |

**Index:** `(status, created_at)`, `(requestable_type, requestable_id)`.

### `admin_profiles`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| user_id | FK → users | unique, cascadeOnDelete |
| two_factor_secret | string(255) | nullable until enrolled |
| is_super_admin | boolean | default false (AS-13) |

---

## 2. Master Data (admin-managed, AD10–12)

### `sports`

| id | name string(60) unique | is_active boolean default true | sort_order unsignedSmallInteger default 0 |

### `cities`

| id | name string(100) | state string(100) | is_active boolean |

**Index:** unique `(name, state)`; index `state`.

### `age_groups`

| id | name string(30) unique | min_age nullable tinyint | max_age nullable tinyint | is_active boolean |

### `positions` **[NEW]**

> Powers the athlete Position filter (S.4) and mandatory "Position/Event" field.

| id | sport_id FK → sports nullable, nullOnDelete | name string(60) | is_active boolean default true | sort_order unsignedSmallInteger default 0 |

**Unique:** `(sport_id, name)`. **Index:** `sport_id`.

---

## 3. Media

### `media_items` (shared) **[CHANGED]**

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| owner_type | string | morphs index — athlete_profile / coach_profile / academy / organizer_profile / talent_scout_profile / generalized_profile / trial_registration / **post** / **program** / **facility** / **event** / **achievement** |
| owner_id | bigint | |
| media_type | enum('photo','video','document') | |
| disk | string(30) default 's3' | Object storage (NFR-4) |
| path | string(255) | |
| original_name | string(190) | nullable |
| mime_type | string(80) | |
| size_bytes | unsignedInteger | |
| caption | string(255) | nullable — **[NEW] (S.9/S.28)** |
| sport_id | FK → sports | nullable — **[NEW] sport tag** |
| sort_order | smallint | default 0 |

**Index:** `(owner_type, owner_id, sort_order)`. softDeletes.

---

## 4. Profiles (30 fields per role — `SportX_Mandatory_Fields.md`)

### `athlete_profiles` **[CHANGED — 30 fields]**

| Column | Type | Constraints | Field # / Priority |
|---|---|---|---|
| id | bigint PK | | — |
| user_id | FK → users | unique, cascadeOnDelete | — |
| full_name | string(100) | | 1 ■ Mandatory |
| date_of_birth | date | index | 6 ■ Mandatory (age/age group) |
| gender | enum('male','female','other','prefer_not_to_say') | | 6 ■ Mandatory |
| age_group_id | FK → age_groups | nullOnDelete | 6 ■ Mandatory |
| skill_level | enum('beginner','intermediate','advanced','competitive') | | 7 ■ Mandatory |
| city_id | FK → cities | nullOnDelete | 5 ■ Mandatory (city/state) |
| bio | text | nullable | 8 ■ Mandatory (short bio) |
| photo_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| phone | string(20) | nullable | Optional |
| academy_id | FK → academies | nullable, nullOnDelete | 9 🟠 current team/academy |
| team_name | string(120) | nullable | 9 🟠 team name |
| coach_id | FK → coach_profiles | nullable, nullOnDelete | 10 🟠 coach |
| competition_history | json | nullable | 12 🟠 |
| performance_stats | json | nullable | 13 🟠 (matches, runs, avg…) |
| personal_best | string(120) | nullable | 14 🟠 |
| experience_years | unsignedTinyInteger | nullable | 16 🟠 |
| training_centre | string(150) | nullable | 17 🟠 |
| playing_hand | enum('right','left','both') | nullable | 18 🟠 |
| height_cm | unsignedSmallInteger | nullable | 19 🟠 |
| weight_kg | unsignedSmallInteger | nullable | 20 🟢 |
| goals | json | nullable | 22 🟠 athlete goals |
| open_to | json | nullable | 23 🟠 (trials, tournaments, scholarships, teams, sponsorships, academy admission) |
| availability | json | nullable | 24 🟠 (days + morning/afternoon/evening) |
| relocation_preference | enum('local','state','national','international') | nullable | 25 🟢 |
| education | string(150) | nullable | 26 🟢 |
| sponsorship_interest | boolean | default false | 29 🟢 |
| social_links | json | nullable | 30 🟢 |
| verification_status | enum('unverified','pending','verified','rejected') | default 'unverified' | 28 🟢 |
| listing_status | enum('draft','published','closed','removed') | default 'draft' | System |
| profile_completeness | tinyint unsigned | default 0 | System |

**Index:** `(listing_status, city_id)`, `(skill_level, city_id)`, fulltext `(bio)`.
**Field 15 (Certificates) / 21 (Photos & Videos):** via `media_items` morph + `achievements.certificate_media_id`.

### `athlete_sports` **[CHANGED — extended pivot]**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| athlete_id | FK → athlete_profiles | cascade | |
| sport_id | FK → sports | restrict | Field 3 primary / 27 additional |
| position_id | FK → positions | nullable, nullOnDelete | Field 4 (position/event) **[NEW]** |
| playing_role | string(60) | nullable | Field 4 (e.g. "Batsman (Right Hand)") **[NEW]** |
| level | enum('beginner','intermediate','advanced','competitive') | nullable | Field 7 per-sport **[NEW]** |
| experience_years | unsignedTinyInteger | nullable | Field 16 per-sport **[NEW]** |
| is_primary | boolean | default false | Field 3 primary flag **[NEW]** |

**Unique:** `(athlete_id, sport_id)`.

### `achievements` **[CHANGED — typed records]**

> Covers athlete field 11/15 and coach field 20 (owner morph).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| owner_type | string | morphs: athlete_profile / coach_profile | **[NEW]** |
| owner_id | bigint | | **[NEW]** |
| title | string(190) | | Field 11 |
| achievement_type | enum('tournament','award','selection','record','certification','other') | nullable | **[NEW]** |
| sport_id | FK → sports | nullable, nullOnDelete | **[NEW]** |
| level | string(60) | nullable | e.g. State / National **[NEW]** |
| year | unsignedSmallInteger | nullable | **[NEW]** |
| description | text | nullable | |
| certificate_media_id | FK → media_items | nullable, nullOnDelete | Field 15 **[NEW]** |
| sort_order | smallint | default 0 | |

**Index:** `(owner_type, owner_id, year)`.

### `coach_profiles` **[CHANGED — 30 fields]**

| Column | Type | Constraints | Field # / Priority |
|---|---|---|---|
| id | bigint PK | | — |
| user_id | FK → users | unique, cascadeOnDelete | — |
| full_name | string(100) | | 1 ■ Mandatory |
| photo_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| city_id | FK → cities | nullOnDelete | 6 ■ Mandatory |
| coaching_level | enum('grassroots','youth','state','professional') | | 5 ■ Mandatory |
| bio | text | nullable | 7 ■ Mandatory |
| experience_years | unsignedTinyInteger | | 8 ■ Mandatory |
| specializations | json | nullable | 4 ■ Mandatory (batting, fitness…) |
| coaching_role | enum('head_coach','assistant_coach','trainer','other') | nullable | 9 🟠 |
| academy_id | FK → academies | nullable, nullOnDelete | 10 🟠 |
| organization_name | string(150) | nullable | 10 🟠 |
| certifications | json | nullable | 11 🟠 |
| teams_coached | json | nullable | 12 🟠 |
| age_groups_coached | json | nullable | 13 🟠 |
| levels_coached | json | nullable | 14 🟠 |
| expertise | json | nullable | 15 🟠 |
| services | json | nullable | 17 🟠 (individual, group, online…) |
| availability | json | nullable | 18 🟠 |
| training_locations | json | nullable | 19 🟠 |
| coaching_achievements | json | nullable | 20 🟠 (also achievements owner=coach) |
| athletes_coached_summary | string(190) | nullable | 21 🟠 |
| philosophy | text | nullable | 23 🟢 |
| fee_structure | string(120) | nullable | 24 🟢 |
| open_to | json | nullable | 25 🟢 |
| relocation_preference | enum('local','state','national','international') | nullable | 26 🟢 |
| education | string(150) | nullable | 27 🟢 |
| social_links | json | nullable | 30 🟢 |
| contact_number | string(20) | nullable | Contact |
| email | string(190) | nullable | Contact |
| verification_status | enum('unverified','pending','verified','rejected') | default 'unverified' | 29 🟢 |
| listing_status | enum('draft','published','closed','removed') | default 'draft' | System |
| profile_completeness | tinyint unsigned | default 0 | System |

**Index:** `(listing_status, city_id)`, fulltext `(bio)`.
**Field 3 (Primary Sport(s)):** via `coach_sports`. **Field 16 (Training Programs):** via `programs`. **Field 22:** media_items. **Field 28:** reviews.

### `coach_sports` **[NEW]**

| id | coach_id FK → coach_profiles cascade | sport_id FK → sports restrict | is_primary boolean default false |

**Unique:** `(coach_id, sport_id)`.

### `academies` **[CHANGED — 30 fields]**

| Column | Type | Constraints | Field # / Priority |
|---|---|---|---|
| id | bigint PK | | — |
| owner_user_id | FK → users | cascade | — |
| name | string(150) | | 1 ■ Mandatory |
| logo_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| cover_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| academy_type | enum('private','club','school','college','government') | | 4 ■ Mandatory |
| city_id | FK → cities | nullOnDelete | 5 ■ Mandatory |
| description | text | | 6 ■ Mandatory |
| training_offered | json | nullable | 7 ■ Mandatory (batting, bowling…) |
| age_groups | json | nullable | 8 ■ Mandatory (U-6 to Senior) |
| address | string(255) | | 14 🟠 / location |
| google_maps_url | string(255) | nullable | 14 🟠 |
| year_established | smallint unsigned | nullable | 11 🟠 |
| facilities_summary | json | nullable | 12 🟠 (mirrors `facilities` table) |
| training_schedule | string(190) | nullable | 13 🟠 |
| fee_range | string(60) | nullable | 15 🟠 |
| admission_process | text | nullable | 16 🟠 |
| achievements | json | nullable | 17 🟠 |
| athletes_developed | string(190) | nullable | 18 🟠 |
| competitions | json | nullable | 19 🟠 |
| head_name | string(120) | nullable | 26 🟢 |
| head_designation | string(120) | nullable | 26 🟢 |
| certifications | json | nullable | 27 🟢 |
| financial_aid | text | nullable | 28 🟢 |
| accommodation | boolean | default false | 29 🟢 |
| transport | boolean | default false | 29 🟢 |
| contact_number | string(20) | nullable | 23 🟠 |
| email | string(190) | nullable | 23 🟠 |
| whatsapp | string(20) | nullable | 23 🟠 |
| website | string(255) | nullable | 24 🟢 |
| social_links | json | nullable | 24 🟢 |
| verification_badge | boolean | default false | 22 🟠 |
| verification_status | enum('unverified','pending','verified','rejected') | default 'unverified' | 22 🟠 |
| listing_status | enum('draft','published','closed','expired','removed') | default 'draft' | System |
| profile_completeness | tinyint unsigned | default 0 | System |

**Index:** `(listing_status, city_id)`, `(academy_type, city_id)`.
**Field 3:** `academy_sports`. **Field 9/20:** `programs` / `trials`. **Field 10:** `academy_coaches`. **Field 12:** `facilities` table. **Field 21:** media_items. **Field 25:** reviews. **Field 30:** opportunities.

### `academy_sports` — id, academy_id FK cascade, sport_id FK, is_primary boolean; unique `(academy_id, sport_id)`.

### `academy_coaches`

| id | academy_id FK cascade | coach_user_id FK→users nullable | display_name string(100) nullable | *coach_user_id set when linked (AS-12); display_name fallback* |

### `facilities` **[NEW — replaces `academies.facilities` JSON]**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| academy_id | FK → academies | cascade | |
| name | string(150) | | |
| facility_type | enum('ground','indoor','gym','court','pool','other') | index | AC.7 tabs |
| size_spec | string(120) | nullable | size / lanes |
| amenities | json | nullable | parking, changing room, water… |
| media | json | nullable | image ids |
| sort_order | smallint | default 0 | |

**Index:** `(academy_id, facility_type)`.

### `organizer_profiles` **[CHANGED — 30 fields]**

| Column | Type | Constraints | Field # / Priority |
|---|---|---|---|
| id | bigint PK | | — |
| user_id | FK → users | unique, cascadeOnDelete | — |
| organization_name | string(150) | | 1 ■ Mandatory |
| logo_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| cover_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| org_type | enum('event_company','individual','club','college','federation','ngo','other') | | 3 ■ Mandatory |
| city_id | FK → cities | nullOnDelete | 6 ■ Mandatory |
| description | text | nullable | 7 ■ Mandatory |
| event_types | json | nullable | 5 ■ Mandatory (tournament, trial, camp…) |
| experience_years | unsignedTinyInteger | nullable | 8 🟠 |
| events_history | json | nullable | 9 🟠 |
| competition_levels | json | nullable | 10 🟠 |
| registration_mode | enum('individual','team','both') | nullable | 12 🟠 |
| eligibility_criteria | text | nullable | 13 🟠 |
| participants_summary | string(190) | nullable | 17 🟠 |
| venue_amenities | json | nullable | 18 🟠 |
| achievements | json | nullable | 21 🟠 |
| partners | json | nullable | 25 🟢 |
| sponsors | json | nullable | 26 🟢 |
| contact_person_name | string(120) | nullable | 30 🟢 |
| contact_person_designation | string(120) | nullable | 30 🟢 |
| contact_number | string(20) | nullable | 22 🟠 |
| email | string(190) | nullable | 22 🟠 |
| whatsapp | string(20) | nullable | 22 🟠 |
| website | string(255) | nullable | 29 🟢 |
| social_links | json | nullable | 29 🟢 |
| verification_status | enum('unverified','pending','verified','rejected') | default 'unverified' | 23 🟠 |
| listing_status | enum('draft','published','closed','removed') | default 'draft' | System |
| profile_completeness | tinyint unsigned | default 0 | System |

**Field 4:** organizer_sports pivot. **Field 11:** tournaments/trials. **Fields 14–20:** per-event. **Field 21:** events/achievements. **Field 24:** media_items. **Field 27:** opportunities. **Field 28:** reviews.

### `organizer_sports` **[NEW]** — id, organizer_id FK cascade, sport_id FK, is_primary boolean; unique `(organizer_id, sport_id)`.

### `talent_scout_profiles` **[CHANGED — 30 fields]**

> Was `scout_profiles` in the delta; canonical table name `talent_scout_profiles` (existing migration). One-to-one with a `scout` user.

| Column | Type | Constraints | Field # / Priority |
|---|---|---|---|
| id | bigint PK | | — |
| user_id | FK → users | unique, cascadeOnDelete | — |
| full_name | string(100) | | 1 ■ Mandatory |
| photo_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| cover_media_id | FK → media_items | nullable, nullOnDelete | 2 ■ Mandatory |
| scout_type | enum('independent','club','academy','federation') | | 3 ■ Mandatory |
| specializations | json | nullable | 5 ■ Mandatory (batting, bowling…) |
| city_id | FK → cities | nullOnDelete | 6 ■ Mandatory |
| bio | text | nullable | 7 ■ Mandatory |
| experience_years | unsignedTinyInteger | nullable | 8 🟠 |
| scouting_level | enum('grassroots','school','college','club','district','state','national','professional') | nullable | 9 🟠 |
| age_groups_scouted | json | nullable | 10 🟠 |
| organization_name | string(150) | nullable | 11 🟠 |
| previous_organizations | json | nullable | 12 🟠 |
| certifications | json | nullable | 13 🟠 |
| scouting_methods | json | nullable | 14 🟠 |
| evaluation_areas | json | nullable | 15 🟠 |
| athletes_scouted | string(190) | nullable | 16 🟠 |
| discoveries | text | nullable | 17 🟠 |
| scouting_achievements | json | nullable | 18 🟠 |
| regions | json | nullable | 19 🟠 |
| events_covered | json | nullable | 20 🟠 |
| services | json | nullable | 21 🟠 |
| recruitment_focus | json | nullable | 22 🟠 |
| affiliations | json | nullable | 27 🟢 |
| availability | enum('available','limited','unavailable') | default 'available' | 28 🟢 |
| fee_structure | string(120) | nullable | 30 🟢 |
| website | string(255) | nullable | 29 🟢 |
| social_links | json | nullable | 29 🟢 |
| verification_status | enum('unverified','pending','verified','rejected') | default 'unverified' | 26 🟢 |
| listing_status | enum('draft','published','closed','removed') | default 'draft' | System |
| profile_completeness | tinyint unsigned | default 0 | System |

**Field 4:** talent_scout_sports pivot. **Field 23:** `scout_reports`. **Field 24:** media_items. **Field 25:** reviews.

### `talent_scout_sports` **[NEW]** — id, scout_id FK cascade, sport_id FK restrict, is_primary boolean; unique `(scout_id, sport_id)`.

### `generalized_profiles` **[NEW]**

> Section 6 of `SportX_Mandatory_Fields.md` — covers NGO, Doctor, Physiotherapist, Sports Store, Brand, Nutritionist, Journalist, Agent, Federation, Facility, School/College, Sports Media, Event Company, Photographer, Psychologist, Government Body, etc. These are **not login roles** — they are directory profiles linked to a user account (created via a generic provider onboarding or seeded/admin-created).

| Column | Type | Constraints | Field # / Priority |
|---|---|---|---|
| id | bigint PK | | — |
| user_id | FK → users | nullable, nullOnDelete | — |
| category | string(60) | index | 1 ■ Mandatory (NGO, doctor…) |
| name | string(150) | | 2 ■ Mandatory |
| logo_media_id | FK → media_items | nullable, nullOnDelete | 3 ■ Mandatory |
| cover_media_id | FK → media_items | nullable, nullOnDelete | 3 ■ Mandatory |
| description | text | | 4 ■ Mandatory |
| city_id | FK → cities | nullOnDelete | 8 ■ Mandatory |
| specialization | string(190) | nullable | 6 ■ Mandatory |
| contact_number | string(20) | nullable | 11 ■ Mandatory |
| email | string(190) | nullable | 11 ■ Mandatory |
| whatsapp | string(20) | nullable | 11 ■ Mandatory |
| services | json | nullable | 18 ■ Mandatory |
| target_audience | json | nullable | 7 🟠 |
| service_area | enum('local','district','state','national','international') | nullable | 9 🟠 |
| contact_person_name | string(120) | nullable | 12 🟠 |
| contact_person_designation | string(120) | nullable | 12 🟠 |
| website | string(255) | nullable | 13 🟠 |
| social_links | json | nullable | 13 🟠 |
| organization_type | string(60) | nullable | 14 🟠 |
| year_established | smallint unsigned | nullable | 15 🟠 |
| founder_name | string(120) | nullable | 16 🟠 |
| products | json | nullable | 19 🟠 |
| programs | json | nullable | 20 🟠 |
| professional_qualifications | json | nullable | 21 🟠 |
| certifications | json | nullable | 22 🟠 |
| professional_experience | text | nullable | 23 🟠 |
| achievements | json | nullable | 24 🟠 |
| branches | json | nullable | 10 🟢 |
| staff | json | nullable | 17 🟢 |
| work_history | json | nullable | 25 🟢 |
| documents | json | nullable | 27 🟢 (private) |
| availability | enum('available','limited','unavailable') | default 'available' | 28 🟢 |
| service_mode | enum('online','offline','both','home_visit') | nullable | 29 🟢 |
| partnerships | json | nullable | 30 🟢 |
| pricing | string(120) | nullable | ➕ |
| verification_status | enum('unverified','pending','verified','rejected') | default 'unverified' | 26 🟠 |
| listing_status | enum('draft','published','closed','removed') | default 'draft' | System |
| profile_completeness | tinyint unsigned | default 0 | System |

**Index:** `(category, listing_status, city_id)`. **Field 5:** generalized_profile_sports pivot (add table if multi-sport needed).

---

## 5. Programs & Facilities

### `programs` **[NEW]**

> Coach field 16 / Academy field 9. Training program listings (CO.4/CO.5/AC.4/D.11).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| owner_type | string | morphs: coach_profile / academy | |
| owner_id | bigint | | |
| sport_id | FK → sports | restrict | |
| title | string(150) | | |
| age_group | string(60) | nullable | |
| duration | string(60) | nullable | e.g. "6 months" |
| mode | enum('online','offline','hybrid') | default 'offline' | |
| price | string(60) | nullable | display-only |
| schedule | string(190) | nullable | |
| about | text | nullable | |
| status | enum('draft','active','past','removed') | default 'draft', index | |
| softDeletes | | | |

**Index:** `(owner_type, owner_id, status)`, `(sport_id, status)`.

---

## 6. Events — Trials, Tournaments & Camps

> **Decision (Backend-Feature-Delta §8 D2):** keep `trials` + `tournaments` tables; unify at the API/resource layer with an event `type`. Camps are tournaments/trials with `category=camp` (or a `type` column added below).

### `trials` **[CHANGED]**

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| posted_by_user_id | FK → users | cascade | — |
| academy_id | FK → academies | nullable, nullOnDelete | — |
| name | string(150) | | ■ Mandatory |
| organization_name | string(150) | nullable | ■ Mandatory |
| sport_id | FK → sports | restrict | ■ Mandatory |
| position_id | FK → positions | nullable, nullOnDelete | **[NEW]** |
| event_datetime | timestamp | index | ■ Mandatory |
| venue | string(190) | | ■ Mandatory |
| google_maps_url | string(255) | nullable | ■ Mandatory |
| city_id | FK → cities | nullOnDelete | — |
| contact_number | string(20) | | ■ Mandatory |
| registration_deadline | timestamp | nullable, index | ■ Mandatory |
| eligibility | text | nullable | Optional |
| required_documents | json | nullable | Optional |
| vacancies | smallint unsigned | nullable | Optional |
| benefits | text | nullable | Optional |
| entry_fee | string(60) | nullable | Optional |
| status | enum('draft','published','closed','expired','removed') | default 'draft', index | System |
| expires_at | timestamp | nullable, index | System |
| softDeletes | | | |

**Indexes:** `(status, event_datetime)`, `(status, expires_at)`, `(sport_id, city_id, status)`, `(posted_by_user_id, status)`.

### `trial_registrations` **[CHANGED]**

| id | trial_id FK cascade | athlete_id FK→athlete_profiles cascade | registration_ref string(20) unique (AS-08) | document_status enum('pending','submitted') | verification_status enum('pending','approved','rejected') default 'pending' | reminder_enabled boolean | softDeletes |

**Unique:** `(trial_id, athlete_id)`. **Index:** `(athlete_id, verification_status)`.

### `trial_registration_documents` — id, trial_registration_id FK cascade, document_type string(60), media_item_id FK cascade, status enum('uploaded','rejected').

### `tournaments` **[CHANGED]**

| Column | Type | Constraints | Mandatory? |
|---|---|---|---|
| id | bigint PK | | — |
| organizer_id | FK → organizer_profiles | cascade | — |
| sport_id | FK → sports | restrict | ■ Mandatory |
| name | string(150) | | ■ Mandatory |
| organizer_name | string(150) | nullable | ■ Mandatory |
| format | string(40) | nullable | — (AS-09) |
| event_type | enum('tournament','championship','league','camp','workshop','sports_meet','marathon','other') | default 'tournament' | **[NEW] (organizer field 5)** |
| start_date | date | | ■ Mandatory |
| end_date | date | nullable | ■ Mandatory |
| registration_deadline | date | nullable, index | ■ Mandatory |
| venue | string(190) | | ■ Mandatory |
| google_maps_url | string(255) | nullable | ■ Mandatory |
| city_id | FK → cities | nullOnDelete | — |
| entry_fee | string(60) | nullable | ■ Mandatory |
| contact_number | string(20) | nullable | ■ Mandatory |
| registration_link | string(255) | nullable | ■ Mandatory (external link) |
| prize_pool | string(60) | nullable | Optional |
| rules | text | nullable | Optional |
| banner_media_id | FK → media_items | nullable, nullOnDelete | Optional |
| gender | enum('male','female','mixed','open') | nullable | Optional |
| status | enum('draft','published','closed','expired','removed') | | System |
| expires_at | timestamp | nullable | System |
| softDeletes | | | |

**Indexes:** `(status, start_date)`, `(sport_id, city_id, status)`, `(organizer_id, status)`.

### `tournament_categories` — id, tournament_id FK cascade, age_group_id FK restrict, name string(60), capacity unsignedSmallInteger, waitlist_enabled boolean. Unique `(tournament_id, age_group_id)`.

### `tournament_registrations`

| id | tournament_id FK cascade | category_id FK cascade | athlete_id FK cascade | participation_type enum('individual','team') | team_name string(120) | payment_status enum('pending','paid') (manual flag only) | status enum('pending','confirmed','waitlisted','cancelled') | softDeletes |

**Unique:** `(tournament_id, category_id, athlete_id)`.

### `tournament_results` — id, tournament_id FK cascade, category_id FK cascade, place tinyint, winner_name string(150), bracket_media_id FK nullable, published_at timestamp nullable. Unique `(category_id, place)`.

### `event_schedules` **[NEW — P1]**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| schedulable_type | string | morphs: trial / tournament | |
| schedulable_id | bigint | | |
| day | date | index | |
| slot_label | string(120) | nullable | |
| start_time | time | nullable | |
| end_time | time | nullable | |
| venue | string(190) | nullable | |
| sort_order | smallint | default 0 | |

**Index:** `(schedulable_type, schedulable_id, day)`.

### `event_views` **[NEW — P1]**

| id | viewable_type string (trial/tournament) | viewable_id bigint | user_id FK nullable | source string(60) nullable | created_at |

**Index:** `(viewable_type, viewable_id, created_at)`.

---

## 7. Opportunities & Applications **[NEW — replaces scholarships/sponsorships]**

> **Biggest structural change (D2/D3).** Sponsorship + scholarship collapse into one `opportunities` table with a `type` enum; any provider (academy/organizer/coach/scout) posts them; athletes apply in-app with a pitch and track status (AT.8). Complete sponsor role removal is in §15.

### `opportunities`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| provider_type | string | morphs: academy / organizer_profile / coach_profile / talent_scout_profile / user(admin) | |
| provider_id | bigint | | |
| type | enum('scholarship','sponsorship','tryout','camp') | index | |
| title | string(150) | | |
| sport_id | FK → sports | nullable, restrict | |
| organization_name | string(150) | nullable | |
| eligibility | text | nullable | |
| benefits | text | nullable | |
| amount | decimal(12,2) | nullable | |
| currency | char(3) | default 'INR' | |
| location | string(190) | nullable | |
| deadline | date | index | |
| documents_required | json | nullable | |
| description | text | nullable | |
| logo_media_id | FK → media_items | nullable, nullOnDelete | |
| status | enum('draft','published','closed','expired','removed') | default 'draft', index | |
| posted_by_admin | boolean | default false | legacy admin-exclusive schemes (D6) |
| expires_at | timestamp | nullable, index | |
| softDeletes | | | |

**Indexes:** `(status, deadline)`, `(type, sport_id, status)`, `(provider_type, provider_id, status)`.

### `opportunity_applications`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| opportunity_id | FK → opportunities | cascade | |
| athlete_id | FK → athlete_profiles | cascade | |
| pitch | text | nullable | in-app application pitch |
| documents | json | nullable | uploaded docs |
| profile_snapshot | json | nullable | captured at apply time |
| status | enum('submitted','shortlisted','rejected','accepted') | default 'submitted', index | |
| reviewed_by | FK → users | nullable, nullOnDelete | |
| review_note | text | nullable | **[NEW] P1 review** |
| replied_at | timestamp | nullable | |
| softDeletes | | | |

**Unique:** `(opportunity_id, athlete_id)`. **Index:** `(athlete_id, status)`, `(opportunity_id, status)`.

---

## 8. Social Feed **[NEW]**

### `posts`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| author_user_id | FK → users | cascade | author morph resolvable via user role |
| body | text | nullable | text content |
| media | json | nullable | media ids / urls |
| hashtags | json | nullable | extracted tags |
| sport_id | FK → sports | nullable, nullOnDelete | sport tag |
| audience | enum('public','followers','connections') | default 'public' | |
| likes_count | unsignedInteger | default 0 | denormalized |
| comments_count | unsignedInteger | default 0 | denormalized |
| status | enum('published','removed') | default 'published' | moderation |
| softDeletes | | | |

**Index:** `(status, created_at)`, `(author_user_id, created_at)`, `(sport_id, created_at)`.

### `post_likes`

| id | post_id FK cascade | user_id FK cascade | created_at | **Unique:** `(post_id, user_id)`.

### `post_comments`

| id | post_id FK cascade | user_id FK cascade | parent_id FK→post_comments nullable | body text | status enum('published','removed') | softDeletes |

**Index:** `(post_id, created_at)`.

---

## 9. Network & Messaging **[NEW]**

### `follows` (one-way)

| id | follower_user_id FK cascade | followable_type string (athlete_profile/coach_profile/academy/organizer_profile/talent_scout_profile) | followable_id bigint | created_at |

**Unique:** `(follower_user_id, followable_type, followable_id)`. **Index:** `(followable_type, followable_id)`.

### `connection_requests` (mutual, request→accept)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| requester_user_id | FK → users | cascade | |
| addressee_user_id | FK → users | cascade | |
| purpose | string(120) | nullable | scout contact purpose (SC.13) |
| message | text | nullable | |
| status | enum('pending','accepted','declined','cancelled','removed') | default 'pending', index | |
| responded_at | timestamp | nullable | |

**Unique:** `(requester_user_id, addressee_user_id)`. **Index:** `(addressee_user_id, status)`.

### `conversations`

| id | bigint PK | last_message_at timestamp nullable index | created_at | updated_at |

### `conversation_participants`

| id | conversation_id FK cascade | user_id FK cascade | last_read_at timestamp nullable | **Unique:** `(conversation_id, user_id)`.

### `messages`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| conversation_id | FK → conversations | cascade | |
| sender_user_id | FK → users | cascade | |
| body | text | nullable | text P0 |
| attachments | json | nullable | media P1 |
| read_at | timestamp | nullable | |
| softDeletes | | | |

**Index:** `(conversation_id, created_at)`.

### `blocks`

| id | blocker_user_id FK cascade | blocked_user_id FK cascade | created_at | **Unique:** `(blocker_user_id, blocked_user_id)`.

---

## 10. Scouting **[CHANGED]**

### `scout_shortlists` **[CHANGED]**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| scout_user_id | FK → users | cascade | |
| athlete_id | FK → athlete_profiles | cascade | |
| status | enum('under_review','good','high','final') | default 'under_review', index | **[NEW] pipeline tabs** |
| tags | json | nullable | **[NEW]** |
| notes | text | nullable | private |

**Unique:** `(scout_user_id, athlete_id)`.

### `observations` **[NEW]**

| id | scout_user_id FK cascade | athlete_id FK cascade | rating unsignedTinyInteger nullable | note text | media json nullable | created_at |

**Index:** `(scout_user_id, athlete_id)`.

### `scout_reports` **[NEW — P1]**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| scout_user_id | FK → users | cascade | |
| athlete_id | FK → athlete_profiles | cascade | |
| scores | json | nullable | 5-dimension scores (SC.8) |
| conclusion | enum('recommend','watch','pass') | nullable | |
| notes | text | nullable | |
| status | enum('draft','final') | default 'draft' | |
| softDeletes | | | |

**Index:** `(scout_user_id, athlete_id)`.

---

## 11. Enquiries **[CHANGED]**

### `enquiries`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| athlete_id | FK → athlete_profiles | cascade — initiator |
| subject_type | string | morphs: `coach_profile`,`academy`,`organisation`,`program`,`opportunity`,`facility` **[CHANGED]** |
| subject_id | bigint | |
| preferred_datetime | timestamp | nullable |
| conversation_id | FK → conversations | nullable, nullOnDelete **[NEW]** — thread link |

**Indexes:** morphs `(subject_type, subject_id, updated_at)`; `(athlete_id, updated_at)`.

### `enquiry_messages`

| id | enquiry_id FK cascade | sender_user_id FK cascade | body text | read_at timestamp nullable | media json nullable |

**Index:** `(enquiry_id, created_at)`.

---

## 12. Saves, Reports, Notifications, Broadcasts

### `saved_items` **[CHANGED]**

| id | user_id FK cascade | item_type string — morphs (academy/coach_profile/trial/tournament/opportunity/program/facility/post/event/generalized_profile) | item_id bigint |

**Unique:** `(user_id, item_type, item_id)`.

### `listing_reports` **[CHANGED]**

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| reporter_user_id | FK → users | cascade |
| reportable_type | string | morphs: user, post, academy, coach_profile, organizer_profile, trial, tournament, opportunity, program, facility, generalized_profile |
| reportable_id | bigint | |
| reason | enum('fake','outdated','inappropriate','misleading','spam','other') | **[CHANGED]** |
| comment | text | nullable |
| status | enum('pending','approved','edited','removed','warned','suspended') | default 'pending' |
| resolved_by | FK → users (admin) | nullable, nullOnDelete |
| resolved_at | timestamp | nullable |

**Indexes:** `(reportable_type, reportable_id, status)`, `(status, created_at)`.

### `notifications` **[CHANGED]**

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| user_id | FK → users | cascade |
| type | enum('reminder','enquiry_reply','status_update','follow','connection_request','connection_accepted','message','enquiry','registration_decision','verification_result','mention','broadcast','opportunity_deadline') | index **[CHANGED]** |
| title | string(190) | |
| body | string(255) | |
| notifiable_type | string | nullable |
| notifiable_id | bigint | nullable |
| action_url | string(255) | nullable |
| read_at | timestamp | nullable, index |

**Index:** `(user_id, read_at, created_at)`.

### `broadcasts` **[NEW — P1]**

| id | sender_admin_id FK→users cascade | audience json (role/status/city filters) | title string(190) | body text | scheduled_at timestamp nullable index | sent_at timestamp nullable | status enum('draft','scheduled','sent','cancelled') default 'draft' |

---

## 13. Leaderboard **[NEW — P0 points engine]**

### `leaderboard_seasons`

| id | name string(80) | starts_at date | ends_at date | is_active boolean default true | **Index:** `is_active`.

### `leaderboard_scores`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| season_id | FK → leaderboard_seasons | cascade | |
| athlete_id | FK → athlete_profiles | cascade | |
| sport_id | FK → sports | nullable, nullOnDelete | |
| points | unsignedInteger | default 0, index | |
| breakdown | json | nullable | source of points |

**Unique:** `(season_id, athlete_id, sport_id)`. **Index:** `(season_id, points)`.

### `leaderboard_config` **[NEW — P1, admin AD.11]**

| id | key string(60) unique | value json | updated_by FK→users nullable | — weights + season length |

---

## 14. Reviews **[NEW — P1]**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | bigint PK | | |
| rater_user_id | FK → users | cascade | |
| rateable_type | string | morphs: coach_profile / academy / organizer_profile / program / facility | |
| rateable_id | bigint | | |
| rating | unsignedTinyInteger | | 1–5 |
| body | text | nullable | |
| interaction_verified | boolean | default false | gating (verified interaction only) |
| status | enum('published','hidden') | default 'published' | |
| softDeletes | | | |

**Unique:** `(rater_user_id, rateable_type, rateable_id)`. **Index:** `(rateable_type, rateable_id, status)`.

---

## 15. Expiry, Reminders, Analytics, Academy Invites

### `expiry_rules` **[CHANGED]**

| id | content_type enum('trial','tournament','opportunity','program','facility') | trigger_field enum('event_date','final_date','listed_deadline') | days_after smallint default 0 | is_active boolean default true |

**Unique:** `content_type`.

### `expiry_events`

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| content_type | enum(...) | same set as rules |
| content_id | bigint | |
| scheduled_at | timestamp | |
| executed_at | timestamp | nullable |
| status | enum('pending','expired','overridden','restored') | default 'pending' |
| overridden_by | FK → users (admin) | nullable |

**Indexes:** `(status, scheduled_at)`, `(content_type, content_id)`.

### `reminder_subscriptions`

| id | user_id FK cascade | reminderable_type string — morphs (trial/tournament/opportunity/program) | reminderable_id bigint | remind_at timestamp index | sent_at timestamp nullable |

**Unique:** `(user_id, reminderable_type, reminderable_id)` (AS-10).

### `analytics_events` **[NEW]**

| id | user_id FK nullable | event string(80) index | context json nullable | created_at |

**Index:** `(event, created_at)`.

### `academy_athlete_invites` **[NEW — P1]**

| Column | Type | Constraints |
|---|---|---|
| id | bigint PK | |
| academy_id | FK → academies | cascade |
| invited_user_id | FK → users | nullable, nullOnDelete |
| invited_name | string(120) | nullable |
| invited_phone | string(20) | nullable |
| status | enum('pending','accepted','declined') | default 'pending', index |
| responded_at | timestamp | nullable |

---

## 16. Removed / Deprecated Tables **[REMOVED]**

| Table / item | Superseded by | Migration action |
|---|---|---|
| `sponsor_profiles` (role) | `opportunities` (provider types) | drop after migrating rows; remove `sponsor` from `users.role` |
| `sponsorships` | `opportunities` (type='sponsorship') | copy rows + `legacy_type`, then drop |
| `scholarships` | `opportunities` (type='scholarship') | copy rows + `posted_by_admin`, then drop |
| `sponsorship_applications` | `opportunity_applications` | migrate rows, then drop |
| `shortlist_entries` (sponsor) | `scout_shortlists` / `saved_items` | migrate or drop if unused |
| `academies.facilities` JSON column | `facilities` table | back-fill rows then drop column |

---

## 17. Migration Order (build sequence)

1. `users`, `otp_codes`, `guardian_consents`, `admin_profiles`
2. `sports`, `cities`, `age_groups`, `positions`
3. `media_items` (no FKs to profiles)
4. `athlete_profiles`, `athlete_sports`, `achievements`
5. `coach_profiles`, `coach_sports`, `academies`, `academy_sports`, `academy_coaches`, `facilities`, `organizer_profiles`, `organizer_sports`, `talent_scout_profiles`, `talent_scout_sports`, `generalized_profiles`
6. `programs` (owner morph — after providers)
7. `sports_venues` (owner_user_id added)
8. `trials`, `trial_registrations`, `trial_registration_documents`, `event_schedules`
9. `tournaments`, `tournament_categories`, `tournament_registrations`, `tournament_results`
10. `opportunities`, `opportunity_applications`
11. `enquiries`, `enquiry_messages` (after conversations)
12. `posts`, `post_likes`, `post_comments`
13. `follows`, `connection_requests`, `conversations`, `conversation_participants`, `messages`, `blocks`
14. `scout_shortlists`, `observations`, `scout_reports`
15. `saved_items`, `listing_reports`, `notifications`, `broadcasts`, `verification_requests`
16. `leaderboard_seasons`, `leaderboard_scores`, `leaderboard_config`, `reviews`
17. `expiry_rules`, `expiry_events`, `reminder_subscriptions`, `analytics_events`, `academy_athlete_invites`

> FK note: `media_items` must precede all profile/event tables (step 3).

---

## 18. Query Hotspots (index rationale)

| Hotspot screen/query | Tables & indexes used |
|---|---|
| Directory with filters (S.2/S.3) | `academies/coach_profiles/trials/sports_venues (listing_status/status, city_id)` + `positions` |
| Feed (S.9) | `posts(status, created_at)` + `(author_user_id, created_at)` |
| Leaderboard (S.6) | `leaderboard_scores(season_id, points)` |
| Connections/chat (S.19/S.17) | `connection_requests(addressee_user_id, status)`, `conversation_participants(user_id)` |
| Scout shortlist (SC.5) | `scout_shortlists(scout_user_id, status)` |
| Opportunities (D.9/AT.8) | `opportunities(status, deadline)`, `opportunity_applications(athlete_id, status)` |
| Verification queue (AD.4) | `verification_requests(status, created_at)` |
| Moderation queue (AD.6) | `listing_reports(status, created_at)` |
| Expiry sweep | `*(status, expires_at)` + `expiry_events(status, scheduled_at)` |
| Universal search (S.5) | Per-type queries incl. athletes; merged at service layer (AS-11) |

---

## 19. Seed Data Scope

- `sports`: Cricket, Football, Badminton, Athletics, Swimming (+ admin-extensible).
- `cities`: launch city set (AS-14).
- `age_groups`: Under-10, Under-12, Under-14, Under-16, Under-18, Open.
- `positions`: sport-scoped (e.g. Cricket → Batsman, Bowler, All-rounder, Wicketkeeper).
- `expiry_rules`: trial = 1 day after event; tournament = 3 days after final; opportunity = on listed deadline.
- `leaderboard_seasons` + `leaderboard_config`: default weights.
- **No** `sponsor` seeding (role removed).
