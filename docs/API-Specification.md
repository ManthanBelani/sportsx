> **Synced with new design (v3):** reflects `Backend-Feature-Delta.md` and `SportX_Mandatory_Fields.md`. See `Database-Design.md` for the canonical schema.

# API Specification — SportX India

Full endpoint listing for the Laravel REST API. Every endpoint maps to a feature in `Functional-Requirements.md` and a use case in `Use-Cases.md`.

> **v3 additions:** the endpoint catalog now follows `Backend-Feature-Delta.md` §11. Each row carries a **Status** tag: `EXISTS` (old backend, keep) · `NEW` (build) · `CHANGED` (modify) · `VERIFY` (partially built — check `sportx-api` first) · `P1` (MVP+ wave) · `REMOVED`. **Role model:** `athlete, coach, academy, organizer, scout, admin` — the old `sponsor` role is **REMOVED** (sponsorship is now an `opportunity` type).

> **Platform-integration docs (added 2026-10):** three subsystems are now fully specified in dedicated documents and are referenced from the sections below rather than duplicated here —
> - `Email-Provider-Architecture.md` — dual transactional email over **SMTP or Gmail API**, switchable at runtime. Covers `POST /auth/send-otp` (`channel=email`), email verification, password reset, account approval/rejection, and the notification **email fallback**.
> - `Google-Authentication.md` — **"Continue with Google"** sign-in and account linking via verified ID tokens (§1, `POST /auth/google`).
> - `FCM-Notification-System.md` — the full notification system: in-app + FCM push + email fallback, device-token lifecycle, per-user preferences (§14).
>
> **Admin:** `GET/POST /admin/email-settings/*` exposes provider status and a runtime SMTP ⇄ Gmail switch (§20).

> **Conventions & assumptions**
> - **Base URL:** `/api/v1` — AS-15.
> - **Auth:** Laravel Sanctum bearer tokens (header: `Authorization: Bearer <token>`). Issue at login/verify-OTP; invalidate at logout — AS-16.
> - **Response envelope:** Lists return `{ data: [], meta: { current_page, per_page, total, last_page } }`. Singles return `{ data: { ... } }`. Actions return `{ data: { id, ... } }` or `{ message: "..." }`.
> - **Error envelope:** `{ error: { code: string, message: string, fields?: { [field]: string[] } } }`.
> - **Pagination:** `?page=1&per_page=20` (default 20, max 50). Directory/search results use cursor or offset — AS-17.
> - **Filtering:** Query parameters per module (sport_id, city_id, age_group_id, status, q, etc.). Documented per endpoint.
> - **Sorting:** `?sort=created_at&direction=desc` (default varies per endpoint).
> - **Media upload:** `POST /media/upload` — `multipart/form-data` with `file` + `owner_type` + `owner_id` + `media_type`. Returns `{ data: { id, url } }`.
> - **Polymorphic IDs:** `item_type`/`item_id` or `reportable_type`/`reportable_id` strings are human-readable model class names (e.g. `Trial`, `Academy`).
> - **Admin routes:** prefixed `/api/v1/admin`, require `role=admin` + 2FA session.
> - **Status codes:** 200 OK, 201 Created, 204 No Content, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict (duplicate), 422 Unprocessable Entity (validation), 429 Too Many Requests.

---

## 1. Authentication & OTP

> **v3 (D1):** OTP signup/login is **P0 again** — phone **or** email + 6-digit OTP. The old "no OTP / email-only / token-link-only" decision is **[SUPERSEDED — see Backend-Feature-Delta.md]**. Password login is **kept alongside** OTP.

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| POST | `/auth/register` | — | CHANGED | Create account; `role` = `athlete/coach/academy/organizer/scout`; phone **or** email; triggers OTP (no instant token). | FR-AUTH-2,3; BE-M1.1 |
| POST | `/auth/send-otp` | — | NEW | Send 6-digit OTP via `channel=email\|phone`; 60s cooldown, max 5 attempts. | A.3/A.4; BE-M1.1 |
| POST | `/auth/verify-otp` | — | NEW | Verify OTP; issue token + `needs_onboarding`; sets `email_verified_at`/`phone_verified_at`. | A.4; BE-M1.1 |
| POST | `/auth/resend-otp` | — | NEW | Re-send OTP (rate-limited; Flutter already calls this — currently 404). | A.4; BE-M1.1 |
| POST | `/auth/login` | — | CHANGED | Keep email+password; **add** phone/email + OTP branch. | FR-AUTH-5 |
| POST | `/auth/logout` | Any | EXISTS | Revoke token. | — |
| GET | `/auth/me` | Any | EXISTS | Session check (already used by app). | — |
| POST | `/auth/forgot-password` | — | P1 | Token-link exists; add OTP variant. | A.6; BE-P1.12 |
| POST | `/auth/reset-password` | — | P1 | Same as above. | A.6; BE-P1.12 |
| POST | `/auth/google` | — | **BUILT (was P1)** | Google sign-in / account linking. Accepts an ID token, verifies against Google's JWKS, creates or links an account. See `Google-Authentication.md`. | A.3; D9 **CLOSED** |
| POST | `/auth/google/link` | Any | NEW | Link a Google identity to the current account (explicit linking, password re-confirmation). | AS-65 |
| POST | `/guardian/consent` | — | NEW | Guardian name/phone/relationship → OTP to guardian (minors). | A.9; BE-M1.4 |
| POST | `/guardian/verify-otp` | — | NEW | Verify guardian consent; unlocks minor's profile. | A.9; BE-M1.4 |
| GET/PUT | `/me/guardian-controls` | Athlete | NEW | Consent status, message/visibility prefs, leaderboard name mode. | AT.10; BE-M1.4 |
| GET | `/me/completion-checklist` | Any | NEW | Per-role completion % + missing items with deep-link keys. | AT.6; BE-M1.6 |
| POST | `/me/change-password` | Any | NEW | Logged-in password change. | S.22 |
| POST | `/me/delete-account` | Any | EXISTS | Soft-delete (keep 90-day purge). | S.22 |

> **Removed:** `POST /auth/verify-email` — the token-link verification endpoint is superseded by OTP; keep only as a **410 Gone** compatibility stub for one release (BE-M1.1). **Password auth stays** — do NOT drop email/password login (delta §3, Auth).

### POST `/auth/register`

**Request (email channel):**
```json
{ "role": "scout", "name": "Kiran Patel", "email": "kiran@example.com", "password": "secret" }
```
> `role` required (one of: `athlete, coach, academy, organizer, scout` — **no `sponsor`**). `phone` optional. Registering triggers an OTP; verify it via `POST /auth/verify-otp` to receive a token.

**Response 201:**
```json
{ "data": { "id": 1, "role": "scout", "name": "Kiran Patel", "otp_required": true, "needs_onboarding": true } }
```

### POST `/auth/send-otp`

**Request:** `{ "channel": "phone", "destination": "+9198XXXXXXXX", "purpose": "signup" }`
> `channel`: `email`|`phone`. `purpose`: `signup`|`login`|`reset_password`|`guardian_consent`|`verify_contact`. **429** if within 60s cooldown or attempts exhausted.
> **Delivery:** `channel=email` is delivered by the active provider in `Email-Provider-Architecture.md` (SMTP **or** Gmail API — switchable at runtime). `channel=phone` remains **blocked on AS-60** (SMS vendor unselected).

**Response 200:** `{ "data": { "sent": true, "expires_at": "...", "resend_available_at": "..." } }`

> Codes are bcrypt-hashed in `otp_codes.code_hash`; the plaintext exists only in the outbound message. Codes expire per `sportx.otp.expiry_minutes` (10) and are limited to `sportx.otp.max_attempts` (5).

### POST `/auth/verify-otp`

**Request:** `{ "channel": "phone", "destination": "+9198XXXXXXXX", "code": "482913" }`

**Response 200:**
```json
{ "data": { "token": "1|abc...", "user": { "id": 1, "role": "scout", "phone_verified_at": "..." }, "needs_onboarding": true } }
```

### POST `/auth/resend-otp`

**Request:** same as `/auth/send-otp`. **Response 200** or **429** (cooldown).

### POST `/auth/google`

> Full contract, verification rules and account-resolution logic: **`Google-Authentication.md`**.

**Request:** `{ "id_token": "eyJhbGciOiJSUzI1NiIs...", "role": "athlete" }`
> `id_token` — the `credential` from `GoogleSignIn.authentication.idToken`. `role` is optional, used only when creating a new account, and is **validated against `GOOGLE_ALLOWED_ROLES`**.

**Response 200:**
```json
{
  "token": "1|abc...",
  "user": { "id": 42, "role": "athlete", "name": "Kiran Patel", "email": "kiran@example.com", "email_verified_at": "...", "status": "active" },
  "needs_onboarding": true,
  "linked": false,
  "created": true
}
```

**Errors:** 401 `INVALID_ID_TOKEN` · 401 `EMAIL_NOT_VERIFIED` · 403 `ACCOUNT_DISABLED` · 403 `PENDING_APPROVAL` · 403 `SIGNUP_DISABLED` · 422 `INVALID_ROLE` · 429 throttle.

> **Account linking:** an identity with no `social_accounts` row but a **verified** matching SportX email is linked automatically. `pending` accounts are linked but refused login (403) so Google cannot bypass the approval gate. See `Google-Authentication.md` §6.

### POST `/auth/login`

**Request (password):** `{ "email": "aryan@example.com", "password": "secret" }`
**Request (OTP):** `{ "channel": "phone", "destination": "+9198XXXXXXXX" }` → sends OTP (then verify via `/auth/verify-otp`).

**Response 200:** Same shape as register response (`{ data: { token, user, needs_onboarding } }`).

### POST `/guardian/consent`

**Request:** `{ "athlete_user_id": 12, "guardian_name": "Suresh Mehta", "guardian_phone": "+9198XXXXXXXX", "relationship": "parent" }`
> Sends OTP to the guardian. Minor's profile stays `pending` until `POST /guardian/verify-otp` succeeds (BE-M1.4).

### GET `/me/completion-checklist`

**Response 200:**
```json
{ "data": { "role": "athlete", "completion": 62, "missing": [ { "field": "achievements", "label": "Achievements", "deep_link": "profile/achievements" }, { "field": "photo_media_id", "label": "Profile Photo", "deep_link": "profile/photo" } ] } }
```

---

## 2. Onboarding

> **v3:** `sponsor` onboarding is **REMOVED**; `scout` onboarding is **NEW**. All onboarding endpoints collect the role's 30 fields from `SportX_Mandatory_Fields.md` — mandatory fields (🔴) are required, optional fields (🟠/🟢) may be `null`.

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/onboarding/{role}` | Any, needs_onboarding | EXISTS | Get onboarding form schema/options. Add `scout`; drop `sponsor`. | A1,A2,C1,... |
| POST | `/onboarding/athlete` | Athlete | EXISTS | Athlete profile; **guardian gate if DOB < 18**. | FR-AUTH-6; AT.2 |
| POST | `/onboarding/coach` | Coach | EXISTS | Coach profile. | FR-AUTH-7 |
| POST | `/onboarding/academy` | Academy | EXISTS | Academy profile. | FR-AUTH-8 |
| POST | `/onboarding/organizer` | Organizer | EXISTS | Organizer profile. | FR-AUTH-9 |
| POST | `/onboarding/scout` | Scout | NEW | Scout org type, sports focus, experience, availability, languages, location. | SC.1; BE-M1.3 |
| ~~POST~~ | ~~`/onboarding/sponsor`~~ | — | REMOVED | Removed with the `sponsor` role (BE-M1.2). Keep 410/404, never 500. | delta §4 |

### POST `/onboarding/athlete`

**Request (mandatory fields marked 🔴, `SportX_Mandatory_Fields.md` §1):**
```json
{ "full_name": "Rohan Mehta", "date_of_birth": "2009-05-15", "gender": "male", "primary_sport_id": 1, "position": "Batsman (Right Hand)", "age_group_id": 3, "skill_level": "intermediate", "city_id": 5, "bio": "2–3 lines", "photo_media_id": 42, "sports": [1, 3] }
```
> 🔴 Mandatory: `full_name`, `date_of_birth`/`age_group_id`, `gender`, `primary_sport_id`, `position`, `skill_level`/`level`, `city_id`, `bio`, `photo_media_id`. 🟠/🟢 optional: `academy_id`, `team_name`, `coach_id`, `achievements`, `competition_history`, `performance_stats`, `personal_best`, `experience_years`, `training_centre`, `playing_hand`, `height_cm`, `weight_kg`, `goals`, `open_to`, `availability`, `relocation_preference`, `education`, `sponsorship_interest`, `social_links`. `sports` = array of sport IDs (primary flagged `is_primary`).

**Response 201:**
```json
{ "data": { "id": 1, "full_name": "Rohan Mehta", "age_group": { "id": 3, "name": "Under-16" }, "skill_level": "intermediate", "city": { "id": 5, "name": "Ahmedabad", "state": "Gujarat" }, "profile_completeness": 80, "guardian_consent_required": false } }
```
> If `date_of_birth` < 18 years ago, `guardian_consent_required` is `true` and the profile stays `pending` until guardian OTP verification (BE-M1.4).

### POST `/onboarding/scout`

**Request (per `SportX_Mandatory_Fields.md` §4):**
```json
{ "full_name": "Rohit Kumar", "photo_media_id": 51, "scout_type": "club", "primary_sport_ids": [1, 3], "specializations": ["Batting", "Bowling", "Wicketkeeping"], "city_id": 5, "bio": "2–3 lines", "experience_years": 5, "scouting_level": "state", "organization_name": "Gujarat Cricket Association", "availability": "available" }
```
> 🔴 Mandatory: `full_name`, `photo_media_id`, `scout_type`, `primary_sport_ids`, `specializations`, `city_id`, `bio`. 🟠/🟢 optional: `experience_years`, `scouting_level`, `age_groups_scouted`, `organization_name`, `previous_organizations`, `certifications`, `scouting_methods`, `evaluation_areas`, `athletes_scouted`, `discoveries`, `scouting_achievements`, `regions`, `events_covered`, `services`, `recruitment_focus`, `affiliations`, `availability`, `fee_structure`, `website`, `social_links`.

> The other onboarding endpoints (coach, academy, organizer) follow the same pattern with the role's 30 fields from `SportX_Mandatory_Fields.md` §2/§3/§5.

---

## 3. Master Data (Meta)

| Method | Path | Auth | Status | Purpose |
|---|---|---|---|---|
| GET | `/meta/sports` | Any | EXISTS | List sports (trending chips, filter options). |
| GET | `/meta/cities` | Any | EXISTS | List cities grouped by state. |
| GET | `/meta/age-groups` | Any | EXISTS | List age groups. |
| GET | `/meta/positions` | Any | NEW | Positions master (sport-scoped) for the athlete Position filter (S.4; BE-M11.6). |
| GET | `/meta/facilities` | Any | NEW | Facility-type filter metadata (AC.7). |
| GET | `/meta/trending-searches` | Any | EXISTS | Recent popular search terms. |
| GET | `/meta/faqs` | Any | NEW | FAQ list for the Help/Support screen (S.24 P0). |

**Response pattern (GET `/meta/sports`):**
```json
{ "data": [ { "id": 1, "name": "Cricket", "is_active": true }, ... ] }
```

---

## 4. Athlete Profile, Achievements & Media

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/profile` | Athlete | EXISTS | Own profile (view). | FR-ATH-1, A4 |
| PUT | `/me/profile` | Athlete | CHANGED | Update profile fields; add privacy fields, social links, cover. | FR-ATH-2, A5 |
| PUT | `/me/profile/sports` | Athlete | CHANGED | Per-sport `playing_role`, `level`, `experience_years`, `is_primary` (AT.4). | BE-M2.1 |
| GET/POST | `/me/achievements` | Athlete/Coach | NEW | Dedicated achievements CRUD: title, type, sport, level, year, certificate, description (S.11). | BE-M2.2 |
| PUT/DELETE | `/me/achievements/{id}` | Owner | NEW | Owner (athlete/coach) only. | BE-M2.2 |
| POST | `/media/upload` | Any logged-in | EXISTS | Upload photo/video/document (+ caption, sport tag). | A6, AC2 |
| PUT | `/media/reorder` | Any | EXISTS | Reorder media items (drag-to-reorder). | A6 |
| DELETE | `/media/{id}` | Owner | EXISTS | Delete a media item. | A6 |
| GET | `/me/media` | Any | NEW | Gallery grid feed for the profile Media tab + viewer (S.28). | BE-M2.2 |
| GET | `/athletes/{id}` | Any | CHANGED | Public athlete profile — open to all roles (was sponsor-scoped); minors restricted (AT.10 policy). | FR-SPON-4 → delta §3 |
| POST/GET | `/me/verification` | Any | NEW | ID + org proof upload, status (pending/verified/rejected + reason) (A.10). | BE-M1.5 |
| PUT | `/me/privacy` | Any | NEW | `profile_visibility`, `who_can_message`, `who_can_connect` (or fold into `/me/settings`). | S.22; BE-M7.5 |

### PUT `/me/profile` (Athlete)

**Request:**
```json
{ "full_name": "Rohan Mehta", "date_of_birth": "2009-05-15", "gender": "male", "skill_level": "advanced", "city_id": 5, "phone": "+91 98XXXXXXXX", "academy_id": 5, "coach_id": 3, "position": "Batsman (Right Hand)", "experience_years": 3, "cover_media_id": 60, "social_links": { "instagram": "...", "youtube": "..." }, "profile_visibility": "connections", "who_can_message": "connections" }
```
> 🔴 Mandatory fields cannot be nulled. Optional fields can be set to `null` to clear. Achievements now use dedicated `/me/achievements` CRUD (no longer diff-via-profile). Per-sport attributes (playing role, level, experience, primary) are updated via `PUT /me/profile/sports`.

### GET `/me/achievements` / POST `/me/achievements`

**Request:**
```json
{ "title": "State Level Winner", "achievement_type": "selection", "sport_id": 1, "level": "State", "year": 2025, "description": "Gujarat U-16", "certificate_media_id": 77 }
```

### POST `/media/upload`

**Request:** `multipart/form-data` — `file` (image/video), `owner_type` (e.g. `athlete_profile`), `owner_id`, `media_type` (`photo`/`video`/`document`), `caption` (optional), `sport_id` (optional).

**Response 201:**
```json
{ "data": { "id": 42, "url": "https://cdn.../path.jpg", "media_type": "photo" } }
```

### POST `/me/verification`

**Request:** `multipart/form-data` — `id_proof_media_id`, `org_proof_media_id` (optional), `note`.

**Response 201:** `{ "data": { "id": 7, "status": "pending", "created_at": "..." } }`  → reviewed by admin (AD.4); result notification on decision.

---

## 5. Directory / Listing Endpoints

All listing types share the same pattern: paginated card-list with consistent filters. **v3:** `scholarships` and `sponsorships` are replaced by the unified `/opportunities` endpoint (see §12); `/programs` and `/facilities` are new listing types; `/athletes` joins the directory set.

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/academies` · `/academies/{id}` | Any | EXISTS | Academy directory + detail. | FR-ATH-4, T1/T2 |
| GET | `/coaches` · `/coaches/{id}` | Any | EXISTS | Coach directory + detail (+ rating, distance, counts). | FR-ATH-5, T1/T2 |
| GET | `/athletes` · `/athletes/{id}` | Any | CHANGED | Athlete directory + public profile (was sponsor-only; add `position`, `level`, `achievements` filters). | BE-M3.1, SC.4 |
| GET | `/scouts/{id}` | Any | NEW | Public scout view: About + Activity only (shortlist/reports owner-only) (D.5). | BE-M1.3 |
| GET | `/organizers/{id}` | Any | NEW | Public organizer profile (D.4). | delta §11.3 |
| GET | `/trials` · `/trials/{id}` | Any | EXISTS | Browse trials + detail. | FR-ATH-7, T1/T2 |
| GET | `/tournaments` · `/tournaments/{id}` | Any | EXISTS | Browse tournaments (list/calendar) + detail. | FR-ATH-9, A16/A17 |
| GET | `/opportunities` · `/opportunities/{id}` | Any | NEW | Browse unified opportunities (scholarship/sponsorship/tryout/camp) + detail (D.9). | BE-M5.1 |
| GET | `/programs` · `/programs/{id}` | Any | NEW | Browse training programs + public detail (D.11). | BE-M6.1 |
| GET | `/facilities` · `/facilities/{id}` | Any | NEW | Browse facilities + public detail (D.13). | BE-M6.3 |
| GET | `/sports-venues` · `/sports-venues/{id}` | Any | EXISTS | Browse sports venues directory + detail. | AS-47, T1/T2 |
| ~~GET~~ | ~~`/scholarships`, `/sponsorships`~~ | — | REMOVED | Merged into `/opportunities`; keep 410 for one release (delta §4). | — |

### Shared query parameters (all GET directory endpoints)

| Param | Type | Description |
|---|---|---|
| sport_id | int[] | Filter by sport(s). |
| city_id | int | Filter by city. |
| age_group_id | int | Filter by age group. |
| position_id | int | Filter by position (S.4; BE-M11.6). |
| level | string | Filter by skill/playing level. |
| facilities | string[] | Filter by facility type (academies). |
| price_min`, `price_max | int | Fee range (academies/coaches/programs). |
| rating_min | number | Minimum rating (P1, reviews). |
| distance`, `lat`, `lng | — | "Near me" distance sort (city-centroid for MVP — §8 D5). |
| registration_status | string | Event card registration state (open/closing/closed). |
| status | string | Filter by listing status. |
| page | int | Page number. |
| per_page | int | Items per page (default 20, max 50). |
| sort | string | Sort field (e.g. `event_datetime`, `created_at`). |
| direction | string | `asc` or `desc`. |

### Directory-specific extra filters

| Endpoint | Extra params |
|---|---|
| `/academies` | `fee_min`, `fee_max`, `facility_type`, `rating_min` |
| `/coaches` | `fee_min`, `fee_max`, `rating_min` |
| `/athletes` | `position_id`, `level`, `skill_level`, `has_achievements` |
| `/trials` | `date_from`, `date_to` |
| `/tournaments` | `date_from`, `date_to`, `month` |
| `/opportunities` | `type` (scholarship/sponsorship/tryout/camp), `deadline_from`, `deadline_to` |
| `/programs` | `mode`, `age_group_id` |
| `/facilities` | `facility_type` |
| `/sports-venues` | `booking_available` (boolean) |

### GET `/trials` Response (card list)

```json
{ "data": [ { "id": 1, "name": "U-14 Cricket Trials", "sport": { "id": 1, "name": "Cricket" }, "venue": "Sardar Patel Stadium", "city": { "name": "Ahmedabad", "state": "Gujarat" }, "event_datetime": "2026-08-15T07:00:00+05:30", "registration_deadline": "2026-08-14T23:59:59+05:30", "entry_fee": "₹200", "registration_status": "open", "organization_name": "Elite Cricket Academy", "contact_number": "+91 98XXXXXXXX", "status": "published" } ], "meta": { "current_page": 1, "per_page": 20, "total": 89 } }
```

### GET `/trials/{id}` Response (detail)

```json
{ "data": { "id": 1, "name": "U-14 Cricket Trials", "sport": { ... }, "organization_name": "Elite Cricket Academy", "event_datetime": "...", "venue": "...", "google_maps_url": "https://maps.google.com/...", "city": { ... }, "eligibility": "Boys, U-14, Ahmedabad residents", "entry_fee": "₹200", "registration_deadline": "...", "required_documents": ["Aadhaar Card", "Passport Photo"], "contact_number": "+91 98XXXXXXXX", "vacancies": 30, "benefits": "Selected athletes get free academy kit", "status": "published", "is_saved_by_me": true, "organizer": { "type": "academy", "name": "Elite Cricket Academy", "id": 5 } } }
```

> All other detail endpoints follow this shape with fields from the T2 field-substitution table in wireframes. Verification badges are surfaced on profile/card/search resources where `verification_status=verified` (BE-M1.5).

---

## 6. Universal Search

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/search` | Any | CHANGED | Unified search; **add `athletes` group** (+ coaches). | FR-DISC-1,2; BE-M3.1 |
| GET | `/me/recent-searches` | Any | EXISTS | Saved recent searches. | S6 |
| POST | `/me/recent-searches` | Any | NEW | Persist a recent search (old spec had GET only). | delta §11.5 |

### GET `/search`

**Params:** `q` (required), `page`, `per_page`.

**Response 200:**
```json
{ "data": { "athletes": { "data": [...], "total": 6 }, "academies": { "data": [...], "total": 3 }, "coaches": { "data": [...], "total": 2 }, "trials": { "data": [...], "total": 5 }, "tournaments": { "data": [...], "total": 1 }, "opportunities": { "data": [...], "total": 2 }, "programs": { "data": [...], "total": 1 }, "facilities": { "data": [...], "total": 0 }, "sports_venues": { "data": [...], "total": 4 } }, "meta": { "query": "cricket ahmedabad", "page": 1 } }
```
> `scholarships`/`sponsorships` groups are **REMOVED** (merged into `opportunities`).

---

## 7. Enquiries

> **v3:** enquiry `subject_type` morphology is extended (+ `program`, `opportunity`); enquiries open a linked chat thread (`conversation_id`). The old assumptions "sponsorship_application subject" and "enquiries are the only messaging" are **[SUPERSEDED — see Backend-Feature-Delta.md]**.

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| POST | `/enquiries` | Any (athlete-primary) | CHANGED | Send enquiry; `subject_type` adds `program`, `opportunity`; creates/opens a chat thread. | FR-ENQ-1; BE-M6.2 |
| GET | `/me/enquiries` | Coach/Academy/Organizer/Scout | CHANGED | Enquiry inbox (T4); widen role scope + tabs Chats/Requests. | FR-COACH-3, FR-ACAD-7 |
| GET | `/enquiries/{id}` | Owner | EXISTS | Enquiry thread (T4b). | FR-COACH-4, FR-ACAD-9 |
| POST | `/enquiries/{id}/messages` | Owner | EXISTS | Reply to enquiry. | FR-COACH-4 |
| PUT | `/enquiries/{id}/read` | Owner | EXISTS | Mark messages as read. | — |

### POST `/enquiries`

**Request:**
```json
{ "subject_type": "program", "subject_id": 3, "message": "Is there a slot this weekend?", "preferred_datetime": "2026-08-09T06:00:00+05:30" }
```
> `subject_type`: `coach_profile`, `academy`, `organisation`, `program`, `opportunity`, `facility`. `sponsorship_application` is **REMOVED**. Response includes `conversation_id` for the linked thread (S.18).

**Response 201:** `{ data: { id, subject_type, subject_id, created_at, ... } }`

### GET `/me/enquiries`

**Params:** `filter` (`all`, `new`, `replied` — T4 tabs), `page`, `per_page`.

**Response:**
```json
{ "data": [ { "id": 1, "athlete": { "name": "Aryan Patel", "sport": "Cricket" }, "last_message_preview": "Is there a slot...", "status": "new", "updated_at": "..." } ] }
```

### POST `/enquiries/{id}/messages`

**Request:** `{ "body": "Yes, Saturday 6 AM is open." }`

**Response 201:** Message row + triggers `EnquiryReplied` event → athlete notification.

---

## 8. Trial Registrations

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/trials/{trial}/register` | Athlete | Register for a trial. | FR-ATH-8 |
| GET | `/trials/{trial}/registrations` | Academy/Organizer owner | Registrant list (AC6). | FR-ACAD-5 |
| GET | `/registrations/trials/{registration}` | Academy/Organizer | Registrant detail + documents (AC7). | FR-ACAD-6 |
| POST | `/registrations/trials/{registration}/verify` | Academy/Organizer | Mark as verified. | FR-ACAD-6 |
| POST | `/registrations/trials/{registration}/reject` | Academy/Organizer | Mark as rejected. | FR-ACAD-6 |
| POST | `/registrations/trials/{registration}/reminder` | Athlete | Toggle reminder on/off. | A15 |

### POST `/trials/{trial}/register`

**Request:**
```json
{ "document_media_ids": [42, 43], "reminder_enabled": true }
```
> Documents must match the trial's `required_documents` list. Profile fields auto-populated server-side.

**Response 201:**
```json
{ "data": { "registration_ref": "#TR20260815-0042", "trial": { "id": 1, "name": "...", "event_datetime": "...", "venue": "..." }, "status": "pending", "reminder_enabled": true } }
```
> 409 if already registered. 422 if trial closed/expired or documents missing.

---

## 9. Tournament Registrations

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/tournaments/{tournament}/register` | Athlete | Register for a tournament. | FR-ATH-10 |
| GET | `/tournaments/{tournament}/registrations` | Organizer | Registration management list (O7). | FR-ORG-5 |
| GET | `/tournaments/{tournament}/capacity` | Organizer | Category capacities (O8). | FR-ORG-6 |
| PUT | `/tournaments/{tournament}/capacity` | Organizer | Update capacities + waitlist toggle. | FR-ORG-6 |
| PATCH | `/registrations/tournaments/{registration}/payment` | Organizer | Flip manual payment flag. | FR-ORG-5 |

### POST `/tournaments/{tournament}/register`

**Request:**
```json
{ "category_id": 2, "participation_type": "team", "team_name": "Team Titans", "reminder_enabled": true }
```

**Response 201:**
```json
{ "data": { "registration_ref": "#TM20260820-0003", "category": { "name": "U-16", "capacity": 24 }, "status": "confirmed", "payment_status": "pending" } }
```
> `status` is `confirmed` if spots available, `waitlisted` if full + waitlist enabled, 422 if full + no waitlist.

### PUT `/tournaments/{id}/capacity`

**Request:**
```json
{ "categories": [ { "id": 2, "capacity": 30, "waitlist_enabled": true }, { "id": 3, "capacity": 24, "waitlist_enabled": false } ] }
```

---

## 10. Results

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/tournaments/{id}/results` | Any | Public results/brackets view. | FR-ORG-8, O10 |
| POST | `/tournaments/{id}/results` | Organizer | Publish results per category. | FR-ORG-7, O9 |

### POST `/tournaments/{id}/results`

**Request:**
```json
{ "category_id": 2, "bracket_media_id": 55, "places": [ { "place": 1, "winner_name": "Team Titans" }, { "place": 2, "winner_name": "Team Strikers" }, { "place": 3, "winner_name": "Team Falcons" } ] }
```

**Response 201:** Results set. Overwrites any unpublished results for the category (O9 re-publish allowed).

---

## 11. Scholarships — [SUPERSEDED — see Backend-Feature-Delta.md]

> Scholarship listings are **no longer admin-curated read-only**. They are one `type` of the unified `/opportunities` endpoint (see §12). `GET /scholarships` and `GET /scholarships/{id}` are **REMOVED** — keep 410 Gone for one release, or alias to `/opportunities?type=scholarship` (delta §4).

---

## 12. Opportunities & Applications [CHANGED — replaces Scholarships + Sponsorships]

> **v3 (D2/D3, BE-M5.1):** `scholarships` (admin-only) and `sponsorships` (sponsor-owned) collapse into one `opportunities` table with a `type` enum. Providers (**academy/organizer/coach/scout**) post them; athletes apply in-app with a pitch and track status (AT.8). The old sponsor-facing endpoints (`/me/sponsorships`, `/me/applications`, sponsor `/me/shortlist`) are **REMOVED** (delta §4).

### Browse & apply (public + athlete)

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/opportunities` | Any | NEW | Filters: `type` (scholarship/sponsorship/tryout/camp), sport, age, deadline; SC.11 hub tabs. | D.9, SC.11 |
| GET | `/opportunities/{id}` | Any | NEW | Provider, eligibility, benefits/amount, deadline. | D.9 |
| POST | `/opportunities/{id}/apply` | Athlete | NEW | Pitch + docs; profile snapshot auto-attached; **409** on duplicate. | AT.8 |
| GET | `/me/opportunities?type=applied\|saved\|created` | Any | NEW | My Opportunities (AT.8). | AT.8 |

### Provider posting (academy/organizer/coach/scout; athlete P1)

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| POST | `/me/opportunities` | Provider | NEW | Create (type-specific validation); athlete P1 via policy flag. | BE-M5.1 |
| PUT/PATCH | `/me/opportunities/{id}` (+publish/close) | Owner | NEW | Edit / status transitions (owner-only). | BE-M5.1 |
| GET | `/opportunities/{id}/applications` | Provider | P1 | Applicant review list. | BE-M5.2 |
| PATCH | `/opportunities/{id}/applications/{app}` | Provider | P1 | Shortlist / decline + note. | BE-M5.2 |

### POST `/opportunities/{id}/apply`

**Request:** `{ "pitch": "I've represented my state at the U-16 level...", "documents": [88, 89] }`

**Response 201:** `{ "data": { "id": 12, "opportunity_id": 3, "status": "submitted", "profile_snapshot": { ... } } }` — `409` if already applied.

### POST `/me/opportunities`

**Request:**
```json
{ "type": "scholarship", "title": "Merit Scholarship 2026", "sport_id": 1, "organization_name": "Khel Academy", "eligibility": "U-18, state-level players", "benefits": "Full fee waiver", "amount": 50000, "currency": "INR", "location": "Ahmedabad", "deadline": "2026-10-31", "documents_required": ["Aadhaar"], "description": "..." }
```
> `type`: `scholarship`|`sponsorship`|`tryout`|`camp`. `amount` numeric; all other fee columns are display-strings (no payments — `Database-Design.md` conventions).

---

## 13. Activity Hub & Saved Items

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/activity` | Any | CHANGED | Activity tabs: trials, tournaments, **opportunities**, registrations. | FR-ATH-14, A24 |
| GET | `/me/saved` | Any | CHANGED | Saved/bookmarked items grouped by type. **Morphs extend** to `post`, `opportunity`, `event`. | FR-ATH-15, A25; BE-M3.3 |
| POST | `/me/saved` | Any | CHANGED | Save an item (`item_type` now accepts `post`/`opportunity`/`event`). | — |
| DELETE | `/me/saved` | Any | EXISTS | Unsave. | — |

### POST `/me/saved`

**Request:** `{ "item_type": "opportunity", "item_id": 1 }`
> Extended `item_type` set: `academy`, `coach_profile`, `trial`, `tournament`, `opportunity`, `program`, `facility`, `post`, `event`, `generalized_profile`. 409 if already saved. 201 on success.

---

## 14. Notifications

> **Expanded by `FCM-Notification-System.md`** — the notification system now spans in-app + FCM push + email fallback, with device-token lifecycle management and per-user preference controls.

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/notifications?tab=` | Any | CHANGED | Tabs All/People/Opps/Events/Mentions; Today/Yesterday/Week grouping (S.16). Returns `meta.unread_count`. | FR-NOTIF-1 |
| PATCH | `/me/notifications/{id}/read` | Any | EXISTS | Mark single notification read. | — |
| POST | `/me/notifications/read-all` | Any | EXISTS | Mark all read. | — |
| DELETE | `/me/notifications/{id}` | Any | EXISTS | Delete single notification. | — |
| POST | `/me/device-tokens` | Any | CHANGED | Register FCM device token. Upsert on the now-**unique** `token`; a token re-registered by another user transfers to that user. Sets `last_seen_at`. | `FCM-Notification-System.md` §3 |
| DELETE | `/me/device-tokens` | Any | EXISTS | Unregister (called on logout). | — |
| POST | `/me/device-tokens/subscribe` | P1 | NEW | Subscribe the caller's tokens to an FCM topic (`sportx_broadcast`, `sportx_sport_{id}`). | §7 of the FCM doc |
| POST | `/me/device-tokens/test` | P1 | NEW | Send a test push to the caller's devices. | FCM doc §7 |
| GET | `/me/notification-preferences` | Any | NEW | Resolved preferences (hard overrides → type defaults → user overrides). | FCM doc §5 |
| PUT | `/me/notification-preferences` | Any | NEW | Update per-channel / per-category preferences. | FCM doc §5 |
| GET | `/admin/notifications/stats` | Admin | NEW | Delivery counts by type / `push_status` / provider. | FCM doc §10 |
| POST | `/admin/notifications/broadcast` | Admin | CHANGED | Broadcast. `channels: ["in_app","push"]`; email fallback enabled only when push is impossible. | delta §11.14 |

> **Notification `type` extends** to: `reminder`, `enquiry_reply`, `status_update`, `registration_approved`, `registration_rejected`, `trial_approved`, `trial_rejected`, `tournament_approved`, `tournament_rejected`, `account_action`, `follow`, `connection_request`, `connection_accepted`, `message`, `mention`, `broadcast`, `opportunity_deadline` (`Database-Design.md` §12). The column is **`VARCHAR(40)`**, not a MySQL enum — the original three-value enum could not represent this vocabulary. Each row also carries `channel`, `category`, `image_url`, `priority`, `metadata`, `pushed_at` and `push_status`.
>
> **Notification delivery is preference-aware:** `users.notification_prefs` is read before any push is dispatched. `account_action`, `registration_approved` and `registration_rejected` are hard overrides and always deliver in-app. See `FCM-Notification-System.md` §5.

---

## 15. Trust & Safety — Reports, Blocks

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| POST | `/reports` | Any | CHANGED | Report content (S.10/S.26). **Morphs extend** to `user`, `post`, `opportunity`, `program`, `facility`. | FR-TRUST-1; BE-M11.1 |
| GET | `/me/reports` | Any | NEW | My report statuses (S.23 safety centre). | delta §11.15 |
| POST | `/blocks` | Any | NEW | Block a user (S.23). | BE-M11.2 |
| GET | `/blocks` | Any | NEW | Blocked-users list. | BE-M11.2 |
| DELETE | `/blocks/{id}` | Any | NEW | Unblock. | BE-M11.2 |
| GET | `/admin/moderation/queue` | Admin | EXISTS | Reported listings queue (AD6). | FR-ADMIN-6 |
| GET | `/admin/moderation/reports/{id}` | Admin | EXISTS | Report detail + listing (AD7). | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/approve` | Admin | EXISTS | Approve listing (no action). | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/remove` | Admin | EXISTS | Remove listing. | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/edit-then-resolve` | Admin | EXISTS | Edit listing content + resolve. | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/warn` | Admin | EXISTS | Warn owner. | FR-ADMIN-7 |
| POST | `/admin/moderation/reports/{id}/suspend` | Admin | NEW | Suspend owner (BE-M11.4). | BE-M11.4 |

### POST `/reports`

**Request:**
```json
{ "reportable_type": "post", "reportable_id": 5, "reason": "inappropriate", "comment": "Abusive content" }
```
> `reportable_type` accepts: `user`, `post`, `academy`, `coach_profile`, `organizer_profile`, `generalized_profile`, `trial`, `tournament`, `opportunity`, `program`, `facility`. `reason`: `fake`, `outdated`, `inappropriate`, `misleading`, `spam`, `other`.

---

## 16. Settings

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/settings` | Any | CHANGED | Get user settings (+ visibility/messaging prefs, language, push toggles). | S11; BE-M7.5 |
| PUT | `/me/settings` | Any | CHANGED | Update prefs (incl. `profile_visibility`, `who_can_message`, `who_can_connect`). | FR-PLAT-1 |
| POST | `/me/delete-account` | Any | EXISTS | Request account deletion. | S11 |
| POST | `/support/contact` | Any | NEW | Report-a-problem + contact form (S.24 P0). | delta §11.16 |

## 16A. Discovery — Home, Explore, Leaderboard

> **v3:** role-aware dashboards replace the 5 separate home screens; leaderboard is a **new P0 points engine** (BE-M8.1).

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/home` | Any | NEW | One role-aware dashboard for all 5 homes: greeting, completion %, leaderboard strip/top-talents, shortcut counts (enquiries/registrations), feed preview. | AT.1, CO.2, AC.2, OR.2, SC.2 |
| GET | `/explore` | Any | NEW | Grouped sections (athletes/coaches/academies/events/opportunities) for S.2/Explore; cheaper than 5 calls. | S.2 |
| GET | `/leaderboard` | Any | NEW | Tabs (athletes/coaches/academies/teams/events), sport/location/age filters, podium + ranks 4–10; minors anonymized. | S.6; BE-M8.1 |
| GET | `/leaderboard/strip` | Any | NEW | Top-5 for home (AT.1/CO.2/AC.2). | BE-M8.1 |
| GET | `/me/leaderboard` | Any | BUILT | Personalised athlete board with `period` (weekly/monthly/season/allTime) and `category` (xp/matches/wins/achievements/connections) filters; includes the viewer's own rank. | AT.1; BE-M8.1 |

**GET `/leaderboard` params:** `sport_id`, `city_id`, `age_group_id`, `season_id`, `tab`.
**Response:** `{ "data": { "podium": [...], "ranks": [...], "season": { "id": 1, "name": "2026 Season" } }, "meta": { ... } }`

**GET `/me/leaderboard` params:** `period` (`weekly|monthly|season|allTime`), `category` (`xp|matches|wins|achievements|connections`), `sport_id`, `limit` (max 100).
**Response:** `{ "data": { "period": "weekly", "category": "xp", "season": {...}, "entries": [ { "rank": 1, "id": 12, "athlete_profile_id": 12, "user_id": 31, "name": "...", "avatar_url": "/storage/...", "score": 150, "sport": "Cricket", "level": "intermediate", "is_current_user": false, "city": "Pune" } ], "current_user": { ... } | null, "total_participants": 42 } }`

Scores are computed live from activity rows so weekly/monthly windows are possible: achievements (`achievements.created_at`), matches (approved trial/tournament registrations), wins (`tournament_results` place 1, matched on winner name), connections (accepted `connections`). XP = 50 per achievement + 10 per approved match (participation capped at 50). Minors are anonymized (first name + initial) unless the guardian opted into full names.

**Leaderboard points** recalc on: verified achievement, profile-completion milestones, post/event participation (BE-M8.1). Admin config endpoints (`/admin/leaderboard-config`, `/admin/leaderboard/reset-season`) are P1.

---

## 16B. Social Feed — Posts, Likes, Comments **[NEW — verify partial first]**

> Social feed/chat were **spec-excluded in the old design** — this is superseded (D7). Migrations/endpoints may be partially built; start each with a verify pass (delta §M7).

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/feed` | Any | VERIFY/NEW | Tabs For You/Following/Athletes/Coaches/Academies/Events; S.9. | BE-M7.1 |
| POST | `/posts` | Any | VERIFY/NEW | Text + media + hashtags + sport tag + audience (S.9). | BE-M7.1 |
| GET/PATCH/DELETE | `/posts/{id}` | Any/Owner | VERIFY/NEW | Detail (S.27); edit/delete own. | BE-M7.1 |
| POST/DELETE | `/posts/{id}/like` | Any | VERIFY/NEW | Toggle like + counts. | BE-M7.2 |
| GET/POST | `/posts/{id}/comments` | Any | VERIFY/NEW | Comment list + add (S.27). | BE-M7.2 |
| DELETE | `/comments/{id}` | Owner | NEW | Delete own comment. | BE-M7.2 |
| GET | `/hashtags/trending` | Any | P1 | Hashtag + mention notifications (BE-P1.8). | BE-P1.8 |

**POST `/posts` Request:** `{ "body": "...", "media": [101], "hashtags": ["cricket"], "sport_id": 1, "audience": "public" }`

---

## 16C. Network — Follow & Connect **[NEW]**

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| POST/DELETE | `/follow/{type}/{id}` | Any | NEW | One-way follow (athlete/coach/academy/event). | BE-M7.3 |
| GET | `/me/followers` · `/me/following` | Any | NEW | S.19 tabs. | BE-M7.3 |
| POST | `/connections` | Any | NEW | Connection request (athlete↔athlete; scout→athlete with purpose). | BE-M7.3, BE-M10.3 |
| GET | `/me/connections` | Any | NEW | Tabs Connections/Requests/Sent. | BE-M7.3 |
| PATCH | `/connections/{id}` | Any | NEW | Accept/decline → unlocks chat. | BE-M7.3 |
| DELETE | `/connections/{id}` | Any | NEW | Cancel sent / remove connection. | BE-M7.3 |
| GET | `/me/suggestions` | Any | P1 | Suggested-for-you (S.12). | BE-P1.8 |

> **Minors (BE-M10.3):** contact/connect to a U-18 athlete routes to the guardian — guardian consent required before chat unlock.

---

## 16D. Messaging — Conversations **[NEW — verify partial first]**

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/conversations` | Any | VERIFY/NEW | Tabs Chats/Requests, search, unread badges (S.17). | BE-M7.4 |
| POST | `/conversations` | Any | NEW | Start from an accepted connection (or auto-create on accept). | BE-M7.4 |
| GET | `/conversations/{id}` | Any | VERIFY/NEW | Thread (S.18); report/block entry. | BE-M7.4 |
| POST | `/conversations/{id}/messages` | Any | VERIFY/NEW | Text P0; attachments P1. | BE-M7.4 |
| PATCH | `/conversations/{id}/read` | Any | NEW | Read receipts. | BE-M7.4 |

> **Rules enforced (BE-M7.4):** no cold DMs; open only for an accepted connection OR an enquiry thread; minors = guardian-allowed connections only; blocks hide content both ways.

---

## 16E. Scouting — Shortlist, Observations, Contact

> The talent-scout role is **first-class** in v3 (`talent_scout_profiles`, 30 fields) — it is no longer only a side-guide. See `Talent-Scout-Implementation-Guide.md`.

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/scout-dashboard` | Scout | NEW | Dashboard aggregates; or fold into `/me/home` (recommended). | SC.2; BE-M10.4 |
| GET/POST/DELETE | `/me/shortlist` | Scout | CHANGED | Extend: `status` (under_review/good/high/final), `tags`, private `notes`, pipeline tabs. | SC.5/SC.6; BE-M10.1 |
| POST/GET | `/observations` | Scout | NEW | Quick note + rating + optional media (SC.10). | BE-M10.2 |
| POST | `/athletes/{id}/contact` | Scout | NEW | Purpose (trial invite/enquiry); U-18 routes to guardian (SC.13). | BE-M10.3 |
| POST/GET | `/scout-reports` | Scout | P1 | 5-dimension assessment + conclusion (SC.8/SC.9). | BE-P1.6 |
| GET | `/scout/compare?ids=` | Scout | P1 | Side-by-side scores (SC.7). | BE-P1.6 |

**GET/POST `/me/shortlist` Request:** `{ "athlete_id": 12, "status": "under_review", "tags": ["fast-bowler"], "notes": "private note" }` — `shortlist/notes/reports` are **owner-only** (scout-data privacy policy).

---

## 16F. Programs & Facilities **[NEW]**

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/programs` | Coach/Academy | NEW | Tabs Active/Drafts/Past (CO.4/AC.4). | BE-M6.1 |
| POST/PUT | `/me/programs`, `/me/programs/{id}` | Coach/Academy | NEW | Full program form (CO.5); publish/draft. | BE-M6.1 |
| GET | `/programs/{id}` | Any | NEW | Public program detail (D.11). | BE-M6.1 |
| POST | `/programs/{id}/enquire` | Any | NEW | Preferred batch + message → creates chat thread (D.12 → S.18). | BE-M6.2 |
| GET | `/me/facilities` | Academy | NEW | Tabs All/Grounds/Indoor/Gym/Other (AC.7). | BE-M6.3 |
| POST/PUT/DELETE | `/me/facilities`, `/me/facilities/{id}` | Academy | NEW | Facility form (AC.8). | BE-M6.3 |
| GET | `/facilities/{id}` | Any | NEW | Public facility detail (D.13). | BE-M6.3 |

---

## 16G. Events (unified create), Analytics & Share

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| POST | `/me/events?type=trial\|tournament\|camp` | Organizer/Academy (Coach/Athlete P1) | NEW/CHANGED | Unified create (OR.5); maps to `trials`/`tournaments` tables per §8 D2. | BE-M4.1 |
| GET | `/me/events` | Provider | NEW | My Events (OR.4/AC.6) with registered counts, Upcoming/Past. | §11.6 |
| GET | `/me/registrations` | Athlete | NEW | Unified My Registrations (upcoming/past) across trials+tournaments (AT.9). | §11.6 |
| DELETE | `/me/registrations/{id}` | Athlete | NEW | Cancel registration. | §11.6 |
| GET | `/events/{id}/registrations/export` | Provider | NEW | Registrant CSV/Excel export (OR.7). | BE-M4.3 |
| GET/POST | `/events/{id}/schedule` | Provider | P1 | Timetable slots (OR.9). | BE-P1.2 |
| GET | `/events/{id}/gallery` | Any | P1 | Gallery via media morph (OR.10). | BE-P1.2 |
| POST | `/events/{id}/results` | Provider | P1 | Results (OR.11). | BE-P1.3 |
| GET | `/events/{id}/analytics` | Provider | P1 | Views/regs/inquiries, timeline, sources (OR.12). | BE-P1.4 |
| POST | `/events/{id}/announce` | Provider | P1 | Announce to registrants/followers (OR.14). | BE-P1.5 |
| GET | `/share/{type}/{slug}` | Public | P1 | Deep-link resolver for profile/event/opportunity/post (S.30). | BE-M2.4 |
| POST | `/analytics/events` | Any | NEW | Batch funnel logging (signup, registration, enquiry, shortlist) → feeds OR.12. | BE-M12.1 |

---

## 17. Provider — Coach Listing

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/coach-profile` | Coach | EXISTS | Own listing (+ programs tab data, rating aggregate P1). | FR-COACH-1 |
| PUT | `/me/coach-profile` | Coach | EXISTS | Update listing (30 fields — `SportX_Mandatory_Fields.md` §2). | FR-COACH-1 |

---

## 18. Provider — Academy Listing & Trials

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/academy` | Academy | EXISTS | Own academy listing (+ programs/facilities/events/reviews tab data). | FR-ACAD-1 |
| PUT | `/me/academy` | Academy | EXISTS | Update listing (30 fields — `SportX_Mandatory_Fields.md` §3). | FR-ACAD-1 |
| GET | `/me/trials` | Academy/Organizer | EXISTS | My trials list (AC5/O4). | FR-ACAD-4, FR-ORG-2 |
| POST | `/me/trials` | Academy/Organizer | EXISTS | Create trial (AC4/O3). | FR-ACAD-3, FR-ORG-2 |
| PUT | `/me/trials/{id}` | Owner | EXISTS | Edit trial. | FR-ACAD-3, FR-ORG-2 |
| PATCH | `/me/trials/{id}/publish` | Owner | EXISTS | Publish draft. | — |
| PATCH | `/me/trials/{id}/close` | Owner | EXISTS | Close trial. | FR-ACAD-4 |
| GET/POST | `/me/facilities` | Academy | NEW | Facilities CRUD (see §16F; replaces `academies.facilities` JSON). | BE-M6.3 |

### POST `/me/trials`

**Request:**
```json
{ "name": "U-14 Cricket Trial", "organization_name": "Elite Cricket Academy", "sport_id": 1, "event_datetime": "2026-08-15T07:00:00+05:30", "venue": "Sardar Patel Stadium", "google_maps_url": "https://maps.google.com/...", "city_id": 5, "contact_number": "+91 98XXXXXXXX", "registration_deadline": "2026-08-14T23:59:59+05:30", "eligibility": "Boys, U-14, Ahmedabad", "entry_fee": "₹200", "required_documents": ["Aadhaar Card", "Passport Photo"], "vacancies": 30, "benefits": "Free academy kit for selected athletes", "publish": false }
```
> Mandatory fields per PDF: `name`, `organization_name`, `sport_id`, `event_datetime`, `venue`, `google_maps_url`, `contact_number`, `registration_deadline`. Optional: `eligibility`, `entry_fee`, `required_documents`, `vacancies`, `benefits`. `publish: false` → status=draft; `publish: true` → status=published (sets expires_at from expiry rule).

---

## 19. Provider — Organizer Tournaments

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/me/tournaments` | Organizer | EXISTS | My tournaments list (O6). | FR-ORG-4 |
| POST | `/me/tournaments` | Organizer | EXISTS | Create tournament (O5); `event_type` supports camp/championship/league/etc. | FR-ORG-3 |
| PUT | `/me/tournaments/{id}` | Organizer | EXISTS | Edit tournament. | FR-ORG-3 |
| PATCH | `/me/tournaments/{id}/publish` | Organizer | EXISTS | Publish. | — |
| PATCH | `/me/tournaments/{id}/close` | Organizer | EXISTS | Close. | — |
| GET/POST/PUT | `/me/venues` | Organizer | P1 | Organizer-owned venues (OR.13); public browse exists. | BE-M6.4 |

### POST `/me/tournaments`

**Request:**
```json
{ "name": "U-16 State Cup", "sport_id": 1, "format": "knockout", "start_date": "2026-08-20", "end_date": "2026-08-25", "registration_deadline": "2026-08-18", "venue": "GMDC Ground", "google_maps_url": "https://maps.google.com/...", "city_id": 5, "contact_number": "+91 98XXXXXXXX", "entry_fee": "₹500/team", "registration_link": "https://forms.example.com/u16-cup", "prize_pool": "₹50,000", "rules": "ICC standard rules apply", "gender": "male", "categories": [ { "age_group_id": 3, "capacity": 24 }, { "age_group_id": 4, "capacity": 24 } ], "publish": true }
```
> Mandatory fields per PDF: `name`, `sport_id`, `start_date`, `end_date`, `registration_deadline`, `venue`, `google_maps_url`, `entry_fee`, `contact_number`, `registration_link`. Optional: `format`, `city_id`, `prize_pool`, `rules`, `gender`, `banner_media_id`.

---

## 20. Admin Endpoints

All routes prefixed `/api/v1/admin`. Require `role=admin` + 2FA-verified session.

### Admin Auth

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| POST | `/admin/login` | — | Admin login (email + password). | FR-ADMIN-1 |
| POST | `/admin/verify-2fa` | — | Verify 2FA code. | FR-ADMIN-1 |
| GET | `/admin/dashboard` | Admin | Dashboard counters. | FR-ADMIN-2 |

### Content Management

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/admin/content` | Admin | Category picker with counts (AD3). | FR-ADMIN-3 |
| GET | `/admin/content/{type}` | Admin | Content list per category (AD4). | FR-ADMIN-4 |
| POST | `/admin/content/{type}` | Admin | Create record (AD5). | FR-ADMIN-5 |
| GET | `/admin/content/{type}/{id}` | Admin | Get record for editing. | FR-ADMIN-5 |
| PUT | `/admin/content/{type}/{id}` | Admin | Update record. | FR-ADMIN-5 |
| DELETE | `/admin/content/{type}/{id}` | Admin | Delete record. | FR-ADMIN-5 |

> `{type}` = `academies`, `coaches`, `trials`, `tournaments`, `opportunities`, `programs`, `facilities`, `posts`, `sports_venues`. **Changed:** `scholarships`/`sponsorships` are removed; the extended set adds opportunities/programs/facilities/posts (BE-M11.5). Each uses the same schema as the owner's own edit form.

### Admin — User Management & Verification (NEW P0)

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/admin/users` | Admin | NEW | Search + role/status filters (AD.3). | BE-M11.3 |
| GET | `/admin/users/{id}` | Admin | NEW | User detail. | BE-M11.3 |
| POST | `/admin/users/{id}/suspend` · `/ban` | Admin | NEW | Suspend/ban (uses `users.status`). | BE-M11.3 |
| GET | `/admin/verification` | Admin | NEW | Verification queue (AD.4). | BE-M1.5 |
| POST | `/admin/verification/{id}/approve` · `/reject` | Admin | NEW | Approve / reject + reason (queues result notification). | BE-M1.5 |

### Admin — Email Provider Settings **[NEW — `Email-Provider-Architecture.md`]**

> Credentials live in the environment and are never returned by any endpoint. These routes expose the **resolved status** so operators can see which provider is live and verify it end to end.

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET | `/admin/email-settings` | Admin | NEW | Active provider, failover chain, per-provider `configured` flags (host/port/client-id only — never secrets). | Email doc §6 |
| GET | `/admin/email-settings/diagnostics` | Admin | NEW | Gmail OAuth probe + SMTP socket reachability + resolved chain. | Email doc §10 |
| POST | `/admin/email-settings/provider` | Admin | NEW | Switch the active provider (`smtp` \| `gmail`) at runtime. Persists to `platform_settings.json`; no deploy. | Email doc §6.3 |
| POST | `/admin/email-settings/test` | Admin | NEW | Send a real test message through the chosen provider. | Email doc §13 |
| POST | `/admin/email-settings/clear-token-cache` | Admin | NEW | Drop the cached Gmail OAuth2 access token after a credential rotation. | Email doc §5.4 |

### Admin — Leaderboard Config (P1)

| Method | Path | Auth | Status | Purpose | Source |
|---|---|---|---|---|---|
| GET/PUT | `/admin/leaderboard-config` | Admin | P1 | Points weights + season length (AD.11). | BE-M8.2 |
| POST | `/admin/leaderboard/reset-season` | Admin | P1 | Reset active season. | BE-M8.2 |
| POST/GET | `/admin/broadcasts` | Admin | P1 | Audience filter + schedule + FCM fan-out (AD.12). | BE-P1.9 |

### Expiry Rules & Monitor

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/admin/expiry-rules` | Admin | Show rules (AD8). | FR-ADMIN-8 |
| PUT | `/admin/expiry-rules` | Admin | Update rules. | FR-ADMIN-8 |
| GET | `/admin/expiry/monitor` | Admin | Expiry monitor (AD9). | FR-ADMIN-9 |
| POST | `/admin/expiry/events/{id}/override` | Admin | Override pending expiry. | FR-ADMIN-9 |
| POST | `/admin/expiry/events/{id}/restore` | Admin | Restore expired listing. | FR-ADMIN-9 |

### Category Management

| Method | Path | Auth | Purpose | Source |
|---|---|---|---|---|
| GET | `/admin/categories/sports` | Admin | List sports. | FR-ADMIN-10 |
| POST | `/admin/categories/sports` | Admin | Add sport. | FR-ADMIN-10 |
| PUT | `/admin/categories/sports/{id}` | Admin | Edit sport. | FR-ADMIN-10 |
| DELETE | `/admin/categories/sports/{id}` | Admin | Remove sport (soft). | FR-ADMIN-10 |
| GET | `/admin/categories/cities` | Admin | List cities. | FR-ADMIN-11 |
| POST | `/admin/categories/cities` | Admin | Add city. | FR-ADMIN-11 |
| PUT | `/admin/categories/cities/{id}` | Admin | Edit city. | FR-ADMIN-11 |
| DELETE | `/admin/categories/cities/{id}` | Admin | Remove city (soft). | FR-ADMIN-11 |
| GET | `/admin/categories/age-groups` | Admin | List age groups. | FR-ADMIN-12 |
| POST | `/admin/categories/age-groups` | Admin | Add. | FR-ADMIN-12 |
| PUT | `/admin/categories/age-groups/{id}` | Admin | Edit. | FR-ADMIN-12 |
| DELETE | `/admin/categories/age-groups/{id}` | Admin | Remove (soft). | FR-ADMIN-12 |
| GET/POST/PUT/DELETE | `/admin/categories/positions` | Admin | Positions master CRUD (S.4 filter; BE-M11.6). | BE-M11.6 |

---

## 21. Error Catalog

| HTTP | Code | When | Example |
|---|---|---|---|
| 400 | `BAD_REQUEST` | Malformed request body. | — |
| 401 | `UNAUTHORIZED` | Missing/invalid token. | — |
| 403 | `FORBIDDEN` | Role lacks permission. | Athlete trying to access admin routes. |
| 404 | `NOT_FOUND` | Resource missing. | Trial ID doesn't exist. |
| 409 | `CONFLICT` | Duplicate state. | Already registered for trial. Already saved. |
| 422 | `VALIDATION_FAILED` | Field validation errors. | Missing required field, invalid enum. |
| 429 | `TOO_MANY_REQUESTS` | Rate limit exceeded. | OTP resend too frequently. |

### Domain Error Codes (`Google-Authentication.md`)

| HTTP | Code | When | Client behaviour |
|---|---|---|---|
| 401 | `INVALID_ID_TOKEN` | Google ID token malformed, bad signature, wrong `aud`, expired | Clear error; do not retry |
| 401 | `EMAIL_NOT_VERIFIED` | `email_verified` claim not true | Prompt to verify with Google |
| 403 | `ACCOUNT_DISABLED` | Identity matched a `suspended` / `deleted` account | Show support contact |
| 403 | `PENDING_APPROVAL` | Identity matched a `pending` account | Show pending-approval screen |
| 403 | `SIGNUP_DISABLED` | Unknown identity while `GOOGLE_ALLOW_SIGNUP=false` | Fall back to password registration |
| 422 | `INVALID_ROLE` | `role` outside `GOOGLE_ALLOWED_ROLES` | Field error on `role` |

### 422 Validation Error Shape

```json
{ "error": { "code": "VALIDATION_FAILED", "message": "The given data was invalid.", "fields": { "email": ["The email has already been taken."], "sports": ["At least one sport is required."] } } }
```

---

## 22. Endpoint Count Summary

> Counts updated for the v3 delta. See `Backend-Feature-Delta.md` §11 roll-up: **P0 ≈ 70 new, ≈ 25 changed, ≈ 10 verify-first; P1 ≈ 30 new.** `sponsor` role routes (~12) are removed.

| Module | Endpoints | Notes |
|---|---|---|
| Auth & OTP | 19 | + send/verify/resend OTP, Google sign-in + linking, guardian consent, completion checklist, change-password |
| Onboarding | 6 | scout added, sponsor removed |
| Meta/Master Data | 7 | + positions, facilities, faqs |
| Athlete Profile, Achievements & Media | 12 | + achievements CRUD, media gallery, verification, privacy |
| Directories (incl. athletes/opportunities/programs/facilities) | 20 | scholarships/sponsorships removed |
| Universal Search | 3 | + athletes group, POST recent-searches |
| Discovery (home/explore/leaderboard) | 4 | new |
| Enquiries | 5 | extended morphs |
| Events (unified) + Registrations | ~20 | + schedule/gallery/results/analytics/announce, export |
| Results | 2 | |
| Opportunities & Applications | 10 | replaces Scholarships + Sponsorships |
| Programs & Facilities | 8 | new |
| Social Feed | 7 | verify-first |
| Network (follow/connect) | 7 | new |
| Messaging | 5 | verify-first |
| Scouting | 8 | shortlist/observations/reports/contact |
| Activity & Saved | 4 | extended morphs |
| Notifications | 11 | extended types, device-token lifecycle, topic subscribe, preference read/update, test push |
| Trust & Safety (reports/blocks) | 9 | extended morphs + blocks |
| Settings/Support | 4 | + privacy, support contact |
| Provider (coach/academy/organizer) | 20 | + venues, facilities |
| Admin Auth & Dashboard | 3 | |
| Admin Users & Verification | 5 | new P0 |
| Admin Content CRUD | 6 | extended `{type}` |
| Admin Moderation | 8 | + suspend |
| Admin Expiry | 5 | + opportunity type |
| Admin Categories | 14 | + positions |
| Admin Email Provider Settings | 5 | new — SMTP/Gmail status, diagnostics, runtime switch, test |
| Admin Leaderboard/Broadcasts (P1) | 4 | |
| Analytics/Share | 2 | |
| Media Upload | 3 | |
| **Approx. total** | **~242** | Includes ~110 new/changed v3 endpoints, +12 for email/Google/FCM |

> Approximate: some endpoints share paths under the same method; exact count finalized during implementation. **REMOVED:** `sponsor` onboarding/routes, `/scholarships*`, `/sponsorships*`, `/auth/verify-email` (superseded by OTP).
