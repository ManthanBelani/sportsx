# Mandatory Fields — Spec vs Implementation Audit

Audited `sportsx-design-v3/new_design_docs/SportX_Mandatory_Fields.md` against the **live
MySQL schema** (`sportx-api`, database `sportx_db`) and the Flutter client.
**No.** The spec is substantially unimplemented.

---

## 1. Headline: actual field counts vs spec's 30

| Role | Spec target | Actual domain fields | Coverage |
|------|:-----------:|:--------------------:|:--------:|
| Athlete | 30 | ~20 (16 profile + 6 sports) | ~65% |
| Coach | 30 | 23 | ~77% |
| Academy | 30 | 20 | ~67% |
| Talent Scout | 30 | 8 | **~27%** |
| Organizer | 30 | 3 | **~10%** |
| Generalized (NGO, Doctor, Store, …) | 30 | **0 — no table exists** | **0%** |

Domain fields = excluding `id`, `user_id`, timestamps.

---

## 2. 🔴 Mandatory field coverage, role by role

### Athlete — 7 of 8 present (1 missing)

| # | Spec field | Status |
|---|-----------|--------|
| 1 | Full Name | ✅ `athlete_profiles.full_name` |
| 2 | Profile Photo | ✅ `photo_media_id` |
| 3 | Primary Sport | ✅ `athlete_sports` (has `is_primary`) |
| 4 | Position / Event | ✅ `position` |
| 5 | City / State | ✅ `city_id` |
| 6 | Age / Age Group | ✅ `age_group_id` |
| 7 | Skill / Playing Level | ✅ `skill_level` |
| 8 | **Short Bio** | ❌ **no `bio` column** on `athlete_profiles` |

`bio` exists on `coach_profiles` and `talent_scout_profiles` but **not** athletes. The Flutter
client has no bio field for athletes either.

### Coach — 6 of 8 present (1 missing, 1 thin)

| # | Spec field | Status |
|---|-----------|--------|
| 1 | Full Name | ✅ |
| 2 | Profile Photo | ✅ `photo_media_id` |
| 3 | Primary Sport | ✅ `sport_id` |
| 4 | Coaching Specialization | ⚠️ `qualification` only — `coach_profiles` has **no `specialization` column** |
| 5 | **Coaching Level** | ❌ **missing** (Grassroots/Youth/State/Professional) |
| 6 | City / State | ✅ `city_id` |
| 7 | Short Bio | ✅ `bio` |
| 8 | Years Coaching Exp | ✅ `experience` |

Also missing from spec's High list: coaching role, teams coached, age groups coached, athlete
levels coached, training programs, coaching services, training location, coaching philosophy,
opportunities, travel preference, education, social links.

### Academy — 6 of 9 present (3 missing)

| # | Spec field | Status |
|---|-----------|--------|
| 1 | Academy Name | ✅ `name` |
| 2 | Logo / Cover | ✅ both present |
| 3 | Primary Sport(s) | ✅ `academy_sports` |
| 4 | **Academy Type** | ❌ missing (Private/Club/School/College/Govt) |
| 5 | City / State | ✅ `city_id` |
| 6 | Short Description | ✅ `description` |
| 7 | **Sports / Training Offered** | ❌ missing |
| 8 | Age Groups | ✅ `age_groups` |
| 9 | **Training Programs** | ⚠️ no column; a generic `programs` table exists but is not linked |

### Talent Scout — 6 of 7 present (1 missing)

Table is `talent_scout_profiles` (**12 columns**, not 30).

| # | Spec field | Status |
|---|-----------|--------|
| 1 | Full Name | ✅ `users.name` |
| 2 | Profile Photo | ✅ `photo_media_id` |
| 3 | **Scout Type** | ❌ missing (Independent/Club/Academy/Federation) |
| 4 | Primary Sport(s) | ✅ `talent_scout_sports` |
| 5 | Scouting Specialization | ✅ `sports_specialization` |
| 6 | City / State | ✅ `city_id` |
| 7 | Short Bio | ✅ `bio` |

### Organizer — 2 of 7 present ⚠️ worst-covered role

`organizer_profiles` has only **3 domain columns**: `organization_name`, `org_type`,
`verification_status`.

| # | Spec field | Status |
|---|-----------|--------|
| 1 | Organization Name | ✅ |
| 2 | Logo / Cover Photo | ❌ missing |
| 3 | Organizer Type | ✅ `org_type` |
| 4 | **Primary Sport(s)** | ❌ missing |
| 5 | **Event Types** | ❌ missing |
| 6 | **City / State** | ❌ missing |
| 7 | **Short Description** | ❌ missing |

Everything else in the spec (upcoming events, registration fee, deadlines, venue, fixtures,
results, sponsors, partners) is absent.

### Generalized Profile — ❌ entirely missing

The spec's §6 covers **NGO, Doctor, Physiotherapist, Sports Store, Brand, Nutritionist,
Journalist, Agent, Federation, Facility, School/College, Photographer, Psychologist, Government
Body** — 9 mandatory fields each.

**No table exists for any of these.** The only profile tables are:
`admin_profiles`, `athlete_profiles`, `coach_profiles`, `organizer_profiles`,
`sponsor_profiles`, `talent_scout_profiles`.

`sponsor_profiles` (4 domain fields) is the nearest thing, but it covers only brand
sponsorships, not the generalized category. There is no `profile_type` / `category` concept
anywhere in the schema, which §6 makes mandatory field #1.

---

## 3. 🟠🟢 Optional fields — effectively not implemented

Neither priority tier is meaningfully present. Examples of what the schema has **no column for**:

- **Athlete (22 of 22 optional missing):** current team, competition history, performance
  statistics, personal best, certificates, training centre, playing hand/foot, height, weight,
  photos/videos, goals, open-to-opportunities, availability, travel preference, education,
  additional sports, verification status, sponsorship interest.
  - Partial relief: `achievements` and `media_items` tables exist generically
    (`owner_type`/`owner_id`), and `athlete_sports` carries `playing_role`, `level`,
    `experience_years`.
- **Coach:** coaching role, teams/age-groups/levels coached, areas of expertise, training
  programs, coaching services, training location, philosophy, travel preference, education,
  reviews, social links.
  - Partial relief: `coaching_enrollments`, `facilities`, `achievements` exist.
- **Scout:** scouting level, age groups scouted, previous orgs, certifications, scouting method,
  evaluation areas, athletes scouted, successful discoveries, regions, events covered,
  services, recruitment focus, reports/portfolio, availability.
  - Partial relief: `scout_connections`, `scout_shortlists`, `observations`.

**Notable systematic gaps:**
- **Verification Status** — spec lists it for 4 of 6 roles. Only `organizer_profiles` and
  `sponsor_profiles` have `verification_status`. Coach/Academy/Athlete/Scout have
  `listing_status` (publish state) which is a **different concept**.
- **Social / Professional Links** — not on any profile table. `users.social_links` exists
  globally but is not per-role-profile.
- **Travel / Relocation Preference** — absent for every role.
- **Education** — absent for every role.

---

## 4. Cross-cutting findings

1. **`users` is the only common table** (name, email, phone, role, social_links,
   privacy_settings, language, notification_prefs). So the "Common Mandatory Fields" matrix is
   only satisfied for Name + Contact. Photo, Sport, City, Bio are per-role and inconsistently
   present (see athlete `bio` above).

2. **Two different "status" columns** exist (`listing_status` vs `verification_status`) with
   different meanings across tables — a likely source of inconsistency in the client.

3. **Athlete onboarding validation** (`OnboardingController::athlete`) requires
   `full_name, date_of_birth, gender, sports, age_group_id, skill_level, city_id` —
   that matches the spec's athlete mandatory list **except `bio`**, which it cannot require
   because the column doesn't exist. So the spec is already unmeetable at the API layer.

4. **The Flutter client mirrors the gaps** — there is no athlete bio field, and no
   generalized-profile feature at all (searched for NGO/Physiotherapist/Nutritionist: no hits).

---

## 5. What this means

The spec describes a **30-field-per-role product**. The implementation is a **~10–25 field
MVP for the weaker roles**. Athlete and Coach are closest to the spec. Organizer and the entire
Generalized category are substantially unimplemented.

The two blockers to closing the gap are:

1. **No migration strategy agreed.** Adding ~15 columns × 6 roles is a schema change across the
   board.
2. **The Generalized Profile has no foundation at all** — it needs a new `profile_type` concept
   and likely a new table, not just columns.

---

## 6. Suggested order of work

1. **Athlete `bio`** — one column, closes a mandatory gap in an otherwise-complete role.
2. **Organizer** — 5 missing mandatory fields on a 3-column table; highest severity.
3. **Generalized Profile** — new `profile_category` + profile table; biggest single build.
4. **Coach `specialization` + `coaching_level`** — closes 2 mandatory coach gaps.
5. **Academy `academy_type` + `sports_offered`** — closes 2 mandatory gaps.
6. **Scout `scout_type`** — closes the last mandatory scout gap.
7. **Standardise `verification_status`** across all profile tables.
8. Optional tiers last, priority by role.

---

> Method: read `SHOW COLUMNS` from the live MySQL schema and
> `app/Http/Controllers/OnboardingController.php` validation rules. **No profile screen has been
> exercised in a running app**, so this reflects the database contract, not end-to-end UI
> behaviour. Field presence ≠ field being surfaced in the UI.